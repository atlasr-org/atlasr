#[macro_use]
extern crate warp;
#[macro_use]
extern crate diesel;
extern crate r2d2;
extern crate r2d2_diesel;
extern crate serde_json as json;

use warp::Filter;
use warp::http;
use diesel::prelude::*;
use r2d2_diesel::ConnectionManager;
use std::net::SocketAddr;
use std::str::FromStr;

mod schema;
mod models;

const SERVER_ADDRESS: &'static str = env!("SERVER_ADDRESS");
const TILE_API_ADDRESS: &'static str = env!("TILE_API_ADDRESS");

fn not_found() -> http::Result<http::Response<Vec<u8>>> {
    http::Response::builder()
        .status(http::StatusCode::NOT_FOUND)
        .header("content-type", "text/plain; charset=utf-8")
        .body(vec![])
}

fn error() -> http::Result<http::Response<String>> {
    http::Response::builder()
        .status(http::StatusCode::NOT_FOUND)
        .header("content-type", "text/plain; charset=utf-8")
        .body("error".to_string())
}

fn main() {
    let manager = ConnectionManager::<SqliteConnection>::new("database/europe_switzerland.mbtiles");
    let pool =
        r2d2::Pool::builder()
            .max_size(15)
            .build(manager)
            .expect("Failed to create pool.");

    let pool1 = pool.clone();
    let pool2 = pool.clone();

    // `GET /<zoom_level>/<tile_column>/<tile_row>/`
    let tiles =
        path!(u8 / u16 / u16)
            .map(
                move |z, x, y| {
                    match pool1.get() {
                        Ok(connection) => {
                            use schema::tiles::dsl::*;
                            use models::Tiles;

                            let x = x as u32;
                            let y = y as u32;
                            let z = z as u32;

                            let y = 2u32.pow(z) - 1 - y;

                            let tile =
                                tiles
                                    .filter(zoom_level.eq(z as i32))
                                    .filter(tile_column.eq(x as i32))
                                    .filter(tile_row.eq(y as i32))
                                    .first::<Tiles>(&*connection);

                            match tile {
                                Ok(tile) => {
                                    http::Response::builder()
                                        .header("content-type", "application/x-protobuf")
                                        .header("content-encoding", "gzip")
                                        .body(tile.tile_data)
                                },

                                Err(_) => {
                                    not_found()
                                }
                            }
                        },

                        Err(_) => {
                            not_found()
                        }
                    }
                }
            );

    // `GET /metadata.json`
    let metadata =
        path!("metadata.json")
            .map(
                move || {
                    match pool2.get() {
                        Ok(connection) => {
                            use schema::metadata::dsl::*;
                            use models::Metadata;

                            match metadata.load::<Metadata>(&*connection) {
                                Ok(all_metadata) => {
                                    let mut output = json::map::Map::with_capacity(all_metadata.len());

                                    for metadatum in all_metadata {
                                        let v = metadatum.value;

                                        let map_value = match metadatum.name.as_ref() {
                                            "bounds" | "center" => {
                                                Ok(
                                                    json::Value::Array(
                                                        v
                                                            .splitn(4, ',')
                                                            .map(
                                                                |p| {
                                                                    json::Value::Number(
                                                                        json::Number::from_str(p).unwrap_or_else(|_| json::Number::from_f64(0.0).unwrap())
                                                                    )
                                                                }
                                                            )
                                                            .collect()
                                                    )
                                                )
                                            },

                                            "json" => {
                                                if let Ok(json::Value::Object(meta_metadata)) = json::from_str(&v) {
                                                    output.extend(meta_metadata);
                                                }

                                                Err(())
                                            },

                                            _ => Ok(json::Value::String(v))
                                        };

                                        if let Ok(map_value) = map_value {
                                            output.insert(metadatum.name, map_value);
                                        }
                                    }

                                    if !output.contains_key("profile") {
                                        output.insert("profile".to_string(), json::Value::String("mercator".to_string()));
                                    }

                                    if !output.contains_key("scale") {
                                        output.insert("scale".to_string(), json::Value::Number(json::Number::from_f64(1.0).unwrap()));
                                    }

                                    if !output.contains_key("tilejson") {
                                        output.insert("tilejson".to_string(), json::Value::String("2.0.0".to_string()));
                                    }

                                    if !output.contains_key("tiles") {
                                        output.insert(
                                            "tiles".to_string(),
                                            json::Value::Array(vec![
                                                json::Value::String(
                                                    format!("http://{}/api/tile/{{z}}/{{x}}/{{y}}", SERVER_ADDRESS)
                                                )
                                            ])
                                        );
                                    }

                                    http::Response::builder()
                                        .header("content-type", "application/json")
                                        .body(json::to_string(&output).unwrap())
                                },

                                Err(_) => error()
                            }
                        },

                        Err(_) => error()
                    }
                }
            );

    let routes = tiles.or(metadata);

    warp::serve(routes)
        .run(TILE_API_ADDRESS.parse::<SocketAddr>().expect(&format!("Cannot bind the server to {}", TILE_API_ADDRESS)));
}
