module Outline exposing (main)

import Eigenwijs.Playground exposing (..)


main =
    picture
        [ group [ circle red 50 |> withOutline orange 5, circle transparent 50 |> withOutline green 10 |> moveRight 50 ]
            |> moveUp 200
        , group [ square red 50 |> withOutline orange 5, square transparent 50 |> withOutline green 3 |> moveRight 50 ]
            |> moveUp 100
        , group [ triangle red 50 |> withOutline orange 5, triangle transparent 50 |> withOutline green 5 |> moveRight 50 ]
        , group [ oval red 80 50 |> withOutline orange 5, oval transparent 80 50 |> withOutline green 10 |> moveRight 50 ]
            |> moveDown 100
        , group [ circle red 50 |> withOutline orange 5, circle transparent 50 |> withOutline green 10 |> moveRight 50 ]
            |> moveDown 200
        , group [ words red "Hello!" |> scale 10 |> withOutline orange 0.5 ]
            |> moveLeft 300
        ]
