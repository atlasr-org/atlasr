module Atlasr.Map exposing (addMarkers, connectMarkers, create, flyTo, removeMarkers)

import Atlasr.MapboxGL.Options as Options
import Atlasr.MapboxGL.Ports exposing (..)
import Atlasr.Position exposing (Position)


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
addMarkers : List Position -> Cmd msg
addMarkers positions =
    mapboxgl_add_markers positions


{-| Remove all markers.
-}
removeMarkers : Cmd msg
removeMarkers =
    mapboxgl_remove_markers ()


{-| Draw lines between points/positions.
-}
connectMarkers : List Position -> Cmd msg
connectMarkers positions =
    mapboxgl_connect_markers positions
