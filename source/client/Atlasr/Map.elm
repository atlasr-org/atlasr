module Atlasr.Map exposing (..)

import Atlasr.Position exposing (LongitudeLatitude)
import Atlasr.MapboxGL.Options as Options
import Atlasr.MapboxGL.Ports exposing (..)


create : String -> Options.Map -> Cmd msg
create id options =
    mapboxgl_create_map ( id, options )


jumpTo : LongitudeLatitude -> Cmd msg
jumpTo longitudeLatitude =
    mapboxgl_jump_to { center = longitudeLatitude }
