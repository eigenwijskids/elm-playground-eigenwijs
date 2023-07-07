module Html exposing (init, main)

import Browser
import Eigenwijs.Playground exposing (..)
import Html
import Html.Attributes as Html


type alias Model =
    { picture : Picture
    , animation : Animation
    , game : Game {}
    }


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init () =
    let
        ( pictureState, pictureCmd ) =
            pictureInit ()

        ( animationState, animationCmd ) =
            animationInit ()

        ( gameState, gameCmd ) =
            gameInit {} ()
    in
    ( { time = beginOfTime
      , picture = pictureState
      , animation = animationState
      , game = gameState
      , subscriptions = subscriptions
      }
    , Cmd.batch
        [ Cmd.map PictureMsg pictureCmd
        , Cmd.map AnimationMsg animationCmd
        , Cmd.map GameMsg gameCmd
        ]
    )


picture =
    [ circle red 30 ]


animation time =
    [ circle red (wave 10 50 5 time) ]


gameScene computer memory =
    [ triangle green 100
        |> move computer.mouse.x computer.mouse.y
    ]


game computer memory =
    memory


view model =
    { title = "Playground shapes in html"
    , body =
        [ Html.div []
            [ Html.h1 []
                [ Html.text "Embedding Playground elements in HTML"
                ]
            , Html.dl []
                [ Html.dt [] [ Html.text "Picture" ]
                , Html.dd
                    [ Html.style "position" "relative"
                    , Html.style "width" "100px"
                    , Html.style "height" "100px"
                    ]
                    [ pictureView model.picture picture
                    ]
                , Html.dt [] [ Html.text "Animation" ]
                , Html.dd
                    [ Html.style "position" "relative"
                    , Html.style "width" "100px"
                    , Html.style "height" "100px"
                    ]
                    [ animationView model.animation animation
                    ]
                , Html.dt [] [ Html.text "Game" ]
                , Html.dd
                    [ Html.style "position" "relative"
                    , Html.style "width" "100px"
                    , Html.style "height" "100px"
                    ]
                    [ gameView gameScene model.game
                    ]
                ]
            ]
        ]
    }


type Msg
    = PictureMsg PictureMsg
    | AnimationMsg AnimationMsg
    | GameMsg GameMsg


update msg model =
    case msg of
        PictureMsg m ->
            let
                ( pictureState, pictureCmd ) =
                    pictureUpdate m picture
            in
            ( { model
                | picture = pictureState
              }
            , pictureCmd
            )

        AnimationMsg m ->
            ( { model
                | animation = animationUpdate m model.animation
              }
            , Cmd.none
            )

        GameMsg m ->
            ( { model
                | game = gameUpdate game m model.game
              }
            , Cmd.none
            )


subscriptions model =
    Sub.batch
        [ Sub.map PictureMsg (pictureSubscriptions model.picture)
        , Sub.map AnimationMsg animationSubscriptions
        , Sub.map GameMsg (gameSubscriptions model.game)
        ]
