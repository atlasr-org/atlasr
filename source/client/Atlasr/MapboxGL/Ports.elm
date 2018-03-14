port module Atlasr.MapboxGL.Ports exposing (..)

import Atlasr.MapboxGL.Options as Options
import Atlasr.Position exposing (Longitude, Latitude)


port mapboxgl_create_map : ( String, Options.Map ) -> Cmd msg


port mapboxgl_fly_to : Options.Camera -> Cmd msg


port mapboxgl_add_marker : ( Longitude, Latitude ) -> Cmd msg
