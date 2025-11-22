module PhysicsPlaygroundTest exposing (main)

import Eigenwijs.Playground3d exposing (..)


main =
    game view update init


init =
    { world =
        emptyWorld
            |> withGravity 9.81
            |> withShapes
                [ square black 500
                , block red 300 5 5 |> move 150 0 0
                , block green 5 300 5 |> move 0 150 0
                , block blue 5 5 300 |> move 0 0 150
                ]
            |> withDynamicShapes
                [ group
                    [ cylinder blue 50 100 |> move 100 100 100 |> withWeight (kilograms 10)
                    , cube yellow 50 |> move 60 90 200 |> roll -30
                    ]
                    |> pitch 10
                , cube purple 50 |> move 60 90 300
                , prism red 50 100
                    |> move 100 -100 150
                    |> pitch 90
                , sphere green 50 |> move 100 80 400
                ]
    }


update computer memory =
    { memory
        | world = simulate memory.world
    }


view computer memory =
    [ shapesFromWorld memory.world
        |> group

    --        |> pitch (spin 5 computer.time)
    ]
