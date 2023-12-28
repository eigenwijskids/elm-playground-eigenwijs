module Words exposing (main)

import Eigenwijs.Playground3d exposing (..)


main =
    picture
        [ words black "Words are rendered to the x-axis"
            |> scale 3
        ]
