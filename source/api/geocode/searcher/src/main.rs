extern crate actix_web;
extern crate tantivy;

use actix_web::{
    App,
    HttpRequest,
    HttpResponse,
    http::Method,
    server
};
use tantivy::{
    Index,
    collector::TopCollector,
    directory,
    query::QueryParser
};

struct SearchState {
    index: Index,
    query_parser: QueryParser
}

fn serve_search(request: HttpRequest<SearchState>) -> HttpResponse {
    let term: &str;

    match request.match_info().get("term") {
        Some(value) => {
            term = value;
        },

        None => {
            return HttpResponse::BadRequest().reason("`term` is missing").finish();
        }
    }

    let index = &request.state().index;
    let query_parser = &request.state().query_parser;

    let schema = index.schema();
    let searcher = index.searcher();

    let query = match query_parser.parse_query(term) {
        Ok(value) => {
            value
        },

        Err(_) => {
            return HttpResponse::InternalServerError().finish();
        }
    };

    let mut top_collector = TopCollector::with_limit(10);

    match searcher.search(&*query, &mut top_collector) {
        Err(_) => {
            return HttpResponse::InternalServerError().finish();
        }

        _ => { }
    }

    let mut response = String::from("[");

    for document in top_collector.docs() {
        let retrieved_document = match searcher.doc(&document) {
            Ok(value) => {
                value
            },

            Err(_) => {
                return HttpResponse::InternalServerError().finish();
            }
        };

        response.push_str(&schema.to_json(&retrieved_document));
        response.push_str(",");
    }

    if response.len() > 1 {
        response.pop();
    }

    response.push_str("]");

    HttpResponse::Ok().content_type("application/json").body(response)
}

fn main() {
    server
        ::new(
            || {
                App
                    ::with_state(
                        {
                            let index = Index::open(directory::MmapDirectory::open("../test").unwrap()).unwrap();
                            index.load_searchers().unwrap();

                            let schema = index.schema();
                            let query_parser = QueryParser::for_index(
                                &index,
                                vec![
                                    schema.get_field("name").unwrap(),
                                    schema.get_field("alternative_names").unwrap()
                                ]
                            );

                            SearchState {
                                index: index,
                                query_parser: query_parser
                            }
                        }
                    )
                    .resource(
                        "/search/{term}",
                        |resource| {
                            resource.method(Method::GET).f(serve_search)
                        }
                    )
            }
        )
        .bind("127.0.0.1:8887")
        .expect("Cannot bind the server to 127.0.0.1:8887.")
        .shutdown_timeout(30)
        .run();
}
