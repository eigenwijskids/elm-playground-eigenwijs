module Eigenwijs.Playground.Audio exposing (..)

import Eigenwijs.Playground exposing (..)
import Json.Encode
import WebAudio
import WebAudio.Property


type alias Port msg =
    Json.Encode.Value -> Cmd msg


gameWithAudio : Port -> (Computer -> memory -> List WebAudio.Node) -> (Computer -> memory -> List (Shape (Msg data))) -> (Computer -> memory -> memory) -> memory -> Program () (Game memory) (Msg data)
gameWithAudio toWebAudio audioForMemory viewMemory updateMemory initialMemory =
    let
        view model =
            { title = "Playground"
            , body = [ gameView viewMemory model ]
            }

        update msg ((Game vis memory computer) as model) =
            ( gameUpdate updateMemory msg model
            , audioForMemory computer model.memory
                |> Json.Encode.list WebAudio.encode
                |> toWebAudio
            )
    in
    Browser.document
        { init = gameInit initialMemory
        , view = view
        , update = update
        , subscriptions = gameSubscriptions
        }


gameAudio : (Computer -> memory -> List WebAudio.Node) -> Game memory -> List WebAudio.Node
gameAudio audioForMemory (Game vis memory computer) =
    audioForMemory computer memory
