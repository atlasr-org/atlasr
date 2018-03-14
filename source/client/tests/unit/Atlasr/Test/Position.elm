module Atlasr.Test.Position exposing (..)

import Atlasr.Position as Position
import Test exposing (..)
import Expect


position : Test
position =
    describe "Test suite for the `Position` module."
        [ test "Default position" <|
            \() ->
                Expect.equal ( 0.0, 0.0 ) Position.defaultPosition
        , test "Extract longitude" <|
            \() ->
                Expect.equal 1.2 (Position.extractLongitude ( 1.2, 3.4 ))
        , test "Extract latitude" <|
            \() ->
                Expect.equal 3.4 (Position.extractLatitude ( 1.2, 3.4 ))
        , test "Default name" <|
            \() ->
                Expect.equal "" Position.defaultName
        , test "Default named position" <|
            \() ->
                Expect.equal ( "", ( 0.0, 0.0 ) ) Position.defaultNamedPosition
        ]
