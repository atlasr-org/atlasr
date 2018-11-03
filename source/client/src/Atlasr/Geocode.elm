module Atlasr.Geocode exposing (Geocode, toGeocodes)

import Atlasr.Position exposing (NamedPosition, defaultNamedPosition)
import Http
import Json.Decode
import Task


type alias Geocode =
    { label : String
    , longitude : String
    , latitude : String
    }


{-| Geocode a list of position names.
-}
toGeocodes : (Result Http.Error (List (Maybe Geocode)) -> msg) -> List NamedPosition -> Cmd msg
toGeocodes outputType positionsToGeocode =
    let
        ( defaultName, defaultPosition ) =
            defaultNamedPosition

        tasks =
            List.map
                (\( positionName, position ) ->
                    if positionName /= defaultName then
                        if position == defaultPosition then
                            positionToGeocodeRequest positionName
                                |> Http.toTask
                                |> Task.map (\geocode -> Just geocode)

                        else
                            let
                                ( longitude, latitude ) =
                                    position

                                geocode =
                                    { label = positionName
                                    , longitude = String.fromFloat longitude
                                    , latitude = String.fromFloat latitude
                                    }
                            in
                            Task.succeed (Just geocode)

                    else
                        Task.succeed Nothing
                )
                positionsToGeocode
    in
    Task.attempt outputType <| Task.sequence tasks


{-| Create an HTTP request to geocode a position.
-}
positionToGeocodeRequest : String -> Http.Request Geocode
positionToGeocodeRequest positionName =
    let
        url =
            "/api/geocode?term=" ++ positionName ++ "&limit=1"
    in
    Http.get url decodeGeocode


{-| Decoder for the geocode payload from the HTTP service.
-}
decodeGeocode : Json.Decode.Decoder Geocode
decodeGeocode =
    Json.Decode.at [ "0" ]
        (Json.Decode.map3
            Geocode
            (Json.Decode.at [ "display_name", "0" ] Json.Decode.string)
            (Json.Decode.at [ "longitude", "0" ] Json.Decode.string)
            (Json.Decode.at [ "latitude", "0" ] Json.Decode.string)
        )
