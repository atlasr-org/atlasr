module Atlasr.Map exposing (..)

import Atlasr.MapboxGL.Ports exposing (..)


create : String -> Cmd msg
create id =
    mapboxgl_create_map id
