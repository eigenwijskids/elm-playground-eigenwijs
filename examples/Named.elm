module Named exposing (main)
import Eigenwijs.Playground exposing (..)

main = picture [ words black nameTest ]

nameTest =
    let
        namedSquare = square red 50 |> withName "The Square"
    in
    case nameOf namedSquare of
        Nothing -> "unnamed shape"
        Just name -> "a shape named " ++ name
