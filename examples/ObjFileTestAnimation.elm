module ObjFileTestAnimation exposing (main)

import Eigenwijs.Playground3d.WithObjFiles exposing (..)


main =
    animation view



-- animationWithObjUrls objUrls view
-- objUrls = ["obj/cgtrader_capedavid93_a318.obj.txt"]


view time =
    [ group
        [ objFile white "obj/cgtrader_capedavid93_a318.obj.txt"
            |> scale 0.001
            -- it's a plane, it's big :D
            |> roll 90
            |> moveX 200
        ]
        |> yaw (spin -30 time)
    , square darkGrey 500
    ]



-- obj/polytest.obj.txt
-- obj/cgtrader_capedavid93_a318.obj.txt
