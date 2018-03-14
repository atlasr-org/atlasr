module Atlasr.Position exposing (..)


type alias Longitude =
    Float


type alias Latitude =
    Float


type alias Position =
    ( Longitude, Latitude )


defaultPosition : Position
defaultPosition =
    ( 0.0, 0.0 )


extractLongitude : Position -> Float
extractLongitude ( longitude, _ ) =
    longitude


extractLatitude : Position -> Float
extractLatitude ( _, latitude ) =
    latitude


type alias NamedPosition =
    ( String, Position )


defaultName : String
defaultName =
    ""


defaultNamedPosition : NamedPosition
defaultNamedPosition =
    ( defaultName, defaultPosition )
