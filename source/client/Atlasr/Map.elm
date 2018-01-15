module Atlasr.Map exposing (..)

import Atlasr.MapboxGL.Options as Options
import Atlasr.MapboxGL.Ports exposing (..)


create : String -> Options.Map -> Cmd msg
create id options =
    mapboxgl_create_map ( id, options )
