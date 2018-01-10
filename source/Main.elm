module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type alias Model =
    Int


model : Model
model =
    0



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model -> Html Msg
view model =
    main_ []
        [ article [] []
        , nav []
            [ button [ onClick Decrement ] [ text "-" ]
            , div [] [ text (toString model) ]
            , button [ onClick Increment ] [ text "+" ]
            ]
        ]
