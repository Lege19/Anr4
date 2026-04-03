//! Access tokens are used for short-term authentication.
//!
//! This module also includes handling of user fingerprint cookies, which are used to harden the
//! access tokens.
//!
//! The token is a JSON Web Token

use core::str;
use std::convert::Infallible;

use axum::{
    extract::{FromRef, FromRequestParts},
    http::{HeaderMap, StatusCode, header::AUTHORIZATION, request},
};
use axum_extra::extract::{CookieJar, cookie::Cookie};
use base64::{Engine, prelude::BASE64_STANDARD_NO_PAD};
use hmac::{Hmac, Mac};
use jwt::{SignWithKey, VerifyWithKey};
use rand_core::{OsRng, TryCryptoRng, TryRngCore};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256, Sha512};
use time::{Duration, OffsetDateTime};
use tracing::error;

use crate::database::RowId;

/// Length of the Access Token Secret
pub const HMAC_SECRET_LENGTH: usize = 512;
/// The type to be passed to functions that need to make or verify signatures
pub type HmacSha512 = Hmac<Sha512>;

/// An account kind to be stored in the claims of an access token.
///
/// Either teacher or student
#[derive(Serialize, Deserialize)]
pub enum AccountKind {
    /// Account kind for student accounts, corresponding to a `Login` where `student_id` is set to
    /// the ID of a row from `Student`, and `teacher_id` is set to `null`
    Student,
    /// Account kind for teacher accounts, corresponding to a `Login` where `teacher_id` is set to
    /// the ID of a row from `Teacher`, and `student_id` is set to `null`
    Teacher,
}

