module BouncyGround exposing (main)

import Eigenwijs.Playground exposing (..)


main =
    game view update init


init =
    { x = 0
    , y = 0
    , vx = 0
    , vy = 0
    , gewrichten =
        { heup = 0
        , schouder = 0
        , nek = 0
        }
    }


view { screen } { x, y, gewrichten } =
    [ grond screen
    , stokker gewrichten
        |> move x y
    ]


update { screen, keyboard, time } { x, y, vx, vy, gewrichten } =
    let
        nx =
            x + vx

        ny =
            y + vy

        ( ( nnx, nny ), ( nvx, nvy ) ) =
            if
                stokker gewrichten
                    -- Jaa eig. die
                    |> move nx ny
                    |> collidesWith (grond screen)
            then
                ( ( nx, ny )
                , ( vx / 2
                  , -0.8
                        * vy
                        + (if keyboard.space then
                            3

                           else
                            0
                          )
                  )
                )

            else
                ( ( nx, ny ), ( vx, vy - 0.02 ) )
    in
    { x = nnx
    , y = nny
    , vx = nvx
    , vy = nvy
    , gewrichten =
        { heup = wave 20 160 8 time
        , schouder = wave 40 150 7 time
        , nek = wave -10 10 3 time
        }
    }


grond screen =
    group
        [ rectangle brown screen.width (0.2 * screen.height)
            |> move 0 screen.bottom
        ]


stokker { heup, schouder, nek } =
    circle red 15
        |> stok 20
        |> rotate nek
        |> combinatie
            [ stok 70 eind
                |> rotate schouder
            , stok 70 eind
                |> rotate -schouder
            ]
        |> stok 50
        |> combinatie
            [ stok 80 eind
                |> rotate heup
            , stok 80 eind
                |> rotate -heup
            ]


eind =
    group []


stok lengte verbinding =
    group
        [ rectangle red 10 lengte
            |> moveUp (lengte / 2)
        , circle red 5
            |> moveUp lengte
        , verbinding
            |> moveUp lengte
        ]


combinatie dingen verbinding =
    group (verbinding :: dingen)
