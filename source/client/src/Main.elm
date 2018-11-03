module Atlasr.Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Array exposing (Array)
import Atlasr.Geocode as Geocode
import Atlasr.Map as Map
import Atlasr.MapboxGL.Options as MapOptions
import Atlasr.Position as Position exposing (NamedPosition, Position)
import Atlasr.Route as Route
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import Http
import Process
import Task as CoreTask


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { positions : Array NamedPosition }


init : Int -> ( Model, Cmd Msg )
init x =
    ( { positions = Array.repeat 2 Position.defaultNamedPosition }
    , Map.create "map" MapOptions.default
    )


view : Model -> Browser.Document Msg
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
    { title = "Atlasr"
    , body =
        [ main_ []
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
        ]
    }


type Msg
    = NewPositionName Int String
    | GeoencodePositionNames (List NamedPosition)
    | NewPositionGeocodes (Result Http.Error (List (Maybe Geocode.Geocode)))
    | GetRoute (List Position)
    | NewPositionRoute (Result Http.Error Route.Route)
    | Search
    | AddMarkers (List Position)
    | RemoveMarkers
    | ConnectMarkers (List Position)
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
                        (\geocode_item ->
                            Maybe.map
                                (\geocode ->
                                    let
                                        positionName =
                                            geocode.label

                                        position =
                                            ( Maybe.withDefault defaultLongitude (String.toFloat geocode.longitude)
                                            , Maybe.withDefault defaultLatitude (String.toFloat geocode.latitude)
                                            )
                                    in
                                    ( positionName, position )
                                )
                                geocode_item
                        )
                        geocodes

                positions =
                    List.filterMap
                        (\namedPosition ->
                            Maybe.map
                                (\( positionName, position ) -> Just position)
                                namedPosition
                                |> Maybe.withDefault Nothing
                        )
                        namedPositions
            in
            update
                (Chain [ AddMarkers positions, GetRoute positions ])
                { model
                    | positions =
                        List.map
                            (\namedPosition ->
                                Maybe.withDefault Position.defaultNamedPosition namedPosition
                            )
                            namedPositions
                            |> Array.fromList
                }

        NewPositionGeocodes (Err _) ->
            ( model, Cmd.batch [] )

        GetRoute positions ->
            ( model, Route.toRoute NewPositionRoute positions )

        NewPositionRoute (Ok route) ->
            update
                (ConnectMarkers route.points)
                model

        NewPositionRoute (Err _) ->
            ( model, Cmd.batch [] )

        Search ->
            update
                (Chain [ RemoveMarkers, Array.toList model.positions |> GeoencodePositionNames ])
                model

        AddMarkers positions ->
            ( model, Map.addMarkers positions )

        RemoveMarkers ->
            ( model, Map.removeMarkers )

        ConnectMarkers positions ->
            ( model, Map.connectMarkers positions )

        FlyTo position ->
            ( model, Map.flyTo position )

        Chain messages ->
            let
                chain message ( model1, commands ) =
                    let
                        ( nextModel, nextCommands ) =
                            update message model
                    in
                    ( nextModel, Cmd.batch [ commands, nextCommands ] )
            in
            List.foldl chain ( model, Cmd.batch [] ) messages


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
