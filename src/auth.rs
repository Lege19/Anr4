//! Handles authentication
//!
//! Provides handler for responding to login requests,
//! and extractors for authenticated responses
use axum::{Form, body::Body, extract::State, http::StatusCode};
use axum_extra::extract::CookieJar;
use serde::Deserialize;
use sqlx::query;
use tracing::error;

use crate::{database::RowId, server_state::ServerState};
mod access_token;
use access_token::{AccountKind, JwtState, new_access_token};
pub use access_token::{StudentId, TeacherId};

/// Axum state used in the authentication system.
/// Currently only the access token side of things needs any state,
/// so for now this is a simple type alias
pub type AuthState = JwtState;

/// This is the format of the body for a login request
///
/// Even though this is only used locally,
/// it has to be public because it is used in a Json extractor in a public function.
#[derive(Deserialize)]
pub struct LoginForm {
    /// Email of account to login as
    email: Box<str>,
    /// Password provided in the login form
    password: Box<str>,
}

/// Checks that the provided password matches the provided password hash
fn check_password(password: impl AsRef<[u8]>, hash: &str) -> bool {
    match password_auth::verify_password(password, hash) {
        Ok(()) => true,
        Err(password_auth::VerifyError::PasswordInvalid) => false,
        Err(password_auth::VerifyError::Parse(e)) => {
            error!(%e);
            false
        }
    }
}

/// Axum handler for login requests (`/api/login`)
///
/// The body of the request must be URL query encoded [LoginForm]
///
/// If the login atttempt is correct, the response body contains a newly created access token for
/// the requested account.
#[axum::debug_handler]
pub async fn login_handler(
    state: State<ServerState>,
    cookie_jar: CookieJar,
    body: Form<LoginForm>,
) -> Result<(CookieJar, Body), StatusCode> {
    let login = query!(r#"SELECT * FROM Login WHERE email = ?"#, body.email)
        .fetch_one(&state.0.database.0)
        .await;
    let login = match login {
        Ok(login) => login,
        Err(sqlx::Error::RowNotFound) => {
            // No account with that email
            // Waste some time checking a garbage password to defend against timing attacks
            check_password("", "");
            return Err(StatusCode::UNAUTHORIZED);
        }
        Err(e) => {
            error!(%e);
            return Err(StatusCode::SERVICE_UNAVAILABLE);
        }
    };

    // Check if the password is bad
    if !check_password(body.password.as_ref(), login.password_hash.as_str()) {
        return Err(StatusCode::UNAUTHORIZED);
    }

    // Password is good, continue with login process

    // Option::xor returns Some if exactly one of it's arguments is Some

    let Some((account_id, account_kind)) = login
        .teacher_id
        .map(|id| (id, AccountKind::Teacher))
        .xor(login.student_id.map(|id| (id, AccountKind::Student)))
    else {
        error!(
            "Login with id {} does not have exactly one teacher/student id",
            login.login_id
        );
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    };

    let (access_token, fingerprint_cookie) =
        new_access_token(RowId(account_id), account_kind, state.0.auth.0).map_err(|e| {
            error!(%e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    let cookie_jar = cookie_jar.add(fingerprint_cookie);

    Ok((cookie_jar, Body::new(access_token)))
}
