//! Pulls together the state required by certain parts of the server into a single type to be used
//! as the top level state for axum
use axum::extract::FromRef;

use crate::{auth::AuthState, database::DatabaseState};

/// The global axum server state
#[derive(Clone, Default, FromRef)]
pub struct ServerState {
    /// The state needed for accessing the database
    pub database: DatabaseState,
    /// The state used by the authentication system
    pub auth: AuthState,
}
