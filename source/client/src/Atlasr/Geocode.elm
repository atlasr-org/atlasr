module Atlasr.Geocode exposing (LongitudeLatitude, toGeocodes)

import Http
import Json.Decode
import Task


type alias LongitudeLatitude =
    { label : String
    , longitude : String
    , latitude : String
    }


{-| Geocode a list of position names.
-}
toGeocodes : (Result Http.Error (List ( Int, LongitudeLatitude )) -> msg) -> List ( Int, String ) -> Cmd msg
toGeocodes outputType positionsToGeocode =
    let
        tasks =
            List.map
                (\( index, positionName ) ->
                    positionToGeocodeRequest positionName
                        |> Http.toTask
                        |> Task.map (\longitudeLatitude -> ( index, longitudeLatitude ))
                )
                positionsToGeocode
    in
        Task.attempt outputType <| Task.sequence tasks


{-| Create an HTTP request to geocode a position.
-}
positionToGeocodeRequest : String -> Http.Request LongitudeLatitude
positionToGeocodeRequest positionName =
    let
        url =
            "https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" ++ positionName
    in
        Http.get url decodeGeocode


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
