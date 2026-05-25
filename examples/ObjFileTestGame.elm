module ObjFileTestGame exposing (main)

import Eigenwijs.Playground3d.WithObjFiles exposing (..)


main =
    gameConfig
        |> withCamera camera
        |> withObjUrls objUrls
        |> configuredGame view update init


camera memory =
    eyesAt 100 100 100
        |> lookAt 0 0 0


view computer memory =
    [ objFile red "obj/cgtrader_capedavid93_a318.obj.txt" ]


update computer memory =
    memory


init =
    {}



-- obj/polytest.obj.txt
-- obj/cgtrader_capedavid93_a318.obj.txt
