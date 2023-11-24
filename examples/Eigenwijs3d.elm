module Eigenwijs3d exposing (main)

import Eigenwijs.Playground3d exposing (..)


main =
    picture
        [ circle lightGreen 20
            |> move 35 -20 0
        , square lightBlue 20
            |> moveX 70
        , triangle orange 20
            |> moveX 90
            |> moveY -30
        , circle yellow 30
            |> pullUp 60
        , rectangle red 30 5
            |> moveX 100
        , rectangle green 5 30
            |> moveY 100
        , rectangle blue 5 30
            |> moveZ 100
            |> roll 90
        , sphere brown 40
            |> moveZ 200
        , cube orange 10
            |> moveZ 50
        , block lightPurple 10 20 30
            |> moveY 50
        , block lightPurple 10 10 30
            |> moveY 150
        , block charcoal 10 20 10
            |> moveY 150
        , group
            [ square green 10
                |> extrude 10
                |> moveX 5
            , square yellow 10
                |> pullUp 30
                |> moveX -5
            ]
            |> moveY 100
        , group
            [ snake
                orange
                [ ( 50, 0, 0 )
                , ( -110, 0, 0 )
                , ( -250, 100, 0 )
                , ( -250, 200, 0 )
                , ( -200, 200, 0 )
                ]
                |> moveY 20
            , circle purple 30
                |> move -50 50 0
            ]
            |> pullUp 90
        ]
