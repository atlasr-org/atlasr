module Atlasr.MapboxGL.Options exposing (..)

import Atlasr.Position exposing (LongitudeLatitude)


type alias Map =
    { style : String
    , center : LongitudeLatitude
    , zoom : Int
    }


default : Map
default =
    { style = "https://openmaptiles.github.io/osm-bright-gl-style/style-cdn.json"
    , center = ( 2.294504285127, 48.858262790681 )
    , zoom = 15
    }
