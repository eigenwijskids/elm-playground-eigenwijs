module Keyboard exposing (main)

import Eigenwijs.Playground exposing (..)
import Set


main =
    game view update 0


update computer memory =
    if Set.member "Enter" computer.keyboard.keysReleased then
        memory + 1

    else
        memory


view computer memory =
    [ words black "Press ENTER to increase the counter"
        |> scale 2
    , memory
        |> String.fromInt
        |> words black
        |> scale 3
        |> moveDown 50
    , if computer.keyboard.enter then
        words red "Release ENTER to increase the counter"
            |> scale 2
            |> moveDown 100

      else
        group []
    ]
