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
        ( positionName, _ ) =
            Array.get 0 model.positions |> Maybe.withDefault Position.defaultNamedPosition

        expandedNav =
            if String.isEmpty positionName then
                "false"
            else
                "true"
    in
        main_ []
            [ nav
                [ ariaExpanded expandedNav ]
                [ Html.form [ role "search", onSubmit (Search 0) ]
                    [ input
                        [ type_ "search"
                        , onInput (NewPositionName 0)
                        , ariaLabel "Browse the world"
                        , ariaRequired True
                        , placeholder "Browse the world"
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
    | NewPositionGeocode Int (Result Http.Error Geocode.LongitudeLatitude)
    | Search Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewPositionName index positionName ->
            let
                positions =
                    Array.set index ( positionName, Position.defaultPosition ) model.positions
            in
                ( { model | positions = positions }, Cmd.none )

        NewPositionGeocode index (Ok geocode) ->
            let
                positionName =
                    Array.get index model.positions
                        |> Maybe.map (\( positionName, _ ) -> positionName)
                        |> Maybe.withDefault Position.defaultName

                ( defaultLongitude, defaultLatitude ) =
                    Position.defaultPosition

                position =
                    ( String.toFloat geocode.longitude |> Result.withDefault defaultLongitude
                    , String.toFloat geocode.latitude |> Result.withDefault defaultLatitude
                    )

                positions =
                    Array.set index ( positionName, position ) model.positions
            in
                ( { model | positions = positions }
                , Cmd.batch [ Map.flyTo position, Map.addMarker position ]
                )

        NewPositionGeocode _ (Err _) ->
            Debug.crash "nooooo"

        Search index ->
            ( model
            , Array.get index model.positions
                |> Maybe.map (\( positionName, _ ) -> Geocode.toGeocode (NewPositionGeocode index) positionName)
                |> Maybe.withDefault Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
