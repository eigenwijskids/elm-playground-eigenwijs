module Eigenwijs.Playground3d exposing
    ( picture, animation, game
    , Shape, circle, square, rectangle, triangle, polygon, snake
    , sphere, cylinder, cone, cube, block, obj, prerendered
    , words
    , move, moveX, moveY, moveZ
    , scale, rotate, roll, pitch, yaw, fade
    , group, extrude, pullUp
    , Time, spin, wave, zigzag, beginOfTime, secondsBetween
    , Computer, Mouse, Screen, Keyboard, toX, toY, toXY
    , rgb, rgb255, red, orange, yellow, green, blue, purple, brown
    , lightRed, lightOrange, lightYellow, lightGreen, lightBlue, lightPurple, lightBrown
    , darkRed, darkOrange, darkYellow, darkGreen, darkBlue, darkPurple, darkBrown
    , white, lightGrey, grey, darkGrey, lightCharcoal, charcoal, darkCharcoal, black
    , lightGray, gray, darkGray
    , Number
    , entity
    , pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture
    , animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg
    , gameWithCamera, gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg
    , networkGame, networkGameWithCamera, Connection
    , isometric, eyesAt, lookAt
    , center, extent, extents
    )

{-| **Beware that this is a project under heavy construction** - We are trying to
incrementally work towards a library enabling folks familiar with the 2D
Playground, to add 3D elements to a 3D scene, and in this way enabling them to
contribute to a collaboratively developed game.


# Compatibility with the original Playground library

This library exports the same functions and types except for (for the time being):

  - oval, pentagon, hexagon, octagon (just some grunt work)
  - image
  - Color (Color is imported from the package avh4/elm-color)

The following primitives work in a (slightly) different way:

  - words (are rendered using a pixel font - actually Mogee from the kuzminadya/mogeefont package)
  - move (takes an additional z-coordinate)
  - Shape (also adds a z-coordinate, and has roll, pitch, yaw instead of only a single angle)


# Playgrounds

@docs picture, animation, game


# Shapes

@docs Shape, circle, square, rectangle, triangle, polygon, snake


# 3D Shapes

@docs sphere, cylinder, cone, cube, block, obj, prerendered


# Words

@docs words


# Move Shapes

@docs move, moveX, moveY, moveZ


# Customize Shapes

@docs scale, rotate, roll, pitch, yaw, fade


# Groups and extrusion

@docs group, extrude, pullUp


# Time

@docs Time, spin, wave, zigzag, beginOfTime, secondsBetween


# Computer

@docs Computer, Mouse, Screen, Keyboard, toX, toY, toXY


# Colors

@docs rgb, rgb255, red, orange, yellow, green, blue, purple, brown


### Light Colors

@docs lightRed, lightOrange, lightYellow, lightGreen, lightBlue, lightPurple, lightBrown


### Dark Colors

@docs darkRed, darkOrange, darkYellow, darkGreen, darkBlue, darkPurple, darkBrown


### Shades of Grey

@docs white, lightGrey, grey, darkGrey, lightCharcoal, charcoal, darkCharcoal, black


### Alternate Spellings of Gray

@docs lightGray, gray, darkGray


### Numbers

@docs Number


# Playground Scene3d embeds

@docs entity


# Playground Picture embeds

@docs pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture


# Playground Animation embeds

@docs animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg


# Playground Game embeds

@docs gameWithCamera, gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg
@docs networkGame, networkGameWithCamera, Connection


# Playground Cameras

@docs isometric, eyesAt, lookAt


# Calculations

@docs center, extent, extents

-}

import Angle exposing (Angle)
import Array
import Axis3d exposing (Axis3d)
import Block3d
import Browser
import Browser.Dom as Dom
import Browser.Events as E
import Camera3d exposing (Camera3d)
import Color exposing (..)
import Cone3d
import Cylinder3d
import DelaunayTriangulation2d
import Direction3d exposing (Direction3d)
import Eigenwijs.Playground3d.Shape as Shape
import Html
import Html.Attributes as H
import Html.Events.Extra.Touch as Touch
import Html.Lazy exposing (lazy)
import Http
import Json.Decode as D
import Json.Encode as E
import Length exposing (Length, Meters, centimeters, meters)
import MogeeFont
import Physics.Body as Body exposing (Body)
import Physics.Coordinates exposing (BodyCoordinates, WorldCoordinates)
import Physics.World as World exposing (World)
import Pixels exposing (Pixels, pixels)
import Point2d exposing (Point2d)
import Point3d exposing (Point3d)
import Polyline3d
import Quantity exposing (zero)
import Scene3d exposing (Entity, group)
import Scene3d.Material as Material exposing (Material, Texture)
import Scene3d.Mesh exposing (Mesh)
import Set
import SketchPlane3d
import Sphere3d
import Task
import Time
import TriangularMesh
import Vector3d
import Viewpoint3d exposing (Viewpoint3d)
import WebGL.Texture



-- PICTURE


{-| Make a picture! Here is a picture of a triangle with an eyeball:

    import Playground exposing (..)

    main =
        picture
            [ triangle green 150
            , circle white 40
            , circle black 10
            ]

-}
picture : List Shape -> Program () Picture Msg
picture shapes =
    let
        view screen =
            { title = "Playground"
            , body = [ pictureView screen shapes ]
            }
    in
    Browser.document
        { init = pictureInit
        , view = view
        , update = pictureUpdate
        , subscriptions = pictureSubscriptions
        }


{-| Picture model
-}
type alias Picture =
    { screen : Screen
    , font : Maybe Font
    }


{-| Picture init function
-}
pictureInit : () -> ( Picture, Cmd Msg )
pictureInit () =
    ( Picture (toScreen 600 600) Nothing
    , Cmd.batch
        [ Task.perform GotViewport Dom.getViewport
        , Task.attempt GotFont <| Material.load MogeeFont.spriteSrc
        ]
    )


{-| Picture view function
-}
pictureView : Picture -> List Shape -> Html.Html Msg
pictureView =
    render isometric


{-| Picture update function
-}
pictureUpdate : Msg -> Picture -> ( Picture, Cmd Msg )
pictureUpdate msg p =
    case msg of
        GotViewport { viewport } ->
            ( { p | screen = toScreen viewport.width viewport.height }
            , Cmd.none
            )

        GotFont (Ok texture) ->
            ( { p | font = Just texture }
            , Cmd.none
            )

        Resized w h ->
            ( { p | screen = toScreen (toFloat w) (toFloat h) }
            , Cmd.none
            )

        _ ->
            ( p, Cmd.none )


{-| Picture subscriptions
-}
pictureSubscriptions : Picture -> Sub Msg
pictureSubscriptions _ =
    E.onResize Resized



-- COMPUTER


