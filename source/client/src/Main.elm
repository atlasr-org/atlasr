module Atlasr.Main exposing (..)

import Atlasr.Geocode as Geocode
import Atlasr.Map as Map
import Atlasr.MapboxGL.Options as MapOptions
import Atlasr.Position as Position
import Atlasr.Position exposing (Position, NamedPosition)
import Array exposing (Array)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import Http
import Process
import Task as CoreTask


main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { positions : Array NamedPosition }


init : ( Model, Cmd Msg )
init =
    ( { positions = Array.repeat 2 Position.defaultNamedPosition }
    , Map.create "map" MapOptions.default
    )


view : Model -> Html Msg
view model =
    let
        hasAtLeastOnePositionName =
            Array.toList model.positions
                |> List.any (\( positionName, _ ) -> not (String.isEmpty positionName))

        expandedNav =
            if hasAtLeastOnePositionName then
                "true"
            else
                "false"
    in
        main_ []
            [ nav
                [ ariaExpanded expandedNav ]
                [ Html.form [ role "search", onSubmit Search ]
                    [ input
                        [ type_ "text"
                        , onInput (NewPositionName 0)
                        , ariaLabel "Browse the world"
                        , ariaRequired True
                        , placeholder "Browse the world"
                        , value
                            (Array.get 0 model.positions
                                |> Maybe.map (\( positionName, _ ) -> positionName)
                                |> Maybe.withDefault Position.defaultName
                            )
                        ]
                        []
                    , input
                        [ type_ "text"
                        , onInput (NewPositionName 1)
                        , ariaLabel "Search for a direction"
                        , ariaRequired False
                        , placeholder "Search for a direction"
                        , value
                            (Array.get 1 model.positions
                                |> Maybe.map (\( positionName, _ ) -> positionName)
                                |> Maybe.withDefault Position.defaultName
                            )
                        ]
                        []
                    , input
                        [ type_ "submit"
                        , value "Search"
                        ]
                        []
                    ]
                , section [] []
                ]
            , article [ id "map" ] []
            , footer [] [ text "Atlasr" ]
            ]


type Msg
    = NewPositionName Int String
    | GeoencodePositionNames (List ( Int, String ))
    | NewPositionGeocodes (Result Http.Error (List ( Int, Geocode.LongitudeLatitude )))
    | Search
    | AddAndConnectMarkers (List Position)
    | RemoveMarkers
    | FlyTo Position
    | Chain (List Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewPositionName index positionName ->
            let
                positions =
                    Array.set index ( positionName, Position.defaultPosition ) model.positions
            in
                ( { model | positions = positions }, Cmd.none )

        GeoencodePositionNames positionsToGeocode ->
            ( model, Geocode.toGeocodes NewPositionGeocodes positionsToGeocode )

        NewPositionGeocodes (Ok geocodes) ->
            let
                ( defaultLongitude, defaultLatitude ) =
                    Position.defaultPosition

                namedPositions =
                    List.map
                        (\( index, geocode ) ->
                            let
                                positionName =
                                    geocode.label

                                position =
                                    ( String.toFloat geocode.longitude |> Result.withDefault defaultLongitude
                                    , String.toFloat geocode.latitude |> Result.withDefault defaultLatitude
                                    )
                            in
                                ( positionName, position )
                        )
                        geocodes

                positions =
                    List.map (\( _, position ) -> position) namedPositions
            in
                update
                    (AddAndConnectMarkers positions)
                    { model | positions = namedPositions |> Array.fromList }

        NewPositionGeocodes (Err _) ->
            Debug.crash "hooo"

        Search ->
            let
                positionsToGeocode =
                    Array.toIndexedList model.positions
                        |> List.filterMap (\( index, ( positionName, position ) ) -> Just ( index, positionName ))
            in
                update
                    (Chain [ RemoveMarkers, GeoencodePositionNames positionsToGeocode ])
                    model

        AddAndConnectMarkers positions ->
            ( model, Map.addAndConnectMarkers positions )

        RemoveMarkers ->
            ( model, Map.removeMarkers )

        FlyTo position ->
            ( model, Map.flyTo position )

        Chain messages ->
            let
                chain message ( model1, commands ) =
                    let
                        ( nextModel, nextCommands ) =
                            update message model
                    in
                        nextModel ! [ commands, nextCommands ]
            in
                List.foldl chain (model ! []) messages


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
