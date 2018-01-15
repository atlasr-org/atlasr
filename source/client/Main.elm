module Atlasr.Main exposing (..)

import Atlasr.Map as Map
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)


main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { search : String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "", Map.create "map" )


view : Model -> Html Msg
view model =
    let
        expandedNav =
            if String.isEmpty model.search then
                "false"
            else
                "true"
    in
        main_ []
            [ article [ id "map" ] []
            , nav
                [ ariaExpanded expandedNav ]
                [ input [ type_ "search", onInput Search ] []
                ]
            , footer [] [ text "Atlasr" ]
            ]


type Msg
    = Search String
    | CreateMap String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        CreateMap elementId ->
            ( model, Map.create elementId )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
