port module Audio exposing (main)

import Eigenwijs.Playground exposing (..)
import Set
import WebAudio
import WebAudio.Property


port audioPort : Eigenwijs.Playground.AudioPort msg


main =
    gameWithAudio audioPort audio view update init


init =
    {}


update computer memory =
    memory


view computer memory =
    [ words black "Some letter keys have frequencies assigned, and trigger an oscillator when pressed" |> scale 2
    , words orange "TODO: The AudioContext must be created or resumed after a user gesture on the page, otherwise it won't run." |> moveDown 50
    , words black "Build: elm make --output audio.js Audio.elm" |> moveDown 80
    , words black "Serve suggestion: python -m SimpleHTTPServer 8012" |> moveDown 100
    , words black "Navigate to: http://localhost:8012/Audio.html" |> moveDown 120
    ]


audio computer memory =
    case computer.keyboard.keys |> Set.toList |> List.head of
        Nothing ->
            []

        Just key ->
            let
                frequency =
                    frequencyFor (Debug.log "key" key)
            in
            [ WebAudio.oscillator
                [ WebAudio.Property.frequency frequency
                , WebAudio.Property.type_ "sawtooth"
                ]
                [ WebAudio.audioDestination ]
            , WebAudio.oscillator
                [ WebAudio.Property.frequency frequency
                , WebAudio.Property.detune 10
                , WebAudio.Property.type_ "sawtooth"
                ]
                [ WebAudio.audioDestination ]
            , WebAudio.oscillator
                [ WebAudio.Property.frequency frequency
                , WebAudio.Property.detune -20
                , WebAudio.Property.type_ "sawtooth"
                ]
                [ WebAudio.audioDestination ]
            ]


frequencyFor key =
    case key of
        "e" ->
            330

        "r" ->
            370

        "t" ->
            420

        "y" ->
            440

        "u" ->
            550

        "i" ->
            590

        "o" ->
            660

        "p" ->
            740

        "n" ->
            220

        _ ->
            0
