extern crate hyper;
extern crate futures;
extern crate regex;
#[macro_use]
extern crate lazy_static;

use futures::Future;
use futures::sync::oneshot;

use hyper::{Get, StatusCode};
use hyper::error::Error;
use hyper::header::ContentLength;
use hyper::server::{Http, Service, Request, Response};

use regex::Regex;

use std::fs::File;
use std::io::{self, copy};
use std::thread;

static NOT_FOUND: &[u8] = b"Not Found";
static ROOT: &str = "../../public/";

enum ResourceKind<'a> {
    Unknown(&'a str),
    Html(&'a str),
    Javascript(&'a str),
    Css(&'a str),
    Font(&'a str)
}

fn guess_resource_kind(path: &str) -> ResourceKind {
    lazy_static! {
        static ref STATIC_RESOURCE: Regex = Regex::new(r"^/static(/[a-zA-Z0-9\-]+)+(\.[a-z]+)+$").unwrap();
        static ref HTML_FILE: Regex       = Regex::new(r"\.html$").unwrap();
        static ref JAVASCRIPT_FILE: Regex = Regex::new(r"\.js|\.map$").unwrap();
        static ref CSS_FILE: Regex        = Regex::new(r"\.css$").unwrap();
        static ref FONT_FILE: Regex       = Regex::new(r"\.woff$").unwrap();
    }

    if path == "/index.html" {
        ResourceKind::Html(path)
    } else if STATIC_RESOURCE.is_match(path) {
        if HTML_FILE.is_match(path) {
            ResourceKind::Html(path)
        } else if JAVASCRIPT_FILE.is_match(path) {
            ResourceKind::Javascript(path)
        } else if CSS_FILE.is_match(path) {
            ResourceKind::Css(path)
        } else if FONT_FILE.is_match(path) {
            ResourceKind::Font(path)
        } else {
            ResourceKind::Unknown(path)
        }
    } else {
        ResourceKind::Unknown(path)
    }
}

fn serve_static_file(path: &str) -> Box<Future<Item = Response, Error = hyper::Error>> {
    let pathname = path.to_string();
    let (tx, rx) = oneshot::channel();

    thread::spawn(
        move || {
            let mut file = match File::open(pathname) {
                Ok(f) => f,

                Err(_) => {
                    tx.send(
                        Response::new()
                            .with_status(StatusCode::NotFound)
                            .with_header(ContentLength(NOT_FOUND.len() as u64))
                            .with_body(NOT_FOUND)
                    ).expect("Send error on open");

                    return;
                }
            };

            let mut buf: Vec<u8> = Vec::new();

            match copy(&mut file, &mut buf) {
                Ok(_) => {
                    tx
                        .send(
                            Response::new()
                                .with_header(ContentLength(buf.len() as u64))
                                .with_body(buf)
                        )
                        .expect("Send error on successful file read");
                },

                Err(_) => {
                    tx
                        .send(
                            Response::new()
                                .with_status(StatusCode::InternalServerError)
                        )
                        .expect("Send error on error reading file");
                }
            };
        }
    );

    Box::new(rx.map_err(|e| Error::from(io::Error::new(io::ErrorKind::Other, e))))
}

struct StaticResponses;

impl Service for StaticResponses {
    type Request  = Request;
    type Response = Response;
    type Error    = hyper::Error;
    type Future   = Box<Future<Item = Self::Response, Error = Self::Error>>;

    fn call(&self, request: Request) -> Self::Future {
        match (request.method(), guess_resource_kind(request.path())) {
            (&Get, ResourceKind::Unknown("/")) |
            (&Get, ResourceKind::Html("/index.html")) => {
                serve_static_file(&format!("{}static{}", ROOT, "/index.html"))
            },


            (&Get, ResourceKind::Html(path)) |
            (&Get, ResourceKind::Javascript(path)) |
            (&Get, ResourceKind::Css(path)) |
            (&Get, ResourceKind::Font(path)) => {
                serve_static_file(&format!("{}{}", ROOT, path))
            }

            _ => {
                Box::new(
                    futures::future::ok(
                        Response::new().with_status(StatusCode::NotFound)
                    )
                )
            },
        }
    }
}


fn main() {
    let addr   = "127.0.0.1:8889".parse().unwrap();
    let server = Http::new().bind(
        &addr,
        || Ok(StaticResponses)
    ).unwrap();

    println!("Listening on http://{} with 1 thread.", server.local_addr().unwrap());
    server.run().unwrap();
}
