use axum::Router;
use vocab::{api::api_routes, https_server_boilerplate::serve, server_state::ServerState};

use vite_rs_axum_0_8::ViteServe;

#[derive(vite_rs::Embed)]
#[root = "./website"]
#[dev_server_port = "5173"]
struct Assets;

#[tokio::main]
async fn main() {
    serve(
        Router::<ServerState>::new()
            .nest("/api", api_routes())
            .route_service("/", ViteServe::new(Assets::boxed()))
            .route_service("/{*path}", ViteServe::new(Assets::boxed())),
    )
    .await;
}
