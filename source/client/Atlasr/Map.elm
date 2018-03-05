module Atlasr.Map exposing (..)

import Atlasr.Position exposing (LongitudeLatitude)
import Atlasr.MapboxGL.Options as Options
import Atlasr.MapboxGL.Ports exposing (..)


create : String -> Options.Map -> Cmd msg
create id options =
    mapboxgl_create_map ( id, options )


flyTo : LongitudeLatitude -> Cmd msg
flyTo longitudeLatitude =
    mapboxgl_fly_to { center = longitudeLatitude }
