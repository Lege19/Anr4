//! The library part of the server
//!
//! Anything that is needed in main.rs is imported via here
#![allow(rustdoc::private_intra_doc_links)]
#![warn(missing_docs)]
#![warn(clippy::missing_docs_in_private_items)]
#![warn(rustdoc::missing_crate_level_docs)]

pub mod api;
pub mod auth;
pub mod database;
pub mod https_server_boilerplate;
pub mod server_state;