/// Stores the random key used to sign access tokens
///
/// This is generated once when the server starts,
/// and currently stays the same for the lifetime of the server.
///
/// If authentication and APIs get split between multiple servers in future,
/// this will need to be separated into a public and private key,
/// however currently this signature only uses a private key.
#[derive(Clone)]
pub struct JwtState(pub &'static HmacSha512);

impl Default for JwtState {
    fn default() -> Self {
        let mut secret = [0; HMAC_SECRET_LENGTH];
        OsRng
            .try_fill_bytes(&mut secret)
            .expect("Failed to access OS RNG to generate HMAC secret");
        Self(Box::leak(Box::new(
            HmacSha512::new_from_slice(&secret).expect("Failed to create HMAC"),
        )))
    }
}

/// The claims stored in the access token
///
/// This implements [FromRequestParts] so that it can be used as an extractor on request handlers,
/// automatically rejecting unauthenticated requests and allowing the handler to read the account
/// data for authenticated requests.
#[derive(Deserialize, Serialize)]
pub struct Claims {
    /// Account id
    /// This is a primary key in either the Teacher table or the Student table,
    /// depending on kind
    pub id: RowId,
    /// Kind of account. Student or Teacher
    pub kind: AccountKind,
    /// Base 64 encoded hash of the base 64 encoded random user fingerprint stored in the
    /// fingerprint cookie.
    /// This is hashed to make it impossible to find the original fingerprint without compromising
    /// the fingerprint cookie itself
    pub fingerprint: String,
    #[serde(with = "time::serde::timestamp")]
    /// Expiration date, after which the access token will be rejected by the server
    ///
    /// This is serialized as a unix timestamp.
    ///
    /// Annoyingly, this must be a [OffsetDateTime] not a [time::UtcDateTime],
    /// because this crate only provides serde serialization as a unix timestamp for
    /// [OffsetDateTime],
    /// in the form of [time::serde::timestamp].
    pub expiration: OffsetDateTime,
}

/// Randomly generates a cryptographically secure 64 byte fingerprint
fn make_fingerprint(rng_source: &mut impl TryCryptoRng) -> [u8; 64] {
    let mut fingerprint = [0; 64];

    rng_source
        .try_fill_bytes(&mut fingerprint)
        .expect("Failed to access OS RNG");
    fingerprint
}

/// The fingerprint cookie is extra security which ties a particular access token to the particular
/// device that holds the cookie. The cookie is marked as HTTP Only and Secure, to make it harder
/// to steal.
const FINGERPRINT_COOKIE_NAME: &str = "__Host-Http-Fgp";

/// Create a new access token for a particular account
pub fn new_access_token(
    id: RowId,
    kind: AccountKind,
    hmac: &HmacSha512,
) -> Result<(String, Cookie<'static>), jwt::Error> {
    // https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
    // 64 bytes of crytographically secure randomness
    let fingerprint = make_fingerprint(&mut OsRng);
    let fingerprint = BASE64_STANDARD_NO_PAD.encode(fingerprint);
    let fingerprint_hash = Sha256::digest(fingerprint.as_str());
    // NOTE: This is a hash of the base64 encoded fingerprint, not the binary fingerprint
    let fingerprint_hash = BASE64_STANDARD_NO_PAD.encode(fingerprint_hash);

    let max_age = Duration::minutes(15);
    let cookie = Cookie::build((FINGERPRINT_COOKIE_NAME, fingerprint))
        .http_only(true)
        .same_site(axum_extra::extract::cookie::SameSite::Strict)
        .path("/")
        .max_age(max_age)
        .secure(true)
        .build();

    // I think expecting on this is fine because if this happens once,
    // it will happen every single time a user tries to get a token.
    let expiration = OffsetDateTime::now_utc()
        .checked_add(max_age)
        .expect("Overflow in fingerprint cookie expiration date calculation");

    let claims = Claims {
        fingerprint: fingerprint_hash,
        id,
        kind,
        expiration,
    };
    claims.sign_with_key(hmac).map(|token| (token, cookie))
}

/// Verifies the signature on an access token
///
/// This does not perform any other validation
fn verify_access_token_signature(token: &str, hmac: &HmacSha512) -> Result<Claims, jwt::Error> {
    token.verify_with_key(hmac)
}

/// Verifies that the hashed fingerprint stored in the claims matches the unhashed fingerprint
/// (which is the second argument) from the fingerprint cookie.
fn check_fingerprint(claims: &Claims, fingerprint: &str) -> bool {
    // This reader is in memory so bytes should be fine
    let Ok(a) = BASE64_STANDARD_NO_PAD.decode(claims.fingerprint.as_bytes()) else {
        return false;
    };
    a.as_slice() == Sha256::digest(fingerprint).as_slice()
}

/// Extracts the access token string from the request [HeaderMap]
fn extract_access_token(headers: &HeaderMap) -> Option<&str> {
    headers
        .get(AUTHORIZATION)?
        .to_str()
        .ok()?
        .strip_prefix("Bearer ")
}

impl<S: Sync> FromRequestParts<S> for Claims
where
    JwtState: FromRef<S>,
{
    type Rejection = StatusCode;
    async fn from_request_parts(
        parts: &mut request::Parts,
        state: &S,
    ) -> Result<Self, Self::Rejection> {
        // Checklist:
        // - Verify signature
        // - Verify expiration
        // - Verify fingerprint

        let access_token = extract_access_token(&parts.headers).ok_or(StatusCode::UNAUTHORIZED)?;

        // Check signature
        let claims = verify_access_token_signature(access_token, JwtState::from_ref(state).0)
            .map_err(|e| {
                error!(%e);
                StatusCode::UNAUTHORIZED
            })?;

        // Check expiration
        if claims.expiration < OffsetDateTime::now_utc() {
            return Err(StatusCode::UNAUTHORIZED);
        }

        let cookie_jar: Result<CookieJar, Infallible> =
            CookieJar::from_request_parts(parts, &()).await;
        let cookie_jar = cookie_jar.expect("Infallible");
        let fingerprint = cookie_jar
            .get(FINGERPRINT_COOKIE_NAME)
            .ok_or(StatusCode::UNAUTHORIZED)?;
        // Check fingerprint
        if !check_fingerprint(&claims, fingerprint.value()) {
            return Err(StatusCode::UNAUTHORIZED);
        }

        Ok(claims)
    }
}

/// An axum extractor type.
///
/// This can be a parameter to a request handler
/// to automatically reject all requests that are not authenticated as a student,
/// and extract the student id from the claims of the valid access token to be passed to the
/// handler.
///
/// "Authenticated as a student" means the request comes with a valid access token,
/// with the account kind set to [AccountKind::Student]
pub struct StudentId(pub RowId);
/// Same idea as for [StudentId], but for [AccountKind::Teacher] instead
pub struct TeacherId(pub RowId);

impl<S: Sync> FromRequestParts<S> for StudentId
where
    JwtState: FromRef<S>,
{
    type Rejection = StatusCode;
    async fn from_request_parts(
        parts: &mut request::Parts,
        state: &S,
    ) -> Result<Self, Self::Rejection> {
        let claims = Claims::from_request_parts(parts, state).await?;
        match claims.kind {
            AccountKind::Student => Ok(StudentId(claims.id)),
            _ => Err(StatusCode::BAD_REQUEST),
        }
    }
}

impl<S: Sync> FromRequestParts<S> for TeacherId
where
    JwtState: FromRef<S>,
{
    type Rejection = StatusCode;
    async fn from_request_parts(
        parts: &mut request::Parts,
        state: &S,
    ) -> Result<Self, Self::Rejection> {
        let claims = Claims::from_request_parts(parts, state).await?;
        match claims.kind {
            AccountKind::Teacher => Ok(TeacherId(claims.id)),
            _ => Err(StatusCode::BAD_REQUEST),
        }
    }
}
