module Map exposing (..)

import MapboxGL.Ports exposing (..)


create : String -> Cmd msg
create id =
    mapboxgl_create_map id
