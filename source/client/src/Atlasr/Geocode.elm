module Atlasr.Geocode exposing (LongitudeLatitude, toGeocode)

import Http
import Json.Decode


type alias LongitudeLatitude =
    { label : String
    , longitude : String
    , latitude : String
    }


{-| Geocode a position name (using an HTTP service).
-}
toGeocode : (Result Http.Error LongitudeLatitude -> msg) -> String -> Cmd msg
toGeocode outputType positionName =
    let
        url =
            "https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" ++ positionName

        request =
            Http.get url decodeGeocode
    in
        Http.send outputType request


{-| Decoder for the geocode payload from the HTTP service.
-}
decodeGeocode : Json.Decode.Decoder LongitudeLatitude
decodeGeocode =
    Json.Decode.at [ "0" ]
        (Json.Decode.map3
            LongitudeLatitude
            (Json.Decode.field "display_name" Json.Decode.string)
            (Json.Decode.field "lon" Json.Decode.string)
            (Json.Decode.field "lat" Json.Decode.string)
        )
