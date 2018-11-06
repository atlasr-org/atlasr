#[macro_use]
extern crate warp;
#[macro_use]
extern crate diesel;
extern crate r2d2;
extern crate r2d2_diesel;
extern crate either;

use warp::Filter;
use warp::http;
use diesel::prelude::*;
use r2d2_diesel::ConnectionManager;
use either::Either;
use std::net::SocketAddr;

mod schema;
mod models;

const TILE_API_ADDRESS: &'static str = env!("TILE_API_ADDRESS");

fn not_found() -> http::Result<http::Response<Vec<u8>>> {
    http::Response::builder()
        .status(http::StatusCode::NOT_FOUND)
        .header("content-type", "text/hml; charset=utf-8")
        .body(vec![])
}

fn main() {
    use schema::tiles::dsl::*;
    use models::Tiles;

    let manager = ConnectionManager::<SqliteConnection>::new("database/europe_switzerland.mbtiles");
    let pool =
        r2d2::Pool::builder()
            .max_size(15)
            .build(manager)
            .expect("Failed to create pool.");

    // `GET /zoom/tile_column/tile_row/`
    let tile =
        path!(u8 / u16 / u16)
            .map(
                move |z, c, r| {
                    match pool.get() {
                        Ok(connection) => {
                            let tile =
                                tiles
                                    .filter(zoom_level.eq(z as i32))
                                    .filter(tile_column.eq(c as i32))
                                    .filter(tile_row.eq(r as i32))
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

    let content_type = warp::header::exact("Content-Type", "application/x-protobuf");

    warp::serve(tile)
        .run(TILE_API_ADDRESS.parse::<SocketAddr>().expect(&format!("Cannot bind the server to {}", TILE_API_ADDRESS)));
}
