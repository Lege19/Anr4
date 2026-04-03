//! Exports [api_routes]
#[cfg(debug_assertions)]
use axum::extract::{Path, State};
use axum::{
    Router,
    routing::{get, post},
};
#[cfg(debug_assertions)]
use password_auth::generate_hash;

use crate::{auth, server_state::ServerState};

mod queries;

/// Just useful during development for generating passwords
#[cfg(debug_assertions)]
async fn password_hash(Path(password): Path<Box<str>>, _: State<ServerState>) -> String {
    generate_hash(&*password)
}

/// Constructs an axum router to be nested under `/api` to serve all api routes
pub fn api_routes() -> Router<ServerState> {
    let mut routes = Router::new();

    routes = routes
        .route("/login", post(auth::login_handler))
        .route("/student_info", get(queries::student_info))
        .route("/teacher_info", get(queries::teacher_info))
        .route("/data/cohorts", post(queries::cohorts))
        .route("/data/courses", post(queries::courses))
        .route("/data/topics", post(queries::topics))
        .route("/data/words", post(queries::words))
        .route("/data/progress", post(queries::progress))
        .route("/progress/push", post(queries::push_progress));

    #[cfg(debug_assertions)]
    {
        routes = routes.route("/password_hash/{password}", get(password_hash));
    }
    routes
}
