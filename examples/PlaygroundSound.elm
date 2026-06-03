module PlaygroundSound exposing (main)

import Eigenwijs.Playground exposing (..)


main =
    picture
        [ circle yellow 50
        , sound "https://icecast.omroep.nl/funx-latin-bb-mp3"
        ]
