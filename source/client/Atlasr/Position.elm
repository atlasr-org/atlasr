module Atlasr.Position exposing (..)


type alias LongitudeLatitude =
    ( Float, Float )


extractLongitude : LongitudeLatitude -> Float
extractLongitude ( longitude, _ ) =
    longitude


extractLatitude : LongitudeLatitude -> Float
extractLatitude ( _, latitude ) =
    latitude
