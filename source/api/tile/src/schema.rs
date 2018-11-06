table! {
    tiles (zoom_level, tile_column, tile_row) {
        zoom_level -> Integer,
        tile_column -> Integer,
        tile_row -> Integer,
        tile_data -> Binary,
    }
}

table! {
    metadata (name, value) {
        name -> Text,
        value -> Text,
    }
}
