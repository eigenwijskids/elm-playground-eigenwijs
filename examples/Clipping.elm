module Clipping exposing (main)

import Eigenwijs.Playground.Experimental exposing (..)


main =
    picture
        [ group
            [ square red 50
            , triangle yellow 30
            , words black "Hoohaa" |> scale 2 |> withFont "sans"
            ]
            |> only [ square white 50 ]
            |> rotate 20
            |> scale 5
        ]
