module Atlasr.Position exposing (..)


type alias Longitude =
    Float


type alias Latitude =
    Float


type alias Position =
    ( Longitude, Latitude )


{-| Allocate a default position.
-}
defaultPosition : Position
defaultPosition =
    ( 0.0, 0.0 )


{-| Extract the longitude of a position.
-}
extractLongitude : Position -> Float
extractLongitude ( longitude, _ ) =
    longitude


{-| Extract the latitude of a position.
-}
extractLatitude : Position -> Float
extractLatitude ( _, latitude ) =
    latitude


type alias NamedPosition =
    ( String, Position )


{-| Allocate a default position name.
-}
defaultName : String
defaultName =
    ""


{-| Allocate a default named position.
-}
defaultNamedPosition : NamedPosition
defaultNamedPosition =
    ( defaultName, defaultPosition )
