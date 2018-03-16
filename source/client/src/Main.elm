module Atlasr.Main exposing (..)

import Atlasr.Geocode as Geocode
import Atlasr.Map as Map
import Atlasr.MapboxGL.Options as MapOptions
import Atlasr.Position exposing (Position, NamedPosition)
import Atlasr.Position as Position
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import Http
import Array exposing (Array)


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

        firstPositionIsUnknown =
            Array.get 0 model.positions
                |> Maybe.map (\( _, position ) -> position == Position.defaultPosition)
                |> Maybe.withDefault False

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
                        , ariaHidden firstPositionIsUnknown
                        , disabled firstPositionIsUnknown
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
    | GeoencodePositionName Int String
    | NewPositionGeocode Int (Result Http.Error Geocode.LongitudeLatitude)
    | Search
    | AddMarker Position
    | RemoveMarkers
    | ConnectMarkers
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

        GeoencodePositionName index positionName ->
            ( model, Geocode.toGeocode (NewPositionGeocode index) positionName )

        NewPositionGeocode index (Ok geocode) ->
            let
                ( defaultLongitude, defaultLatitude ) =
                    Position.defaultPosition

                positionName =
                    geocode.label

                position =
                    ( String.toFloat geocode.longitude |> Result.withDefault defaultLongitude
                    , String.toFloat geocode.latitude |> Result.withDefault defaultLatitude
                    )

                positions =
                    Array.set index ( positionName, position ) model.positions
            in
                update
                    (Chain [ FlyTo position, AddMarker position ])
                    { model | positions = positions }

        NewPositionGeocode _ (Err _) ->
            Debug.crash "nooooo"

        Search ->
            let
                positionsToGeocode =
                    Array.toIndexedList model.positions
                        |> List.filterMap
                            (\( index, ( positionName, position ) ) ->
                                let
                                    ( defaultName, defaultPosition ) =
                                        Position.defaultNamedPosition
                                in
                                    if positionName /= defaultName && position == defaultPosition then
                                        Just ( index, positionName )
                                    else
                                        Nothing
                            )
            in
                update
                    (Chain
                        ([ RemoveMarkers ]
                            ++ List.map
                                (\( index, positionName ) -> GeoencodePositionName index positionName)
                                positionsToGeocode
                            ++ [ ConnectMarkers ]
                        )
                    )
                    model

        AddMarker position ->
            ( model, Map.addMarker position )

        RemoveMarkers ->
            ( model, Map.removeMarkers )

        ConnectMarkers ->
            ( model, Map.connectMarkers )

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
