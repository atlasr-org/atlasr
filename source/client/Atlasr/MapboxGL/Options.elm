module Atlasr.MapboxGL.Options exposing (..)

import Atlasr.Position exposing (Position)


type alias Map =
    { style : String
    , center : Position
    , zoom : Int
    , hash : Bool
    , pitchWithRotate : Bool
    , attributionControl : Bool
    , dragRotate : Bool
    , dragPan : Bool
    , keyboard : Bool
    , doubleClickZoom : Bool
    , touchZoomRotate : Bool
    , trackResize : Bool
    , renderWorldCopies : Bool
    }


default : Map
default =
    { style = "https://openmaptiles.github.io/osm-bright-gl-style/style-cdn.json"
    , center = ( 2.294504285127, 48.858262790681 )
    , zoom = 15
    , hash = True
    , pitchWithRotate = True
    , attributionControl = True
    , dragRotate = True
    , dragPan = True
    , keyboard = True
    , doubleClickZoom = True
    , touchZoomRotate = True
    , trackResize = True
    , renderWorldCopies = True
    }


type alias Camera =
    { center : Position }
