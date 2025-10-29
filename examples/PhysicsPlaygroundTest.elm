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
                ]
            |> withDynamicShapes
                [ cylinder blue 50 100 |> move 100 100 100 |> withWeight (kilograms 10)
                , cube yellow 50 |> move 60 90 300
                , block red 50 50 100 |> move 100 -100 150
                , sphere green 50 |> move 70 80 400
                ]
    }


update computer memory =
    { memory
        | world = simulate memory.world
    }


view computer memory =
    shapesFromWorld memory.world
