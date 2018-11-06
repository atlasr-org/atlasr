extern crate actix_web;
extern crate futures;

use actix_web::{
    App,
    HttpRequest,
    HttpResponse,
    Result,
    dev::HttpResponseBuilder,
    fs::NamedFile,
    http::Method,
    client,
    server,
};
use futures::Future;
use std::path::PathBuf;

macro_rules! ROOT_DIRECTORY { () => { "../../public/" }; }
const STATIC_DIRECTORY: &'static str = concat!(ROOT_DIRECTORY!(), "static/");
const SERVER_ADDRESS: &'static str = env!("SERVER_ADDRESS");
const ROUTE_API_ADDRESS: &'static str = env!("ROUTE_API_ADDRESS");
const GEOCODE_API_ADDRESS: &'static str = env!("GEOCODE_API_ADDRESS");
const TILE_API_ADDRESS: &'static str = env!("TILE_API_ADDRESS");

fn serve_static_files(request: HttpRequest) -> Result<NamedFile> {
    let mut path: PathBuf = PathBuf::from(STATIC_DIRECTORY);
    let tail: String = request.match_info().query("tail")?;

    path.push(tail);

    Ok(NamedFile::open(path)?)
}

fn serve_api_geocode(request: HttpRequest) -> impl Future<Item=HttpResponse, Error=client::SendRequestError> {
    client
        ::get(format!("http://{}/search?{}", GEOCODE_API_ADDRESS, request.query_string()))
        .finish()
        .unwrap()
        .send()
        .map(
            |client_response| {
                HttpResponseBuilder
                    ::from(&client_response)
                    .chunked()
                    .streaming(client_response)
            }
        )
}

fn serve_api_route(request: HttpRequest) -> impl Future<Item=HttpResponse, Error=client::SendRequestError> {
    client
        ::get(format!("http://{}/route?{}", ROUTE_API_ADDRESS, request.query_string()))
        .finish()
        .unwrap()
        .send()
        .map(
            |client_response| {
                HttpResponseBuilder
                    ::from(&client_response)
                    .chunked()
                    .streaming(client_response)
            }
        )
}

fn serve_api_tile(request: HttpRequest) -> impl Future<Item=HttpResponse, Error=client::SendRequestError> {
    let tail = request.match_info().get("tail").unwrap_or("");

    client
        ::get(format!("http://{}/{}", TILE_API_ADDRESS, tail))
        .finish()
        .unwrap()
        .send()
        .map(
            |client_response| {
                HttpResponseBuilder
                    ::from(&client_response)
                    .chunked()
                    .streaming(client_response)
            }
        )
}

fn serve_index(_request: HttpRequest) -> Result<NamedFile> {
    let mut path: PathBuf = PathBuf::from(STATIC_DIRECTORY);

    path.push("index.html");

    Ok(NamedFile::open(path)?)
}

fn main() {
    server
        ::new(
            || {
                vec![
                    App::new()
                        .prefix("/static")
                        .resource(
                            r"/{tail:.*}",
                            |resource| {
                                resource.method(Method::GET).f(serve_static_files)
                            }
                        ),

                    App::new()
                        .prefix("/api")
                        .resource(
                            "/geocode",
                            |resource| {
                                resource.method(Method::GET).a(serve_api_geocode)
                            }
                        )
                        .resource(
                            "/route",
                            |resource| {
                                resource.method(Method::GET).a(serve_api_route)
                            }
                        )
                        .resource(
                            "/tile/{tail:.*}",
                            |resource| {
                                resource.method(Method::GET).a(serve_api_tile)
                            }
                        ),

                    App::new()
                        .prefix("/")
                        .resource(
                            "/index.html",
                            |resource| {
                                resource.method(Method::GET).f(serve_index)
                            }
                        )
                        .resource(
                            "/",
                            |resource| {
                                resource.method(Method::GET).f(serve_index)
                            }
                        )
                ]
            }
        )
        .bind(SERVER_ADDRESS)
        .expect(&format!("Cannot bind the server to {}.", SERVER_ADDRESS))
        .shutdown_timeout(30)
        .run();
}
