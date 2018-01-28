extern crate hyper;
extern crate mime;
extern crate futures;
extern crate regex;
#[macro_use]
extern crate lazy_static;

use futures::Future;
use futures::sync::oneshot;

use hyper::{
    Get,
    StatusCode
};
use hyper::error::Error;
use hyper::header::{
    ContentLength,
    ContentType
};
use hyper::server::{
    Http,
    Service,
    Request,
    Response
};

use regex::Regex;

use std::fs::File;
use std::io::{self, copy};
use std::thread;

static NOT_FOUND: &[u8] = b"Not Found";
static ROOT: &str = "../../public/";

#[derive(Copy, Clone)]
enum ResourceKind<'a> {
    Unknown(&'a str),
    Html(&'a str),
    Javascript(&'a str),
    Css(&'a str),
    Font(&'a str)
}

trait Path<'a> {
    fn path(self) -> &'a str;
}

impl<'a> Path<'a> for ResourceKind<'a> {
    fn path(self) -> &'a str {
        match self {
            ResourceKind::Unknown(path) |
            ResourceKind::Html(path) |
            ResourceKind::Javascript(path) |
            ResourceKind::Css(path) |
            ResourceKind::Font(path) => {
                path
            }
        }
    }
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

fn serve_static_file<'a>(resource: ResourceKind<'a>) -> Box<Future<Item = Response, Error = hyper::Error>> {
    let pathname     = resource.path().to_string();
    let content_type = match resource {
        ResourceKind::Unknown(_)    => ContentType::octet_stream(),
        ResourceKind::Html(_)       => ContentType::html(),
        ResourceKind::Javascript(_) => ContentType(mime::TEXT_JAVASCRIPT),
        ResourceKind::Css(_)        => ContentType(mime::TEXT_CSS),
        ResourceKind::Font(_)       => ContentType("application/font-woff".parse::<mime::Mime>().unwrap())
    };

    let (tx, rx) = oneshot::channel();

    thread::spawn(
        move || {
            let mut file = match File::open(format!("{}{}", ROOT, pathname)) {
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
                                .with_header(content_type)
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
                serve_static_file(ResourceKind::Html(&format!("static{}", "/index.html")))
            },


            (&Get, r @ ResourceKind::Html(_)) |
            (&Get, r @ ResourceKind::Javascript(_)) |
            (&Get, r @ ResourceKind::Css(_)) |
            (&Get, r @ ResourceKind::Font(_)) => {
                serve_static_file(r)
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
