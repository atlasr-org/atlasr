module Atlasr.Geocode exposing (LongitudeLatitude, toGeocodes)

import Atlasr.Position exposing (NamedPosition, defaultNamedPosition)
import Http
import Json.Decode
import Task


type alias LongitudeLatitude =
    { label : String
    , longitude : String
    , latitude : String
    }


{-| Allocate a default longitude-latitude.
-}
defaultLongitudeLatitude : LongitudeLatitude
defaultLongitudeLatitude =
    let
        ( defaultName, ( defaultLongitude, defaultLatitude ) ) =
            defaultNamedPosition
    in
        { label = defaultName
        , longitude = toString defaultLongitude
        , latitude = toString defaultLatitude
        }


{-| Geocode a list of position names.
-}
toGeocodes : (Result Http.Error (List (Maybe LongitudeLatitude)) -> msg) -> List NamedPosition -> Cmd msg
toGeocodes outputType positionsToGeocode =
    let
        ( defaultName, defaultPosition ) =
            defaultNamedPosition

        tasks =
            List.map
                (\( positionName, position ) ->
                    if positionName /= defaultName then
                        positionToGeocodeRequest positionName
                            |> Http.toTask
                            |> Task.map (\longitudeLatitude -> Just longitudeLatitude)
                    else
                        Task.succeed Nothing
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
