extern crate hyper;
extern crate futures;
extern crate regex;

use futures::Future;
use futures::sync::oneshot;

use hyper::{Get, StatusCode};
use hyper::error::Error;
use hyper::header::ContentLength;
use hyper::server::{Http, Service, Request, Response};

#[macro_use] extern crate lazy_static;
use regex::Regex;

use std::fs::File;
use std::io::{self, copy};
use std::thread;

static NOTFOUND: &[u8] = b"Not Found";
static ROOT: &str = "../../public/";

fn serve_file(f: &str) -> Box<Future<Item = Response, Error = hyper::Error>> {
    let filename = f.to_string();
    let (tx, rx) = oneshot::channel();

    thread::spawn(
        move || {
            let mut file = match File::open(filename) {
                Ok(f) => f,

                Err(_) => {
                    tx.send(Response::new()
                            .with_status(StatusCode::NotFound)
                            .with_header(ContentLength(NOTFOUND.len() as u64))
                            .with_body(NOTFOUND))
                        .expect("Send error on open");

                    return;
                }
            };

            let mut buf: Vec<u8> = Vec::new();

            match copy(&mut file, &mut buf) {
                Ok(_) => {
                    let res = Response::new()
                        .with_header(ContentLength(buf.len() as u64))
                        .with_body(buf);

                    tx
                        .send(res)
                        .expect("Send error on successful file read");
                },

                Err(_) => {
                    tx
                        .send(Response::new()
                        .with_status(StatusCode::InternalServerError))
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
        let method = request.method();
        let path   = request.path();

        lazy_static! {
            static ref REGEX: Regex = Regex::new(r"^/(javascript/|css/|font/)").unwrap();
        }

        let is_static_file = REGEX.is_match(path);

        match (method, path, is_static_file) {
            (&Get, "/", _) | (&Get, "/index.html", _) => {
                serve_file(&format!("{}{}", ROOT, "index.html"))
            },

            (&Get, static_file, true) => {
                serve_file(&format!("{}{}", ROOT, static_file))
            },
            
            _ => {
                Box::new(
                    futures::future::ok(
                        Response::new().with_status(StatusCode::NotFound)
                    )
                )
            }
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
