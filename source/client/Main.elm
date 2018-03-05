module Atlasr.Main exposing (..)

import Atlasr.Geocode as Geocode
import Atlasr.Map as Map
import Atlasr.MapboxGL.Options as MapOptions
import Atlasr.Position exposing (LongitudeLatitude)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import Http


main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { positionName : String
    , positionGeocode : LongitudeLatitude
    }


init : ( Model, Cmd Msg )
init =
    ( { positionName = ""
      , positionGeocode = ( 0.0, 0.0 )
      }
    , Map.create "map" MapOptions.default
    )


view : Model -> Html Msg
view model =
    let
        expandedNav =
            if String.isEmpty model.positionName then
                "false"
            else
                "true"
    in
        main_ []
            [ nav
                [ ariaExpanded expandedNav ]
                [ Html.form [ role "search", onSubmit Search ]
                    [ input
                        [ type_ "search"
                        , onInput NewPositionName
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
    = NewPositionName String
    | NewPositionGeocode (Result Http.Error Geocode.LongitudeLatitude)
    | Search


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewPositionName positionName ->
            ( { model | positionName = positionName }, Cmd.none )

        NewPositionGeocode (Ok geocode) ->
            let
                positionGeocode =
                    ( Result.withDefault 0.0 (String.toFloat geocode.longitude)
                    , Result.withDefault 0.0 (String.toFloat geocode.latitude)
                    )
            in
                ( { model | positionGeocode = positionGeocode }
                , Map.flyTo positionGeocode
                )

        NewPositionGeocode (Err _) ->
            Debug.crash "nooooo"

        Search ->
            ( model, Geocode.toGeocode NewPositionGeocode model.positionName )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
