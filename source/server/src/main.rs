extern crate actix_web;

use actix_web::{
    App,
    HttpRequest,
    Result,
    fs::NamedFile,
    http::Method,
    server,
};
use std::path::PathBuf;

macro_rules! ROOT_DIRECTORY { () => { "../../public/" }; }
const STATIC_DIRECTORY: &'static str = concat!(ROOT_DIRECTORY!(), "static/");

fn serve_static_files(request: HttpRequest) -> Result<NamedFile> {
    let mut path: PathBuf = PathBuf::from(STATIC_DIRECTORY);
    let tail: String = request.match_info().query("tail")?;

    path.push(tail);

    Ok(NamedFile::open(path)?)
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
                        .route(r"/{tail:.*}", Method::GET, serve_static_files),
                    App::new()
                        .prefix("/")
                        .route("/index.html", Method::GET, serve_index)
                        .route("/", Method::GET, serve_index)
                ]
            }
        )
        .bind("127.0.0.1:8889")
        .expect("Cannot bind the server to 127.0.0.1:8889.")
        .shutdown_timeout(30)
        .run();
}
