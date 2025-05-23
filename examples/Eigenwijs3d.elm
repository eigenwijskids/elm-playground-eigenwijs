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
        , cone green 20 80
            |> move -100 100 0
        , obj purple
            [ ( 1, 1, -1 )
            , ( 1, -1, -1 )
            , ( -1, -1, -1 )
            , ( -1, 1, -1 )
            , ( 0, 0, 1 )
            ]
            [ ( 1, 2, 3 )
            , ( 3, 4, 1 )
            , ( 1, 4, 5 )
            , ( 5, 4, 3 )
            , ( 3, 2, 5 )
            , ( 5, 2, 1 )
            ]
            |> scale 50
            |> move -100 200 0
        , polygon yellow [ ( -65, 68 ), ( -66, 94 ), ( -97, 127 ), ( -236, 185 ), ( -266, 169 ), ( -329, 170 ), ( -351, 195 ), ( -374, 233 ), ( -398, 223 ), ( -403, 192 ), ( -393, 120 ), ( -392, 84 ) ]
            |> scale 0.5
            |> move 300 200 50
            |> pullUp 50
        ]
