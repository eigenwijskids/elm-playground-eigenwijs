module PlaygroundInScene3d exposing (main)

import Angle exposing (Angle)
import Browser
import Browser.Dom
import Browser.Events
import Camera3d exposing (Camera3d)
import Color exposing (..)
import Direction3d exposing (Direction3d)
import Eigenwijs.Playground3d
import Length exposing (Meters, centimeters, meters)
import Pixels exposing (Pixels, pixels)
import Point3d exposing (Point3d)
import Quantity exposing (Quantity)
import Scene3d exposing (Entity, group)
import Scene3d.Material as Material exposing (Material)
import SketchPlane3d
import Task
import Viewpoint3d exposing (Viewpoint3d)


type alias Model =
    { width : Quantity Float Pixels
    , height : Quantity Float Pixels
    }


type Msg
    = Resize (Quantity Float Pixels) (Quantity Float Pixels)


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { width = pixels 0
      , height = pixels 0
      }
    , Cmd.batch
        [ Task.perform
            (\{ viewport } -> Resize (pixels viewport.width) (pixels viewport.height))
            Browser.Dom.getViewport
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onResize
        (\width height ->
            Resize (pixels (toFloat width)) (pixels (toFloat height))
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize width height ->
            ( { model | width = width, height = height }, Cmd.none )


view { width, height } =
    Scene3d.sunny
        { camera =
            orthographic
        , clipDepth = Length.centimeters 0.5
        , dimensions =
            ( Pixels.int (round (Pixels.toFloat width))
            , Pixels.int (round (Pixels.toFloat height))
            )
        , background = Scene3d.backgroundColor (rgb 0.95 0.95 1.0)
        , entities =
            [ Eigenwijs.Playground3d.square blue 20
                |> Eigenwijs.Playground3d.entity
            ]
        , shadows = False
        , upDirection = Direction3d.z
        , sunlightDirection = Direction3d.yz (Angle.degrees -120)
        }


orthographic =
    Camera3d.orthographic
        { viewpoint = Viewpoint3d.isometric { focalPoint = Point3d.origin, distance = Length.meters 10 }
        , viewportHeight = Length.meters 5
        }
