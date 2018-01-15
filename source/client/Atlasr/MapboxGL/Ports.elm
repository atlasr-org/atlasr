port module Atlasr.MapboxGL.Ports exposing (..)

import Atlasr.MapboxGL.Options as Options


port mapboxgl_create_map : ( String, Options.Map ) -> Cmd msg
