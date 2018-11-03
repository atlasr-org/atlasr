port module Atlasr.MapboxGL.Ports exposing (mapboxgl_add_markers, mapboxgl_connect_markers, mapboxgl_create_map, mapboxgl_fly_to, mapboxgl_remove_markers)

import Atlasr.MapboxGL.Options as Options
import Atlasr.Position exposing (Position)


port mapboxgl_create_map : ( String, Options.Map ) -> Cmd msg


port mapboxgl_fly_to : Options.Camera -> Cmd msg


port mapboxgl_add_markers : List Position -> Cmd msg


port mapboxgl_remove_markers : () -> Cmd msg


port mapboxgl_connect_markers : List Position -> Cmd msg
