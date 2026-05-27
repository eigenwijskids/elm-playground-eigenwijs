module ObjFileTestAnimation exposing (main)

import Eigenwijs.Playground3d.Experimental exposing (..)


polytest =
    "obj/polytest.obj.txt"


a318 =
    "obj/cgtrader_capedavid93_a318.obj.txt"


main =
    configuration
        |> withObjUrls [ polytest, a318 ]
        |> configuredAnimation view


view time =
    [ group
        [ objFile white a318
            |> scale 0.001
            -- it's a plane, it's big :D
            |> roll 90
            |> moveX 200
        ]
        |> yaw (spin -30 time)
    , if spin 1 time > 180 then
        objFile red polytest
            |> scale 0.5
            |> moveZ 100

      else
        cube green 100
            |> moveZ 50
    , square darkGrey 500
    ]
