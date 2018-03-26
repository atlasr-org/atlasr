module Atlasr.Map exposing (..)

import Atlasr.Position exposing (Position)
import Atlasr.MapboxGL.Options as Options
import Atlasr.MapboxGL.Ports exposing (..)


{-| Create a map with an ID and some options.
-}
create : String -> Options.Map -> Cmd msg
create id options =
    mapboxgl_create_map ( id, options )


{-| Move the camera to a specific position.
-}
flyTo : Position -> Cmd msg
flyTo position =
    mapboxgl_fly_to { center = position }


{-| Add markers to certain positions, and connect them.
-}
addAndConnectMarkers : List Position -> Cmd msg
addAndConnectMarkers positions =
    mapboxgl_add_and_connect_markers positions


{-| Remove all markers.
-}
removeMarkers : Cmd msg
removeMarkers =
    mapboxgl_remove_markers ()
