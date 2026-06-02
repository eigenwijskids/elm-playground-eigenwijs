module ObjFileTestGame exposing (main)

import Eigenwijs.Playground3d.Experimental exposing (..)


music =
    "https://icecast.omroep.nl/funx-latin-bb-mp3"


polytest =
    "obj/polytest.obj.txt"


a318 =
    "obj/cgtrader_capedavid93_a318.obj.txt"


main =
    configuration
        |> withCamera camera
        |> withObjUrls [ polytest, a318 ]
        |> configuredGame view update init


camera memory =
    eyesAt 500 500 500
        |> lookAt 0 0 0


view { time } memory =
    [ group
        [ objFile white a318
            |> scale 0.001
            -- it's a plane, it's big :D
            |> roll 90
            |> move memory.x memory.y 0
            |> yaw (90 + memory.richting)
        ]
    , if spin 1 time > 180 then
        objFile red polytest
            |> scale 0.5
            |> moveZ 100

      else
        cube green 100
            |> moveZ 50
    , square darkGrey 500
    , if memory.music then
        group [ sound music, cube red 50 ]

      else
        cube green 50
    ]


update computer model =
    let
        snelheid =
            toY computer.keyboard

        draai =
            toX computer.keyboard

        dx =
            snelheid
                * cos (degrees model.richting)

        dy =
            snelheid
                * sin (degrees model.richting)
    in
    { model
        | x = model.x + dx
        , y = model.y + dy
        , richting = model.richting - draai
        , music =
            if computer.keyboard.space then
                True

            else if computer.keyboard.enter then
                False

            else
                model.music
    }


init =
    { x = 0
    , y = 0
    , z = 0
    , richting = 0
    , music = False
    }
