//! There's a lot of boilerplate involved in setting up the server.
//! This module keeps that separate from the interesting stuff of actually responding to requests.
//!
//! Some parts of this are based on: <https://github.com/tokio-rs/axum/blob/main/examples/tls-rustls/src/main.rs>

use axum::{
    Router,
    handler::HandlerWithoutStateExt,
    http::{Response, StatusCode, Uri, uri::Authority},
    middleware::map_response,
    response::Redirect,
};
use axum_csp::{CspDirectiveType, CspHeaderBuilder, CspValue};
use axum_extra::extract::Host;
use axum_server::{Handle, tls_rustls::RustlsConfig};
use std::{
    future,
    net::{IpAddr, Ipv4Addr, SocketAddr},
    path::PathBuf,
    time::Duration,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::server_state::ServerState;

/// How long the graceful shutdown should wait for handlers to finish before un-gracefully shutting
/// down the server
const SHUTDOWN_GRACE_PERIOD: Option<Duration> = Some(Duration::from_secs(20));
/// The port the http redirect server should listen on
const HTTP_PORT: u16 = 3001;
/// The port the main https server should listen on
const HTTPS_PORT: u16 = 3000;
/// The IP address to listen to
const IP_ADDR: IpAddr = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
/// The full address (IP and port) for the HTTP redirect server
const HTTP_ADDR: SocketAddr = SocketAddr::new(IP_ADDR, HTTP_PORT);
/// The full address (IP and port) for the main HTTPS server
const HTTPS_ADDR: SocketAddr = SocketAddr::new(IP_ADDR, HTTPS_PORT);

/// Add CSP headers to a response.
///
/// The reason for this being a higher order function is so that the CSP is only constructed once,
fn add_headers<B>() -> impl Clone + Fn(Response<B>) -> future::Ready<Response<B>> {
    let csp = CspHeaderBuilder::new()
        // Default to denying all sources, makes sure I know exactly what's going on
        .add(CspDirectiveType::DefaultSrc, vec![CspValue::None])
        // Needed so request for favicon.svg is allowed
        .add(CspDirectiveType::ImgSrc, vec![CspValue::SelfSite])
        // Needed so requests for scripts are allowed
        .add(CspDirectiveType::ScriptSource, vec![CspValue::SelfSite])
        .add(
            CspDirectiveType::StyleSource,
            if cfg!(debug_assertions) {
                vec![CspValue::UnsafeInline]
            } else {
                vec![CspValue::UnsafeInline, CspValue::SelfSite]
            },
        )
        // Allow connecting to the backend
        // Also allow connecting to the vite websocket in dev builds
        .add(
            CspDirectiveType::ConnectSrc,
            if cfg!(debug_assertions) {
                vec![
                    CspValue::SelfSite,
                    CspValue::Host {
                        value: "ws://localhost:5173".to_string(),
                    },
                ]
            } else {
                vec![CspValue::SelfSite]
            },
        )
        .finish();

    move |mut response: Response<B>| {
        let headers = response.headers_mut();
        headers.append("Content-Security-Policy", csp.clone());
        future::ready(response)
    }
}

/// Serve an app
///
/// Manages:
/// - HTTP redirect server
/// - HTTPS server creation
/// - Graceful shutdown
pub async fn serve(app: Router<ServerState>) {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| format!("{}=debug", env!("CARGO_CRATE_NAME")).into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // spawn a second server to redirect http requests to the https server
    tokio::spawn(redirect_http::serve_redirect());

    // configure tls certificate and private key
    let config = RustlsConfig::from_pem_file(
        PathBuf::from(std::env::var("TLS_CERT_PATH").expect("TLS_CERT_PATH not provided")),
        PathBuf::from(std::env::var("TLS_KEY_PATH").expect("TLS_KEY_PATH not provided")),
    )
    .await
    .expect("Failed to read TLS certificte");

    let server_handle = Handle::new();

    tokio::spawn(graceful_shutdown(server_handle.clone()));

    tracing::debug!("listening on {}", HTTPS_ADDR);
    axum_server::bind_rustls(HTTPS_ADDR, config)
        .handle(server_handle)
        .serve(
            app.layer(tower_http::trace::TraceLayer::new_for_http())
                .layer(map_response(add_headers()))
                .with_state(ServerState::default())
                .into_make_service(),
        )
        .await
        .expect("Failed to start main server");
    println!("Server shut down successfully");
}

/// Module encapsulating functionality relating to the HTTP redirect server
mod redirect_http {
    use thiserror::Error;

    use super::*;
    /// Errors that can occur in computing the URI to redirect an HTTPS request to
    ///
    /// I'm not aware of this ever failing
    #[derive(Debug, Error)]
    enum GetRedirectUriError {
        /// Failed to parse the host of the original request
        #[error(
            "Failed to parse `host: &str` into a `http::uri::Authority`. Host was: {host}. Failed with error: {parse_error}"
        )]
        HostParseError {
            /// The host that could not be parsed
            host: String,
            /// The particular parse error generated
            parse_error: axum::http::uri::InvalidUri,
        },
        /// After changing the host to the redirected host, the [axum::http::uri::Parts] were now invalid and could not be converted to a [axum::http::uri::Uri]
        #[error("Faild to create final URI for http redirect: {0}")]
        InvalidUriParts(#[from] axum::http::uri::InvalidUriParts),
        #[error(
            "Parse error on hostname with corrected port. Bare host was: {bare_host}. Failed with error: {parse_error}"
        )]
        /// After appending the port to the hostname, it was no longer valid
        FailedToAppendPort {
            /// The host without the port
            bare_host: String,
            /// The particular parse error resulting from attempting to parse the host name with
            /// the port appended
            parse_error: axum::http::uri::InvalidUri,
        },
    }

    /// Compute the Uri to redirect an HTTP request to.
    ///
    /// This tries to replace the scheme with HTTPS and the port with the port of the HTTPS server
    fn get_redirect_uri(host: &str, uri: Uri, https_port: u16) -> Result<Uri, GetRedirectUriError> {
        let mut parts = uri.into_parts();

        parts.scheme = Some(axum::http::uri::Scheme::HTTPS);

        if parts.path_and_query.is_none() {
            parts.path_and_query = Some("/".parse().expect("Parse a constant"));
        }

        let authority: Authority = match host.parse() {
            Ok(authority) => authority,
            Err(error) => {
                return Err(GetRedirectUriError::HostParseError {
                    host: host.to_string(),
                    parse_error: error,
                });
            }
        };
        let bare_host = match authority.port() {
            Some(port_struct) => authority
                .as_str()
                .strip_suffix(port_struct.as_str())
                .unwrap()
                .strip_suffix(':')
                .unwrap(), // if authority.port() is Some(port) then we can be sure authority ends with :{port}
            None => authority.as_str(),
        };

        parts.authority = match format!("{bare_host}:{https_port}").parse() {
            Ok(authority) => Some(authority),
            Err(error) => {
                return Err(GetRedirectUriError::FailedToAppendPort {
                    bare_host: bare_host.to_string(),
                    parse_error: error,
                });
            }
        };

        Ok(Uri::from_parts(parts)?)
    }
    /// Starts the HTTP redirect server
    /// Since this server does very little, graceful shutdown is of little concern
    pub async fn serve_redirect() {
        let redirect = move |Host(host): Host, uri: Uri| async move {
            match get_redirect_uri(&host, uri, HTTPS_PORT) {
                Ok(uri) => Ok(Redirect::permanent(&uri.to_string())),
                Err(error) => {
                    tracing::warn!(%error, "failed to convert URI to HTTPS");
                    Err(StatusCode::BAD_REQUEST)
                }
            }
        };

        let listener = tokio::net::TcpListener::bind(HTTP_ADDR).await.unwrap();
        tracing::debug!("listening on {}", listener.local_addr().unwrap());
        axum::serve(listener, redirect.into_make_service())
            .await
            .unwrap();
    }
}

/// Gacefully shutsdown a server when ctrl-c is pressed
///
/// See also:
/// - <https://tokio.rs/tokio/topics/shutdown>
/// - <https://github.com/programatik29/axum-server/blob/master/examples/graceful_shutdown.rs>
async fn graceful_shutdown(handle: Handle) {
    match tokio::signal::ctrl_c().await {
        Ok(()) => {
            handle.graceful_shutdown(SHUTDOWN_GRACE_PERIOD);
            println!("\rShutting down");
        }
        Err(err) => {
            eprintln!("Unable to listen for ctrl_c: {err}");
            handle.graceful_shutdown(SHUTDOWN_GRACE_PERIOD);
        }
    }
}