{-| When writing a [`game`](#game), you can look up all sorts of information
about your computer:

  - [`Mouse`](#Mouse) - Where is the mouse right now?
  - [`Keyboard`](#Keyboard) - Are the arrow keys down?
  - [`Screen`](#Screen) - How wide is the screen?
  - [`Time`](#Time) - What time is it right now?

So you can use expressions like `computer.mouse.x` and `computer.keyboard.enter`
in games where you want some mouse or keyboard interaction.

-}
type alias Computer =
    { inbox : List Message
    , secondsBeforeSend : Number
    , touch :
        { list : List Touch
        , current : Maybe Touch
        , change : Maybe Touch
        , previous : Maybe Touch
        }
    , mouse : Mouse
    , keyboard : Keyboard
    , screen : Screen
    , time : Time
    }



-- MESSAGING


type alias Message =
    { sender : String
    , subject : String
    , predicate : String
    , object : String
    }



-- TOUCH


{-| Figure out what is going on with touch (touch pad, touch screen).
-}
type alias Touch =
    { x : Number
    , y : Number
    }



-- MOUSE


{-| Figure out what is going on with the mouse.

You could draw a circle around the mouse with a program like this:

    import Playground exposing (..)

    main =
        game view update 0

    view computer memory =
        [ circle yellow 40
            |> moveX computer.mouse.x
            |> moveY computer.mouse.y
        ]

    update computer memory =
        memory

You could also use `computer.mouse.down` to change the color of the circle
while the mouse button is down.

-}
type alias Mouse =
    { x : Number
    , y : Number
    , down : Bool
    , click : Bool
    }


{-| A number like `1` or `3.14` or `-120`.
-}
type alias Number =
    Float



-- KEYBOARD


{-| Figure out what is going on with the keyboard.

If someone is pressing the UP and RIGHT arrows, you will see a value like this:

    { up = True
    , down = False
    , left = False
    , right = True
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.fromList [ "ArrowUp", "ArrowRight" ]
    }

So if you want to move a character based on arrows, you could write an update
like this:

    update computer y =
        if computer.keyboard.up then
            y + 1

        else
            y

Check out [`toX`](#toX) and [`toY`](#toY) which make this even easier!

**Note:** The `keys` set will be filled with the name of all keys which are
down right now. So you will see things like `"a"`, `"b"`, `"c"`, `"1"`, `"2"`,
`"Space"`, and `"Control"` in there. Check out [this list][list] to see the
names used for all the different special keys! From there, you can use
[`Set.member`][member] to check for whichever key you want. E.g.
`Set.member "Control" computer.keyboard.keys`.

[list]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
[member]: /packages/elm/core/latest/Set#member

-}
type alias Keyboard =
    { up : Bool
    , down : Bool
    , left : Bool
    , right : Bool
    , space : Bool
    , enter : Bool
    , shift : Bool
    , backspace : Bool
    , keys : Set.Set String
    }


{-| Turn the LEFT and RIGHT arrows into a number.

    toX { left = False, right = False, ... } == 0
    toX { left = True , right = False, ... } == -1
    toX { left = False, right = True , ... } == 1
    toX { left = True , right = True , ... } == 0

So to make a square move left and right based on the arrow keys, we could say:

    import Playground exposing (..)

    main =
        game view update 0

    view computer x =
        [ square green 40
            |> moveX x
        ]

    update computer x =
        x + toX computer.keyboard

-}
toX : Keyboard -> Number
toX keyboard =
    (if keyboard.right then
        1

     else
        0
    )
        - (if keyboard.left then
            1

           else
            0
          )


{-| Turn the UP and DOWN arrows into a number.

    toY { up = False, down = False, ... } == 0
    toY { up = True , down = False, ... } == 1
    toY { up = False, down = True , ... } == -1
    toY { up = True , down = True , ... } == 0

This can be used to move characters around in games just like [`toX`](#toX):

    import Playground exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square blue 40
            |> move x y
        ]

    update computer ( x, y ) =
        ( x + toX computer.keyboard
        , y + toY computer.keyboard
        )

-}
toY : Keyboard -> Number
toY keyboard =
    (if keyboard.up then
        1

     else
        0
    )
        - (if keyboard.down then
            1

           else
            0
          )


{-| If you just use `toX` and `toY`, you will move diagonal too fast. You will go
right at 1 pixel per update, but you will go up/right at 1.41421 pixels per
update.

So `toXY` turns the arrow keys into an `(x,y)` pair such that the distance is
normalized:

    toXY { up = True , down = False, left = False, right = False, ... } == (1, 0)
    toXY { up = True , down = False, left = False, right = True , ... } == (0.707, 0.707)
    toXY { up = False, down = False, left = False, right = True , ... } == (0, 1)

Now when you go up/right, you are still going 1 pixel per update.

    import Playground exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square green 40
            |> move x y
        ]

    update computer ( x, y ) =
        let
            ( dx, dy ) =
                toXY computer.keyboard
        in
        ( x + dx, y + dy )

-}
toXY : Keyboard -> ( Number, Number )
toXY keyboard =
    let
        x =
            toX keyboard

        y =
            toY keyboard
    in
    if x /= 0 && y /= 0 then
        ( x / squareRootOfTwo, y / squareRootOfTwo )

    else
        ( x, y )


squareRootOfTwo : Number
squareRootOfTwo =
    sqrt 2



-- SCREEN


{-| Get the dimensions of the screen. If the screen is 800 by 600, you will see
a value like this:

    { width = 800
    , height = 600
    , top = 300
    , left = -400
    , right = 400
    , bottom = -300
    }

This can be nice when used with [`moveY`](#moveY) if you want to put something
on the bottom of the screen, no matter the dimensions.

-}
type alias Screen =
    { width : Number
    , height : Number
    , top : Number
    , left : Number
    , right : Number
    , bottom : Number
    }



-- TIME


{-| The current time.

Helpful when making an [`animation`](#animation) with functions like
[`spin`](#spin), [`wave`](#wave), and [`zigzag`](#zigzag).

-}
type Time
    = Time Time.Posix


timeFromMillis : Int -> Time
timeFromMillis timestamp =
    timestamp
        |> Time.millisToPosix
        |> Time


{-| Return the number of seconds between two instances of Time.
-}
secondsBetween : Time -> Time -> Number
secondsBetween (Time time1) (Time time2) =
    (Time.posixToMillis time1 - Time.posixToMillis time2)
        |> abs
        |> toFloat
        |> (/) 1000


{-| Create an angle that cycles from 0 to 360 degrees over time.

Here is an [`animation`](#animation) with a spinning triangle:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ triangle orange 50
            |> rotate (spin 8 time)
        ]

It will do a full rotation once every eight seconds. Try changing the `8` to
a `2` to make it do a full rotation every two seconds. It moves a lot faster!

-}
spin : Number -> Time -> Number
spin period time =
    360 * toFrac period time


{-| Smoothly wave between two numbers.

Here is an [`animation`](#animation) with a circle that resizes:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ circle lightBlue (wave 50 90 7 time)
        ]

The radius of the circle will cycles between 50 and 90 every seven seconds.
It kind of looks like it is breathing.

-}
wave : Number -> Number -> Number -> Time -> Number
wave lo hi period time =
    lo + (hi - lo) * (1 + cos (turns (toFrac period time))) / 2


{-| Zig zag between two numbers.

Here is an [`animation`](#animation) with a rectangle that tips back and forth:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ rectangle lightGreen 20 100
            |> rotate (zigzag -20 20 4 time)
        ]

It gets rotated by an angle. The angle cycles from -20 degrees to 20 degrees
every four seconds.

-}
zigzag : Number -> Number -> Number -> Time -> Number
zigzag lo hi period time =
    lo + (hi - lo) * abs (2 * toFrac period time - 1)


toFrac : Float -> Time -> Float
toFrac period (Time posix) =
    let
        ms =
            Time.posixToMillis posix

        p =
            period * 1000
    in
    toFloat (modBy (round p) ms) / p


{-| BeginOfTime
-}
beginOfTime : Time
beginOfTime =
    Time (Time.millisToPosix 0)



-- ANIMATION


{-| Create an animation!

Once you get comfortable using [`picture`](#picture) to layout shapes, you can
try out an `animation`. Here is square that zigzags back and forth:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ square blue 40
            |> moveX (zigzag -100 100 2 time)
        ]

We need to define a `view` to make our animation work.

Within `view` we can use functions like [`spin`](#spin), [`wave`](#wave),
and [`zigzag`](#zigzag) to move and rotate our shapes.

-}
animation : (Time -> List Shape) -> Program () Animation Msg
animation viewFrame =
    let
        view a =
            { title = "Playground"
            , body = [ animationView a viewFrame ]
            }

        update msg model =
            ( animationUpdate msg model
            , Cmd.none
            )

        subscriptions (Animation visibility _ _ _) =
            case visibility of
                E.Hidden ->
                    E.onVisibilityChange VisibilityChanged

                E.Visible ->
                    animationSubscriptions
    in
    Browser.document
        { init = animationInit
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


{-| The type for animations.
-}
type Animation
    = Animation E.Visibility (Maybe Font) Screen Time


{-| Animation init
-}
animationInit : () -> ( Animation, Cmd Msg )
animationInit () =
    ( Animation E.Visible Nothing (toScreen 600 600) (Time (Time.millisToPosix 0))
    , Cmd.batch
        [ Task.perform GotViewport Dom.getViewport
        , Task.attempt GotFont <| Material.load MogeeFont.spriteSrc
        ]
    )


{-| Animation view
-}
animationView : Animation -> (Time -> List Shape) -> Html.Html Msg
animationView (Animation _ font screen time) viewFrame =
    render
        isometric
        { screen = screen, font = font }
        (viewFrame time)


{-| Animation subscriptions
-}
animationSubscriptions : Sub Msg
animationSubscriptions =
    Sub.batch
        [ E.onResize Resized
        , E.onAnimationFrame Tick
        , E.onVisibilityChange VisibilityChanged
        ]


{-| Animation update function
-}
animationUpdate : Msg -> Animation -> Animation
animationUpdate msg ((Animation v f s t) as state) =
    case msg of
        Tick posix ->
            Animation v f s (Time posix)

        VisibilityChanged vis ->
            Animation vis f s t

        GotViewport { viewport } ->
            Animation v f (toScreen viewport.width viewport.height) t

        GotFont (Ok texture) ->
            Animation v (Just texture) s t

        GotFont (Err _) ->
            Animation v f s t

        Resized w h ->
            Animation v f (toScreen (toFloat w) (toFloat h)) t

        KeyChanged _ _ ->
            state

        MessagesReceived _ ->
            state

        MouseMove _ _ ->
            state

        MouseClick ->
            state

        MouseButton _ ->
            state

        TouchMove _ ->
            state



-- GAME


{-| Create a game!

Once you get comfortable with [`animation`](#animation), you can try making a
game with the keyboard and mouse. Here is an example of a green square that
just moves to the right:

    import Playground exposing (..)

    main =
        game view update 0

    view computer offset =
        [ square green 40
            |> moveRight offset
        ]

    update computer offset =
        offset + 0.03

This shows the three important parts of a game:

1.  `memory` - makes it possible to store information. So with our green square,
    we save the `offset` in memory. It starts out at `0`.
2.  `view` - lets us say which shapes to put on screen. So here we move our
    square right by the `offset` saved in memory.
3.  `update` - lets us update the memory. We are incrementing the `offset` by
    a tiny amount on each frame.

The `update` function is called about 60 times per second, so our little
changes to `offset` start to add up pretty quickly!

This game is not very fun though! Making a `game` also gives you access to the
[`Computer`](#Computer), so you can use information about the [`Mouse`](#Mouse)
and [`Keyboard`](#Keyboard) to make it interactive! So here is a red square that
moves based on the arrow keys:

    import Playground exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square red 40
            |> move x y
        ]

    update computer ( x, y ) =
        ( x + toX computer.keyboard
        , y + toY computer.keyboard
        )

Notice that in the `update` we use information from the keyboard to update the
`x` and `y` values. These building blocks let you make pretty fancy games!

-}
game : (Computer -> memory -> List Shape) -> (Computer -> memory -> memory) -> memory -> Program () (Game memory) Msg
game =
    gameWithCamera (always isometric)


{-| Create a game using a specific camera for viewing the scene!
-}
gameWithCamera : (memory -> Camera) -> (Computer -> memory -> List Shape) -> (Computer -> memory -> memory) -> memory -> Program () (Game memory) Msg
gameWithCamera cam viewMemory updateMemory initialMemory =
    let
        view model =
            { title = "Playground"
            , body = [ gameView cam viewMemory model ]

            --, body = [ lazy (gameView cam viewMemory) model ] -- might not be sensible because of time and its use
            }

        update msg model =
            ( gameUpdate updateMemory msg model
            , Cmd.none
            )
    in
    Browser.document
        { init = gameInit initialMemory
        , view = view
        , update = update
        , subscriptions = gameSubscriptions
        }


type alias WithMessages memory =
    { memory
        | outbox : List ( String, String, String )
    }


{-| A network Connection with server url, sender name, and the send interval
in seconds.
-}
type alias Connection =
    { server : String
    , name : String
    , sendIntervalInSeconds : Number
    }


{-| Create a network game; a game that has a messages `inbox` field in Computer
and a messages `outbox` as a field in its memory. The game takes a Connection
parameter. Messages sent are tagged with your sender name, configured as
`name` in the Connection.
-}
networkGame :
    Connection
    -> (Computer -> WithMessages memory -> List Shape)
    -> (Computer -> WithMessages memory -> WithMessages memory)
    -> WithMessages memory
    -> Program () (Game (WithMessages memory)) Msg
networkGame connection =
    networkGameWithCamera (always isometric) connection


{-| Create a network game using a specific camera for viewing the scene!
-}
networkGameWithCamera : (WithMessages memory -> Camera) -> Connection -> (Computer -> WithMessages memory -> List Shape) -> (Computer -> WithMessages memory -> WithMessages memory) -> WithMessages memory -> Program () (Game (WithMessages memory)) Msg
networkGameWithCamera cam connection viewMemory updateMemory initialMemory =
    let
        view model =
            { title = "Playground"
            , body = [ gameView cam viewMemory model ]

            --, body = [ lazy (gameView cam viewMemory) model ] -- might not be sensible because of time and its use
            }

        update msg model =
            networkGameUpdate updateMemory msg model
                |> withCommandsFromMessages connection
    in
    Browser.document
        { init = networkGameInit initialMemory
        , view = view
        , update = update
        , subscriptions = gameSubscriptions
        }


withCommandsFromMessages : Connection -> Game (WithMessages memory) -> ( Game (WithMessages memory), Cmd Msg )
withCommandsFromMessages { server, name, sendIntervalInSeconds } (Game visibility font memory computer) =
    if computer.secondsBeforeSend <= 0 then
        ( Game visibility
            font
            memory
            { computer
                | secondsBeforeSend =
                    if sendIntervalInSeconds < 0.1 then
                        0.1

                    else
                        sendIntervalInSeconds
            }
        , postMessages server name memory.outbox
        )

    else
        ( Game visibility font memory { computer | secondsBeforeSend = computer.secondsBeforeSend - 1 / 60 }
        , Cmd.none
        )


postMessages : String -> String -> List ( String, String, String ) -> Cmd Msg
postMessages url sender messages =
    case String.trim url of
        "" ->
            Cmd.none

        trimmedUrl ->
            Http.post
                { url = trimmedUrl
                , expect = Http.expectJson MessagesReceived (D.list messageDecoder)
                , body =
                    messages
                        |> E.list (messageEncoded sender)
                        |> Http.jsonBody
                }


messageEncoded : String -> ( String, String, String ) -> E.Value
messageEncoded sender ( subject, predicate, object ) =
    [ ( "sender", E.string sender )
    , ( "subject", E.string subject )
    , ( "predicate", E.string predicate )
    , ( "object", E.string object )
    ]
        |> E.object


messageDecoder : D.Decoder Message
messageDecoder =
    D.map4 Message
        (D.field "sender" D.string)
        (D.field "subject" D.string)
        (D.field "predicate" D.string)
        (D.field "object" D.string)


initialComputer : Computer
initialComputer =
    { inbox = []
    , secondsBeforeSend = 0
    , touch = { list = [], current = Nothing, change = Nothing, previous = Nothing }
    , mouse = Mouse 0 0 False False
    , keyboard = emptyKeyboard
    , screen = toScreen 600 600
    , time = beginOfTime
    }


{-| Game init function
-}
gameInit : memory -> () -> ( Game memory, Cmd Msg )
gameInit initialMemory () =
    ( Game E.Visible Nothing initialMemory initialComputer
    , Cmd.batch
        [ Task.perform GotViewport Dom.getViewport
        , Task.attempt GotFont <| Material.load MogeeFont.spriteSrc
        ]
    )


networkGameInit : WithMessages memory -> () -> ( Game (WithMessages memory), Cmd Msg )
networkGameInit initialMemory () =
    ( Game E.Visible Nothing initialMemory initialComputer
    , Cmd.batch
        [ Task.perform GotViewport Dom.getViewport
        , Task.attempt GotFont <| Material.load MogeeFont.spriteSrc
        ]
    )


{-| Game view function
-}
gameView : (memory -> Camera) -> (Computer -> memory -> List Shape) -> Game memory -> Html.Html Msg
gameView cam viewMemory (Game _ font memory computer) =
    render
        (cam memory)
        { screen = computer.screen, font = font }
        (viewMemory computer memory)



-- SUBSCRIPTIONS


{-| Game subscriptions
-}
gameSubscriptions : Game memory -> Sub Msg
gameSubscriptions (Game visibility _ _ _) =
    case visibility of
        E.Hidden ->
            E.onVisibilityChange VisibilityChanged

        E.Visible ->
            Sub.batch
                [ E.onResize Resized
                , E.onKeyUp (D.map (KeyChanged False) (D.field "key" D.string))
                , E.onKeyDown (D.map (KeyChanged True) (D.field "key" D.string))
                , E.onAnimationFrame Tick
                , E.onVisibilityChange VisibilityChanged
                , E.onClick (D.succeed MouseClick)
                , E.onMouseDown (D.succeed (MouseButton True))
                , E.onMouseUp (D.succeed (MouseButton False))
                , E.onMouseMove (D.map2 MouseMove (D.field "pageX" D.float) (D.field "pageY" D.float))
                ]



-- GAME HELPERS


{-| Game model containing the visibility status, custom data (memory) and the Computer state record.
-}
type Game memory
    = Game E.Visibility (Maybe Font) memory Computer


{-| Animation message alias
-}
type alias AnimationMsg =
    Msg


{-| Game message alias
-}
type alias GameMsg =
    Msg


{-| Camera type
-}
type alias Camera =
    { mode : CameraMode
    , target : Point3d Meters WorldCoordinates
    }


{-| Camera Mode type
-}
type CameraMode
    = FirstPerson (Point3d Meters WorldCoordinates) Angle
    | Isometric Length Length
    | Orbit Number Number Number Angle


{-| Create an isometric camera
-}
isometric : Camera
isometric =
    Camera (Isometric (Length.meters 10) (Length.meters 5)) Point3d.origin


{-| Create a camera looking from a point x y z, towards the origin (0, 0, 0)
-}
eyesAt : Number -> Number -> Number -> Camera
eyesAt x y z =
    Camera (FirstPerson (Point3d.centimeters x y z) (Angle.degrees 40)) Point3d.origin


{-| Modify a camera to look at a specific point x y z
-}
lookAt : Number -> Number -> Number -> Camera -> Camera
lookAt x y z cam =
    { cam | target = Point3d.centimeters x y z }


{-| Playground message type
-}
type Msg
    = KeyChanged Bool String
    | Tick Time.Posix
    | GotViewport Dom.Viewport
    | Resized Int Int
    | VisibilityChanged E.Visibility
    | MouseMove Float Float
    | MouseClick
    | MouseButton Bool
    | TouchMove Touch.Event
    | MessagesReceived (Result Http.Error (List Message))
    | GotFont (Result WebGL.Texture.Error Font)


{-| Game update function
-}
gameUpdate : (Computer -> memory -> memory) -> Msg -> Game memory -> Game memory
gameUpdate updateMemory msg (Game vis font memory computer) =
    case msg of
        Tick time ->
            Game vis font (updateMemory computer memory) <|
                if computer.mouse.click then
                    { computer | time = Time time, mouse = mouseClick False computer.mouse }

                else
                    { computer | time = Time time }

        GotViewport { viewport } ->
            Game vis font memory { computer | screen = toScreen viewport.width viewport.height }

        GotFont (Ok texture) ->
            Game vis (Just texture) memory computer

        GotFont (Err _) ->
            Game vis font memory computer

        Resized w h ->
            Game vis font memory { computer | screen = toScreen (toFloat w) (toFloat h) }

        KeyChanged isDown key ->
            Game vis font memory { computer | keyboard = updateKeyboard isDown key computer.keyboard }

        MessagesReceived (Ok messages) ->
            Game vis font memory { computer | inbox = messages }

        MessagesReceived (Err _) ->
            Game vis font memory computer

        MouseMove pageX pageY ->
            let
                x =
                    computer.screen.left + pageX

                y =
                    computer.screen.top - pageY
            in
            Game vis font memory { computer | mouse = mouseMove x y computer.mouse }

        MouseClick ->
            Game vis font memory { computer | mouse = mouseClick True computer.mouse }

        MouseButton isDown ->
            Game vis font memory { computer | mouse = mouseDown isDown computer.mouse }

        TouchMove te ->
            let
                positions =
                    List.map
                        (\{ clientPos } ->
                            case clientPos of
                                ( x, y ) ->
                                    { x = x, y = y }
                        )
                        te.touches

                position =
                    List.head positions
            in
            Game vis
                font
                memory
                { computer
                    | touch =
                        { list = positions
                        , current = position
                        , previous = computer.touch.current
                        , change =
                            case ( position, computer.touch.previous ) of
                                ( Just new, Just old ) ->
                                    Just
                                        { x = new.x - old.x
                                        , y = new.y - old.y
                                        }

                                _ ->
                                    Nothing
                        }
                }

        VisibilityChanged visibility ->
            Game visibility
                font
                memory
                { computer
                    | keyboard = emptyKeyboard
                    , mouse = Mouse computer.mouse.x computer.mouse.y False False
                }


networkGameUpdate : (Computer -> WithMessages memory -> WithMessages memory) -> Msg -> Game (WithMessages memory) -> Game (WithMessages memory)
networkGameUpdate updateMemory msg (Game vis font memory computer) =
    case msg of
        Tick time ->
            Game vis font (updateMemory computer memory) <|
                if computer.mouse.click then
                    { computer | time = Time time, mouse = mouseClick False computer.mouse }

                else
                    { computer | time = Time time }

        GotViewport { viewport } ->
            Game vis font memory { computer | screen = toScreen viewport.width viewport.height }

        GotFont (Ok texture) ->
            Game vis (Just texture) memory computer

        GotFont (Err _) ->
            Game vis font memory computer

        Resized w h ->
            Game vis font memory { computer | screen = toScreen (toFloat w) (toFloat h) }

        KeyChanged isDown key ->
            Game vis font memory { computer | keyboard = updateKeyboard isDown key computer.keyboard }

        MessagesReceived (Ok messages) ->
            Game vis font memory { computer | inbox = messages }

        MessagesReceived (Err _) ->
            Game vis font memory computer

        MouseMove pageX pageY ->
            let
                x =
                    computer.screen.left + pageX

                y =
                    computer.screen.top - pageY
            in
            Game vis font memory { computer | mouse = mouseMove x y computer.mouse }

        MouseClick ->
            Game vis font memory { computer | mouse = mouseClick True computer.mouse }

        MouseButton isDown ->
            Game vis font memory { computer | mouse = mouseDown isDown computer.mouse }

        TouchMove te ->
            let
                positions =
                    List.map
                        (\{ clientPos } ->
                            case clientPos of
                                ( x, y ) ->
                                    { x = x, y = y }
                        )
                        te.touches

                position =
                    List.head positions
            in
            Game vis
                font
                memory
                { computer
                    | touch =
                        { list = positions
                        , current = position
                        , previous = computer.touch.current
                        , change =
                            case ( position, computer.touch.previous ) of
                                ( Just new, Just old ) ->
                                    Just
                                        { x = new.x - old.x
                                        , y = new.y - old.y
                                        }

                                _ ->
                                    Nothing
                        }
                }

        VisibilityChanged visibility ->
            Game visibility
                font
                memory
                { computer
                    | keyboard = emptyKeyboard
                    , mouse = Mouse computer.mouse.x computer.mouse.y False False
                }



-- SCREEN HELPERS


toScreen : Float -> Float -> Screen
toScreen width height =
    { width = width
    , height = height
    , top = height / 2
    , left = -width / 2
    , right = width / 2
    , bottom = -height / 2
    }



-- MOUSE HELPERS


mouseClick : Bool -> Mouse -> Mouse
mouseClick bool mouse =
    { mouse | click = bool }


mouseDown : Bool -> Mouse -> Mouse
mouseDown bool mouse =
    { mouse | down = bool }


mouseMove : Float -> Float -> Mouse -> Mouse
mouseMove x y mouse =
    { mouse | x = x, y = y }



-- KEYBOARD HELPERS


emptyKeyboard : Keyboard
emptyKeyboard =
    { up = False
    , down = False
    , left = False
    , right = False
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.empty
    }


updateKeyboard : Bool -> String -> Keyboard -> Keyboard
updateKeyboard isDown key keyboard =
    let
        keys =
            if isDown then
                Set.insert key keyboard.keys

            else
                Set.remove key keyboard.keys
    in
    case key of
        " " ->
            { keyboard | keys = keys, space = isDown }

        "Enter" ->
            { keyboard | keys = keys, enter = isDown }

        "Shift" ->
            { keyboard | keys = keys, shift = isDown }

        "Backspace" ->
            { keyboard | keys = keys, backspace = isDown }

        "ArrowUp" ->
            { keyboard | keys = keys, up = isDown }

        "ArrowDown" ->
            { keyboard | keys = keys, down = isDown }

        "ArrowLeft" ->
            { keyboard | keys = keys, left = isDown }

        "ArrowRight" ->
            { keyboard | keys = keys, right = isDown }

        _ ->
            { keyboard | keys = keys }



-- SHAPES


{-| Shapes help you make a `picture`, `animation`, or `game`.

Read on to see examples of [`circle`](#circle), [`rectangle`](#rectangle),
[`words`](#words), [`image`](#image), and many more!

-}
type Shape
    = Shape
        Number
        -- x
        Number
        -- y
        Number
        -- z
        Number
        -- angle roll
        Number
        -- angle pitch
        Number
        -- angle yaw
        Number
        -- scale
        Number
        -- alpha
        Form


type Form
    = Group (List Shape)
    | Circle Color Number
    | Triangle Color Number
    | Square Color Number
    | Rectangle Color Number Number
    | Polygon Color (List ( Number, Number ))
    | Snake Color (List ( Number, Number, Number ))
    | Sphere Color Number
    | Cylinder Color Number Number
    | Cone Color Number Number
    | Cube Color Number
    | Block Color Number Number Number
    | Prism Color Number Number
    | Wall Color Number (List ( Number, Number, Number ))
    | Words Color String
    | Object Color (List ( Number, Number, Number )) (List ( Int, Int, Int ))
    | Entity (Entity WorldCoordinates)


type alias Font =
    Texture Color



--    | ExtrudedPolygon Color Number (List ( Number, Number ))


{-| Make circles:

    dot =
        circle red 10

    sun =
        circle yellow 300

You give a color and then the radius. So the higher the number, the larger
the circle.

-}
circle : Color -> Number -> Shape
circle color radius =
    Shape 0 0 0 0 0 0 1 1 (Circle color radius)


{-| Make cylinders:

    pillar =
        cylinder red 10 50

You give a color, the radius and then the height.

-}
cylinder : Color -> Number -> Number -> Shape
cylinder color radius height =
    Shape 0 0 0 0 0 0 1 1 (Cylinder color radius height)


{-| Make cones:

    spike =
        cone red 10 50

You give a color, the radius and then the height.

-}
cone : Color -> Number -> Number -> Shape
cone color radius height =
    Shape 0 0 0 0 0 0 1 1 (Cone color radius height)


{-| Make triangles:

    triangle blue 50

You give a color and then its size.

-}
triangle : Color -> Number -> Shape
triangle color size =
    Shape 0 0 0 0 0 0 1 1 (Triangle color size)


{-| Make squares. Here are two squares combined to look like an empty box:

    import Playground exposing (..)

    main =
        picture
            [ square purple 80
            , square white 60
            ]

The number you give is the dimension of each side. So that purple square would
be 80 pixels by 80 pixels.

-}
square : Color -> Number -> Shape
square color n =
    Shape 0 0 0 0 0 0 1 1 (Rectangle color n n)


{-| Make rectangles. This example makes a red cross:

    import Playground exposing (..)

    main =
        picture
            [ rectangle red 20 60
            , rectangle red 60 20
            ]

You give the color, width, and then height. So the first shape is vertical
part of the cross, the thinner and taller part.

-}
rectangle : Color -> Number -> Number -> Shape
rectangle color width height =
    Shape 0 0 0 0 0 0 1 1 (Rectangle color width height)


{-| Make any shape you want! Here is a very thin triangle:

    import Playground exposing (..)

    main =
        picture
            [ polygon black [ ( -10, -20 ), ( 0, 100 ), ( 10, -20 ) ]
            ]

**Note:** If you [`rotate`](#rotate) a polygon, it will always rotate around
`(0,0)`. So it is best to build your shapes around that point, and then use
[`move`](#move) or [`group`](#group) so that rotation makes more sense.

-}
polygon : Color -> List ( Number, Number ) -> Shape
polygon color points =
    Shape 0 0 0 0 0 0 1 1 (Polygon color points)


{-| Make a snake!
-}
snake : Color -> List ( Number, Number, Number ) -> Shape
snake color points =
    Shape 0 0 0 0 0 0 1 1 (Snake color points)


{-| Make sphere:

    import Playground exposing (..)

    main =
        picture
            [ sphere green 10
            ]

You give the color, width, height, and then depth. So the first shape is the
vertical part of the cross, the thinner and taller part.

-}
sphere : Color -> Number -> Shape
sphere color size =
    Shape 0 0 0 0 0 0 1 1 (Sphere color size)


{-| Make cubes:

    import Playground exposing (..)

    main =
        picture
            [ cube blue 10
            ]

You give the color, width, height, and then depth. So the first shape is the
vertical part of the cross, the thinner and taller part.

-}
cube : Color -> Number -> Shape
cube color size =
    Shape 0 0 0 0 0 0 1 1 (Cube color size)


{-| Make blocks. This example makes a red cross:

    import Playground exposing (..)

    main =
        picture
            [ block red 20 60 10
            , block red 60 20 10
            ]

You give the color, width, height, and then depth. So the first shape is the
vertical part of the cross, the thinner and taller part.

-}
block : Color -> Number -> Number -> Number -> Shape
block color width height depth =
    Shape 0 0 0 0 0 0 1 1 (Block color width height depth)


{-| Make 3d objects from vertices and faces, such as a pyramid:

    import Playground3d exposing (..)

    main =
        picture
            [ obj
                [ ( 1, 1, -1 )
                , ( 1, -1, -1 )
                , ( -1, -1, -1 )
                , ( -1, 1, -1 )
                , ( 0, 0, 1 )
                ]
                [ ( 1, 2, 3 )
                , ( 3, 4, 1 )
                , ( 1, 4, 5 )
                , ( 5, 4, 3 )
                , ( 3, 2, 5 )
                , ( 5, 2, 1 )
                ]
            ]

-}
obj : Color -> List ( Number, Number, Number ) -> List ( Int, Int, Int ) -> Shape
obj color vertices faces =
    Shape 0 0 0 0 0 0 1 1 (Object color vertices faces)


{-| 3D shapes can be quite intensive to render, so it is best to render the more
complex shapes into an 3D entity once and then draw this prerendered version in
the view. You can still use transformation functions from the `Scene3d` package
such as translation and rotation on the prerendered entities.

For instance if you would like to prerender parts of your snow dog avatar but
still want to animate its head:

    snowdog time =
        group
            [ head white
                |> prerendered
                |> move 50 0 70
                |> yaw (wave -30 30 6 time)
                |> pitch (wave -10 10 3 time)
            , group
                [ cylinder white 15 80 |> pitch 90 |> moveZ 50
                , leg |> move 35 10 20
                , leg |> move 35 -10 20
                , leg |> move -35 10 20
                , leg |> move -35 -10 20
                , cylinder white 7 50 |> pitch -45 |> move -50 0 75
                ]
                |> prerendered
            ]

    leg =
        cylinder white 10 40

    head color =
        group
            [ sphere color 25
            , sphere color 10 |> move 25 0 -5
            , sphere black 5 |> move 35 0 -5
            , sphere black 5 |> move 17 12 5
            , sphere black 5 |> move 17 -12 5
            , triangle color 20
                |> move -5 12 37
                |> yaw 170
                |> pitch 83
                |> roll 2
                |> scale 0.4
            , triangle color 20
                |> move -5 -12 37
                |> yaw 190
                |> pitch 83
                |> roll -2
                |> scale 0.4
            ]

-}
prerendered : Shape -> Shape
prerendered =
    entity >> Entity >> Shape 0 0 0 0 0 0 1 1


{-| Put shapes together so you can [`move`](#move) and [`rotate`](#rotate)
them as a group. Maybe you want to put a bunch of stars in the sky:

    import Playground exposing (..)

    main =
        picture
            [ star
                |> move 100 100
                |> rotate 5
            , star
                |> move -120 40
                |> rotate 20
            , star
                |> move 80 -150
                |> rotate 32
            , star
                |> move -90 -30
                |> rotate -16
            ]

    star =
        group
            [ triangle yellow 20
            , triangle yellow 20
                |> rotate 180
            ]

-}
group : List Shape -> Shape
group shapes =
    Shape 0 0 0 0 0 0 1 1 (Group shapes)


{-| Pull a 2D shape "up" to form a 3D body:

    circle blue 20
        |> extrude 50

This will create a flat circle "extruded" along the
z-axis to form a 3D cylinder. The extruded form is
centered around the xy-plane.

-}
extrude : Number -> Shape -> Shape
extrude h shape =
    case shape of
        Shape x y z rr rp ry s a (Group shapes) ->
            shapes
                |> List.map (extrude h)
                |> Group
                |> Shape x y z rr rp ry s a

        Shape x y z rr rp ry s a (Circle c r) ->
            Shape x y z rr rp ry s a (Cylinder c r h)

        Shape x y z rr rp ry s a (Square c r) ->
            if h == r then
                Shape x y z rr rp ry s a (Cube c r)

            else
                Shape x y z rr rp ry s a (Block c r r h)

        Shape x y z rr rp ry s a (Rectangle c wb hb) ->
            Shape x y z rr rp ry s a (Block c wb hb h)

        Shape x y z rr rp ry s a (Triangle c size) ->
            Shape x y z rr rp ry s a (Prism c size h)

        --Shape x y z rr rp ry s a (Polygon c points) ->
        --    Shape x y z rr rp ry s a (ExtrudedPolygon c h points)
        Shape x y z rr rp ry s a (Snake c p) ->
            Shape x y z rr rp ry s a (Wall c h p)

        _ ->
            shape


{-| Pull a 2D shape "up" to form a 3D body:

    circle blue 20
        |> pullUp 50

This will create a flat circle "pulled up" (or "extruded") along the
z-axis to form a 3D cylinder.

-}
pullUp : Number -> Shape -> Shape
pullUp h shape =
    case shape of
        Shape x y z rr rp ry s a (Group shapes) ->
            shapes
                |> List.map (pullUp h)
                |> Group
                |> Shape x y z rr rp ry s a

        Shape x y z rr rp ry s a (Circle c r) ->
            Shape x y (z + h / 2) rr rp ry s a (Cylinder c r h)

        Shape x y z rr rp ry s a (Square c r) ->
            if h == r then
                Shape x y (z + h / 2) rr rp ry s a (Cube c r)

            else
                Shape x y (z + h / 2) rr rp ry s a (Block c r r h)

        Shape x y z rr rp ry s a (Rectangle c wb hb) ->
            Shape x y (z + h / 2) rr rp ry s a (Block c wb hb h)

        Shape x y z rr rp ry s a (Triangle c size) ->
            Shape x y (z + h / 2) rr rp ry s a (Prism c size h)

        Shape x y z rr rp ry s a (Snake c p) ->
            Shape x y z rr rp ry s a (Wall c h (p |> List.map (\( px, py, pz ) -> ( px, py, pz + h / 2 ))))

        _ ->
            shape


{-| Show some words!

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello! How are you?"
            ]

You can use [`scale`](#scale) to make the words bigger or smaller.

-}
words : Color -> String -> Shape
words color string =
    Shape 0 0 0 0 0 0 1 1 (Words color string)



-- TRANSFORMS


{-| Move a shape by some number of pixels:

    import Playground exposing (..)

    main =
        picture
            [ square red 100
                |> move -60 60 0
            , square yellow 100
                |> move 60 60 0
            , square green 100
                |> move 60 -60 0
            , square blue 100
                |> move -60 -60 0
            ]

-}
move : Number -> Number -> Number -> Shape -> Shape
move dx dy dz (Shape x y z rr rp ry s o f) =
    Shape (x + dx) (y + dy) (z + dz) rr rp ry s o f


{-| Move the `x` coordinate of a shape by some amount. Here is a square that
moves back and forth:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ square purple 20
            |> moveX (wave 4 -200 200 time)
        ]

Using `moveX` feels a bit nicer here because the movement may be positive or negative.

-}
moveX : Number -> Shape -> Shape
moveX dx (Shape x y z rr rp ry s o f) =
    Shape (x + dx) y z rr rp ry s o f


{-| Move the `y` coordinate of a shape by some amount. Maybe you want to make
grass along the bottom of the screen:

    import Playground exposing (..)

    main =
        game view update 0

    update computer memory =
        memory

    view computer count =
        [ rectangle green computer.screen.width 100
            |> moveY computer.screen.bottom
        ]

Using `moveY` feels a bit nicer when setting things relative to the bottom or
top of the screen, since the values are negative sometimes.

-}
moveY : Number -> Shape -> Shape
moveY dy (Shape x y z rr rp ry s o f) =
    Shape x (y + dy) z rr rp ry s o f


{-| Move the `z` coordinate of a shape by some amount:
-}
moveZ : Number -> Shape -> Shape
moveZ dz (Shape x y z rr rp ry s o f) =
    Shape x y (z + dz) rr rp ry s o f


{-| Make a shape bigger or smaller. So if you wanted some [`words`](#words) to
be larger, you could say:

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello, nice to see you!"
                |> scale 3
            ]

-}
scale : Number -> Shape -> Shape
scale ns (Shape x y z rr rp ry s o f) =
    Shape x y z rr rp ry (s * ns) o f


{-| Rotate shapes in degrees.

    import Playground exposing (..)

    main =
        picture
            [ triangle black 50
                |> rotate 10
            ]

The degrees go **counter-clockwise** to match the direction of the
[unit circle](https://en.wikipedia.org/wiki/Unit_circle).

-}
rotate : Number -> Shape -> Shape
rotate da (Shape x y z rr rp ry s o f) =
    Shape x y z (rr + da) rp ry s o f


{-| Rotate shapes in degrees, along the X axis:

    import Playground exposing (..)

    main =
        picture
            [ triangle black 50
                |> roll 10
            ]

    Search Wikipedia for "roll, pitch, yaw" to find out why it is called "roll". ;)

-}
roll : Number -> Shape -> Shape
roll dr (Shape x y z rr rp ry s o f) =
    Shape x y z (rr + dr) rp ry s o f


{-| Rotate shapes in degrees, along the Y axis:

    import Playground exposing (..)

    main =
        picture
            [ triangle black 50
                |> pitch 10
            ]

    Search Wikipedia for "roll, pitch, yaw" to find out why it is called "pitch". ;)

-}
pitch : Number -> Shape -> Shape
pitch dp (Shape x y z rr rp ry s o f) =
    Shape x y z rr (rp + dp) ry s o f


{-| Rotate shapes in degrees, along the Z axis:

    import Playground exposing (..)

    main =
        picture
            [ triangle black 50
                |> yaw 10
            ]

    Search Wikipedia for "roll, pitch, yaw" to find out why it is called "yaw". ;)

-}
yaw : Number -> Shape -> Shape
yaw dy (Shape x y z rr rp ry s o f) =
    Shape x y z rr rp (ry + dy) s o f


{-| Fade a shape. This lets you make shapes see-through or even completely
invisible. Here is a shape that fades in and out:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ square orange 30
        , square blue 200
            |> fade (zigzag 0 1 3 time)
        ]

The number has to be between `0` and `1`, where `0` is totally transparent
and `1` is completely solid.

-}
fade : Number -> Shape -> Shape
fade o (Shape x y z rr rp ry s _ f) =
    Shape x y z rr rp ry s o f


{-| -}
lightYellow : Color
lightYellow =
    Color.lightYellow


{-| -}
yellow : Color
yellow =
    Color.yellow


{-| -}
darkYellow : Color
darkYellow =
    Color.darkYellow


{-| -}
lightOrange : Color
lightOrange =
    Color.lightOrange


{-| -}
orange : Color
orange =
    Color.orange


{-| -}
darkOrange : Color
darkOrange =
    Color.darkOrange


{-| -}
lightBrown : Color
lightBrown =
    Color.lightBrown


{-| -}
brown : Color
brown =
    Color.brown


{-| -}
darkBrown : Color
darkBrown =
    Color.darkBrown


{-| -}
lightGreen : Color
lightGreen =
    Color.lightGreen


{-| -}
green : Color
green =
    Color.green


{-| -}
darkGreen : Color
darkGreen =
    Color.darkGreen


{-| -}
lightBlue : Color
lightBlue =
    Color.lightBlue


{-| -}
blue : Color
blue =
    Color.blue


{-| -}
darkBlue : Color
darkBlue =
    Color.darkBlue


{-| -}
lightPurple : Color
lightPurple =
    Color.lightPurple


{-| -}
purple : Color
purple =
    Color.purple


{-| -}
darkPurple : Color
darkPurple =
    Color.darkPurple


{-| -}
lightRed : Color
lightRed =
    Color.lightRed


{-| -}
red : Color
red =
    Color.red


{-| -}
darkRed : Color
darkRed =
    Color.darkRed


{-| -}
lightGrey : Color
lightGrey =
    Color.lightGrey


{-| -}
grey : Color
grey =
    Color.grey


{-| -}
darkGrey : Color
darkGrey =
    Color.darkGrey


{-| -}
lightCharcoal : Color
lightCharcoal =
    Color.lightCharcoal


{-| -}
charcoal : Color
charcoal =
    Color.charcoal


{-| -}
darkCharcoal : Color
darkCharcoal =
    Color.darkCharcoal


{-| -}
white : Color
white =
    Color.white


{-| -}
black : Color
black =
    Color.black



-- ALTERNATE SPELLING GREYS


{-| -}
lightGray : Color
lightGray =
    Color.lightGray


{-| -}
gray : Color
gray =
    Color.gray


{-| -}
darkGray : Color
darkGray =
    Color.darkGray



-- CUSTOM COLORS


{-| RGB stands for Red-Green-Blue. With these three parts, you can create any
color you want. For example:

    brightBlue =
        rgb255 18 147 216

    brightGreen =
        rgb255 119 244 8

    brightPurple =
        rgb255 94 28 221

For `rgb255` each number needs to be an integer between 0 and 255.
Also see `rgb`, where each numer is expected to be a floating point number between 0 and 1.

It can be hard to figure out what numbers to pick, so try using a color picker
like [paletton] to find colors that look nice together. Once you find nice
colors, click on the color previews to get their RGB values.

[paletton]: http://paletton.com/

-}
rgb255 : Number -> Number -> Number -> Color
rgb255 r g b =
    Color.rgb255 (colorClamp r) (colorClamp g) (colorClamp b)


{-| RGB stands for Red-Green-Blue. With these three parts, you can create any
color you want. For example:

    brightBlue =
        rgb 0.1 0.6 1

    brightGreen =
        rgb 0.6 1 0.05

    brightPurple =
        rgb 0.4 0.1 0.8

For `rgb` each numer is expected to be a floating point number between 0 and 1.
Also see `rgb255`, where each number needs to be an integer between 0 and 255.

It can be hard to figure out what numbers to pick, so try using a color picker
like [paletton] to find colors that look nice together. Once you find nice
colors, click on the color previews to get their RGB values.

[paletton]: http://paletton.com/

-}
rgb : Number -> Number -> Number -> Color
rgb r g b =
    Color.rgb
        (r |> max 0 |> min 1)
        (g |> max 0 |> min 1)
        (b |> max 0 |> min 1)


colorClamp : Number -> Int
colorClamp number =
    clamp 0 255 (round number)



-- CALCULATIONS


{-| Extracts the position from any shape.
-}
center : Shape -> ( Number, Number, Number )
center (Shape x y z _ _ _ _ _ _) =
    ( x, y, z )


{-| Calculates the extent from origin (radius) of a sphere that roughly circumscribes the (group of) shape(s).
TODO: Needs a refactor where offset centers are taken into account within a group.
-}
extent : Shape -> Number
extent (Shape _ _ _ _ _ _ _ _ form) =
    case form of
        Circle _ size ->
            size

        Triangle _ size ->
            size

        Square _ size ->
            size / 2

        Rectangle _ s1 s2 ->
            max s1 s2 / 2

        Polygon _ points ->
            let
                ( ( minx, miny ), ( maxx, maxy ) ) =
                    List.foldl
                        (\( x, y ) ( ( minx1, miny1 ), ( maxx1, maxy1 ) ) ->
                            ( ( min x minx1, min y miny1 )
                            , ( max x maxx1, max y maxy1 )
                            )
                        )
                        ( ( 0, 0 ), ( 0, 0 ) )
                        points
            in
            max (maxx - minx) (maxy - miny) / 2

        Snake _ points ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max z maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            max (maxx - minx) (max (maxy - miny) (maxz - minz)) / 2

        Sphere _ size ->
            size

        Cylinder _ radius height ->
            max radius (height / 2)

        Cone _ radius height ->
            max radius (height / 2)

        Cube _ size ->
            size / 2

        Block _ w h d ->
            max w (max h d) / 2

        Prism _ size height ->
            max size height / 2

        Wall _ height points ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max z maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            max height (max (maxx - minx) (max (maxy - miny) (maxz - minz))) / 2

        Object _ points _ ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max z maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            max (maxx - minx) (max (maxy - miny) (maxz - minz)) / 2

        Words _ _ ->
            0

        Group shapes ->
            List.foldl (\s e -> max e (extent s)) 0 shapes

        Entity _ ->
            0


{-| Calculates the extents per axis of any (group of) shape(s). Extent in this case
means from the center of the object to its edge (a "radius"), so it can directly
be used in calculations from the origin of the objects.
-}
extents : Shape -> ( Number, Number, Number )
extents (Shape _ _ _ _ _ _ _ _ form) =
    case form of
        Circle _ size ->
            ( size, size, 0 )

        Triangle _ size ->
            ( size, size, 0 )

        Square _ size ->
            ( size / 2, size / 2, 0 )

        Rectangle _ s1 s2 ->
            -- This is only a very crude approximation
            ( s1 / 2, s2 / 2, 0 )

        Polygon _ points ->
            let
                ( ( minx, miny ), ( maxx, maxy ) ) =
                    List.foldl
                        (\( x, y ) ( ( minx1, miny1 ), ( maxx1, maxy1 ) ) ->
                            ( ( min x minx1, min y miny1 )
                            , ( max x maxx1, max y maxy1 )
                            )
                        )
                        ( ( 0, 0 ), ( 0, 0 ) )
                        points
            in
            ( (maxx - minx) / 2, (maxy - miny) / 2, 0 )

        Snake _ points ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max z maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            ( (maxx - minx) / 2, (maxy - miny) / 2, (maxz - minz) / 2 )

        Sphere _ size ->
            ( size, size, size )

        Cylinder _ radius height ->
            ( radius, radius, height / 2 )

        Cone _ radius height ->
            ( radius, radius, height )

        Cube _ size ->
            ( size / 2, size / 2, size / 2 )

        Block _ w h d ->
            ( w / 2, h / 2, d / 2 )

        Prism _ radius height ->
            ( radius, radius, height )

        Wall _ height points ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max (z + height) maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            ( (maxx - minx) / 2, (maxy - miny) / 2, (maxz - minz) / 2 )

        Object _ points _ ->
            let
                ( ( minx, miny, minz ), ( maxx, maxy, maxz ) ) =
                    List.foldl
                        (\( x, y, z ) ( ( minx1, miny1, minz1 ), ( maxx1, maxy1, maxz1 ) ) ->
                            ( ( min x minx1, min y miny1, min z minz1 )
                            , ( max x maxx1, max y maxy1, max z maxz1 )
                            )
                        )
                        ( ( 0, 0, 0 ), ( 0, 0, 0 ) )
                        points
            in
            ( (maxx - minx) / 2, (maxy - miny) / 2, (maxz - minz) / 2 )

        Words _ _ ->
            ( 0, 0, 0 )

        Group shapes ->
            List.foldl
                (\s ( ex, ey, ez ) ->
                    let
                        ( sx, sy, sz ) =
                            extents s
                    in
                    ( max ex sx, max ey sy, max ez sz )
                )
                ( 0, 0, 0 )
                shapes

        Entity _ ->
            ( 0, 0, 0 )



-- RENDER


type alias View =
    { position : Point3d Meters WorldCoordinates
    , orientation : Float
    , cameraMode : CameraMode
    }


render : Camera -> { screen : Screen, font : Maybe Font } -> List Shape -> Html.Html Msg
render cam { screen, font } shapes =
    Html.div
        [ Touch.onMove TouchMove
        ]
        [ Scene3d.sunny
            { camera = camera cam
            , clipDepth = Length.centimeters 0.5
            , dimensions =
                ( Pixels.int (round screen.width)
                , Pixels.int (round screen.height)
                )
            , background = Scene3d.transparentBackground
            , entities =
                case font of
                    Nothing ->
                        []

                    Just f ->
                        List.map (entityWithFont f) shapes
            , shadows = False
            , upDirection = Direction3d.y
            , sunlightDirection = Direction3d.yz (Angle.degrees -120)
            }
        ]


camera cam =
    case cam.mode of
        FirstPerson position fov ->
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.lookAt
                        { eyePoint = position
                        , focalPoint = cam.target
                        , upDirection = Direction3d.positiveZ
                        }
                , verticalFieldOfView = fov
                }

        Isometric distance height ->
            Camera3d.orthographic
                { viewpoint = Viewpoint3d.isometric { focalPoint = cam.target, distance = distance }
                , viewportHeight = height
                }

        Orbit azymuth elevation distance fov ->
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.orbit
                        { focalPoint = cam.target
                        , groundPlane = SketchPlane3d.xy
                        , azimuth = Angle.degrees azymuth
                        , elevation = Angle.degrees elevation
                        , distance = Length.centimeters distance
                        }
                , verticalFieldOfView = fov
                }


withColor : Color -> Mesh WorldCoordinates { a | normals : () } -> Entity WorldCoordinates
withColor color =
    withMaterial { color = color, roughness = 0.4 }


withMaterial : { color : Color, roughness : Number } -> Mesh WorldCoordinates { a | normals : () } -> Entity WorldCoordinates
withMaterial { color, roughness } =
    Scene3d.mesh (material color roughness)


material color roughness =
    Material.nonmetal
        { baseColor = color
        , roughness = roughness
        }


{-| Add a 3D shape to a Scene3D scene as an entity.
-}
entity : Shape -> Entity WorldCoordinates
entity (Shape x y z rr rp ry s alpha form) =
    renderForm Nothing form
        |> transform { x = x, y = y, z = z } { x = rr, y = rp, z = ry } s


entityWithFont : Font -> Shape -> Entity WorldCoordinates
entityWithFont font (Shape x y z rr rp ry s alpha form) =
    renderForm (Just font) form
        |> transform { x = x, y = y, z = z } { x = rr, y = rp, z = ry } s


renderForm : Maybe Font -> Form -> Entity WorldCoordinates
renderForm font form =
    case form of
        Group shapes ->
            renderGroup font shapes

        Circle color radius ->
            renderCircle color radius

        Cylinder color radius height ->
            renderCylinder { color = color, roughness = 0.4 } radius height

        Cone color radius height ->
            renderCone { color = color, roughness = 0.4 } radius height

        Triangle color size ->
            renderTriangle color size

        Square color size ->
            renderRectangle color size size

        Rectangle color width height ->
            renderRectangle color width height

        Polygon color points ->
            renderPolygon color points

        Snake color points ->
            renderSnake color points

        Sphere color radius ->
            renderSphere { color = color, roughness = 0.4 } radius

        Cube color size ->
            renderBlock { color = color, roughness = 0.4 } size size size

        Block color width height depth ->
            renderBlock { color = color, roughness = 0.4 } width height depth

        Prism color size height ->
            renderPrism color size height

        Wall color height points ->
            renderWall color height points

        Words color string ->
            case font of
                Nothing ->
                    renderGroup Nothing []

                Just f ->
                    renderWords f color string

        Object color vertices faces ->
            renderObject color vertices faces

        Entity e ->
            e



--ExtrudedPolygon color height points ->
--    renderExtrudedPolygon color height points
-- RENDER GROUP


renderGroup : Maybe Font -> List Shape -> Entity WorldCoordinates
renderGroup font shapes =
    case font of
        Nothing ->
            shapes
                |> List.map entity
                |> Scene3d.group

        Just f ->
            shapes
                |> List.map (entityWithFont f)
                |> Scene3d.group



-- RENDER CIRCLE AND OVAL


renderCircle : Color -> Number -> Entity WorldCoordinates
renderCircle color radius =
    Shape.circle (radius / 100)
        |> withColor color


renderCylinder : Material -> Number -> Number -> Entity WorldCoordinates
renderCylinder { color, roughness } radius height =
    Cylinder3d.centeredOn Point3d.origin
        Direction3d.z
        { radius = Length.centimeters radius
        , length = Length.centimeters height
        }
        |> Scene3d.cylinder (material color roughness)


renderCone : Material -> Number -> Number -> Entity WorldCoordinates
renderCone { color, roughness } radius height =
    Cone3d.along Axis3d.z
        { base = Length.centimeters 0
        , tip = Length.centimeters height
        , radius = Length.centimeters radius
        }
        |> Scene3d.cone (material color roughness)


renderTriangle : Color -> Number -> Entity WorldCoordinates
renderTriangle color s =
    Shape.triangle (s / 100)
        |> withColor color



-- RENDER RECTANGLE AND IMAGE


renderRectangle : Color -> Number -> Number -> Entity WorldCoordinates
renderRectangle color w h =
    Shape.rectangle (w / 100) (h / 100)
        |> withColor color



-- RENDER POLYGON


renderPolygon : Color -> List ( Number, Number ) -> Entity WorldCoordinates
renderPolygon color points =
    points
        |> Array.fromList
        |> Array.map (\( x, y ) -> Point2d.centimeters x y)
        |> DelaunayTriangulation2d.fromPoints
        |> Result.map
            (DelaunayTriangulation2d.toMesh
                >> TriangularMesh.mapVertices (Point2d.coordinates >> (\( x, y ) -> Point3d.xyOn SketchPlane3d.xy x y))
                >> Scene3d.Mesh.indexedFacets
                >> withColor color
            )
        |> Result.withDefault (renderSnake color (points |> List.map (\( x, y ) -> ( x, y, 0 ))))



--renderExtrudedPolygon : Color -> Number -> List (Number, Number) -> Entity WorldCoordinates


addPoint : ( Float, Float ) -> String -> String
addPoint ( x, y ) str =
    str ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ " "



-- RENDER SPHERE


renderSphere : Material -> Number -> Entity WorldCoordinates
renderSphere { color, roughness } radius =
    Sphere3d.withRadius (Length.centimeters radius) Point3d.origin
        |> Scene3d.sphere (material color roughness)



-- RENDER BLOCK


renderBlock : Material -> Number -> Number -> Number -> Entity WorldCoordinates
renderBlock { color, roughness } w h d =
    let
        rw =
            w / 2

        rh =
            h / 2

        rd =
            d / 2
    in
    Block3d.with
        { x1 = Length.centimeters -rw
        , x2 = Length.centimeters rw
        , y1 = Length.centimeters -rh
        , y2 = Length.centimeters rh
        , z1 = Length.centimeters -rd
        , z2 = Length.centimeters rd
        }
        |> Scene3d.block (material color roughness)



-- RENDER SNAKE


renderSnake : Color -> List ( Number, Number, Number ) -> Entity WorldCoordinates
renderSnake color points =
    points
        |> List.map (\( x, y, z ) -> Point3d.centimeters x y z)
        |> Polyline3d.fromVertices
        |> Scene3d.Mesh.polyline
        |> Scene3d.mesh (Material.color color)



-- RENDER PRISM


renderPrism : Color -> Number -> Number -> Entity WorldCoordinates
renderPrism color size height =
    let
        s =
            size / 100

        h =
            height / 100

        negativeZVector =
            Direction3d.negativeZ |> Direction3d.toVector

        positiveZVector =
            Direction3d.positiveZ |> Direction3d.toVector

        p1 =
            Point3d.unsafe { x = 0, y = s, z = 0 }

        p2 =
            Point3d.unsafe { x = s * sin (2 / 3 * pi), y = s * cos (2 / 3 * pi), z = 0 }

        p3 =
            Point3d.unsafe { x = s * sin (4 / 3 * pi), y = s * cos (4 / 3 * pi), z = 0 }

        p4 =
            Point3d.unsafe { x = 0, y = s, z = h }

        p5 =
            Point3d.unsafe { x = s * sin (2 / 3 * pi), y = s * cos (2 / 3 * pi), z = h }

        p6 =
            Point3d.unsafe { x = s * sin (4 / 3 * pi), y = s * cos (4 / 3 * pi), z = h }

        triangleBottom =
            [ ( p1, p2, p3 ) ]

        triangleTop =
            [ ( p6, p5, p4 ) ]

        side1 =
            [ ( p2, p1, p5 ), ( p1, p4, p5 ) ]

        side2 =
            [ ( p3, p2, p6 ), ( p2, p5, p6 ) ]

        side3 =
            [ ( p1, p3, p4 ), ( p3, p6, p4 ) ]

        triangularMesh =
            TriangularMesh.triangles (List.concat [ triangleTop, side1, side2, side3, triangleBottom ])
    in
    Scene3d.Mesh.indexedFacets triangularMesh
        |> Scene3d.Mesh.cullBackFaces
        |> withColor color



-- RENDER WALL


renderWall : Color -> Number -> List ( Number, Number, Number ) -> Entity WorldCoordinates
renderWall color height points =
    TriangularMesh.strip
        (points
            |> List.map (\( x, y, z ) -> Point3d.centimeters x y (z - height / 2))
        )
        (points
            |> List.map (\( x, y, z ) -> Point3d.centimeters x y (z + height / 2))
        )
        |> Scene3d.Mesh.indexedFacets
        |> withColor color



-- RENDER OBJECT


renderObject : Color -> List ( Number, Number, Number ) -> List ( Int, Int, Int ) -> Entity WorldCoordinates
renderObject color vertices faces =
    let
        vertexToPoint ( x, y, z ) =
            Point3d.centimeters x y z

        faceNullBased : ( Int, Int, Int ) -> ( Int, Int, Int )
        faceNullBased ( i, j, k ) =
            ( i - 1, j - 1, k - 1 )
    in
    TriangularMesh.indexed (vertices |> List.map vertexToPoint |> Array.fromList) (faces |> List.map faceNullBased)
        |> Scene3d.Mesh.indexedFacets
        |> withColor color



-- RENDER WORDS


renderWords : Font -> Color -> String -> Entity WorldCoordinates
renderWords font color text =
    Scene3d.Mesh.texturedFacets (mesh text)
        |> Scene3d.mesh (Material.texturedColor font)


mesh =
    MogeeFont.text addLetter >> TriangularMesh.triangles


type alias Vertex a =
    { position : Point3d Meters a
    , uv : ( Float, Float )
    }


addLetter : MogeeFont.Letter -> List ( Vertex a, Vertex a, Vertex a )
addLetter { x, y, width, height, textureX, textureY } =
    let
        tscale ( tx, ty ) =
            ( tx / 128, 1 - ty / 128 )
    in
    [ ( { position = Point3d.centimeters x y 0, uv = tscale ( textureX, textureY + height ) }
      , { position = Point3d.centimeters (x + width) (y + height) 0, uv = tscale ( textureX + width, textureY ) }
      , { position = Point3d.centimeters (x + width) y 0, uv = tscale ( textureX + width, textureY + height ) }
      )
    , ( { position = Point3d.centimeters x y 0, uv = tscale ( textureX, textureY + height ) }
      , { position = Point3d.centimeters x (y + height) 0, uv = tscale ( textureX, textureY ) }
      , { position = Point3d.centimeters (x + width) (y + height) 0, uv = tscale ( textureX + width, textureY ) }
      )
    ]



-- RENDER TRANSFORMS


type alias Translation =
    { x : Number
    , y : Number
    , z : Number
    }


type alias Rotation =
    { x : Number
    , y : Number
    , z : Number
    }


type alias Scale =
    Number


type alias Material =
    { color : Color, roughness : Number }


transform : Translation -> Rotation -> Scale -> Entity WorldCoordinates -> Entity WorldCoordinates
transform t r s =
    Scene3d.rotateAround Axis3d.x (Angle.degrees r.x)
        >> Scene3d.rotateAround Axis3d.y (Angle.degrees r.y)
        >> Scene3d.rotateAround Axis3d.z (Angle.degrees r.z)
        >> Scene3d.scaleAbout Point3d.origin s
        >> Scene3d.translateBy (Vector3d.centimeters t.x t.y t.z)
