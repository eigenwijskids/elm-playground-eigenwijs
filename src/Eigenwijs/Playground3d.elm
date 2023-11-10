module Eigenwijs.Playground3d exposing
    ( picture, animation, game
    , Shape, circle, triangle, square, rectangle
    , sphere, cylinder, cube, block
    , move, moveX, moveY, moveZ
    , scale, rotate, roll, pitch, yaw, fade
    , group, extrude, pullUp
    , Time, spin, wave, zigzag, beginOfTime
    , Computer, Mouse, Screen, Keyboard, toX, toY, toXY
    , rgb, rgb255, red, orange, yellow, green, blue, purple, brown
    , lightRed, lightOrange, lightYellow, lightGreen, lightBlue, lightPurple, lightBrown
    , darkRed, darkOrange, darkYellow, darkGreen, darkBlue, darkPurple, darkBrown
    , white, lightGrey, grey, darkGrey, lightCharcoal, charcoal, darkCharcoal, black
    , lightGray, gray, darkGray
    , Number
    , pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture
    , animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg
    , gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg
    , entity
    )

{-| **Beware that this is a project under heavy construction** - We are trying to
incrementally work towards a library enabling folks familiar with the 2D
Playground, to add 3D elements to a 3D scene, and in this way enabling them to
contribute to a collaboratively developed game.


# Playgrounds

@docs picture, animation, game


# Shapes

@docs Shape, circle, oval, triangle, square, rectangle, triangle, pentagon, hexagon, octagon, polygon


# 3D Shapes

@docs sphere, cylinder, cube, block


# Words

@docs words


# Images

@docs image


# Move Shapes

@docs move, moveUp, moveDown, moveLeft, moveRight, moveForward, moveBackward, moveX, moveY, moveZ


# Customize Shapes

@docs scale, rotate, roll, pitch, yaw, fade


# Groups and extrusion

@docs group, extrude, pullUp


# Time

@docs Time, spin, wave, zigzag, beginOfTime


# Computer

@docs Computer, Mouse, Screen, Keyboard, toX, toY, toXY


# Colors

@docs Color, rgb, rgb255, red, orange, yellow, green, blue, purple, brown


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


# Playground Picture embeds

@docs pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture, PictureMsg


# Playground Animation embeds

@docs animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg


# Playground Game embeds

@docs gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg

-}

import Angle exposing (Angle)
import Axis3d exposing (Axis3d)
import Block3d
import Browser
import Browser.Dom as Dom
import Browser.Events as E
import Camera3d exposing (Camera3d)
import Color exposing (..)
import Cylinder3d
import Direction3d exposing (Direction3d)
import Eigenwijs.Playground3d.Shape as Shape
import Html
import Html.Attributes as H
import Json.Decode as D
import Length exposing (Meters, centimeters, meters)
import Physics.Body as Body exposing (Body)
import Physics.Coordinates exposing (BodyCoordinates, WorldCoordinates)
import Physics.World as World exposing (World)
import Pixels exposing (Pixels, pixels)
import Point3d exposing (Point3d)
import Scene3d exposing (Entity, group)
import Scene3d.Material as Material exposing (Material)
import Scene3d.Mesh exposing (Mesh)
import Set
import SketchPlane3d
import Sphere3d
import Task
import Time
import Vector3d
import Viewpoint3d exposing (Viewpoint3d)



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
    Screen


{-| Picture init function
-}
pictureInit : () -> ( Picture, Cmd Msg )
pictureInit () =
    ( toScreen 600 600
    , Task.perform GotViewport Dom.getViewport
    )


{-| Picture view function
-}
pictureView : Picture -> List Shape -> Html.Html Msg
pictureView =
    render orthographic


{-| Picture update function
-}
pictureUpdate : Msg -> Picture -> ( Picture, Cmd Msg )
pictureUpdate msg p =
    case msg of
        GotViewport { viewport } ->
            ( toScreen viewport.width viewport.height
            , Cmd.none
            )

        Resized w h ->
            ( toScreen (toFloat w) (toFloat h)
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
    { mouse : Mouse
    , keyboard : Keyboard
    , screen : Screen
    , time : Time
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

        subscriptions (Animation visibility _ _) =
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
    = Animation E.Visibility Screen Time


{-| Animation init
-}
animationInit : () -> ( Animation, Cmd Msg )
animationInit () =
    ( Animation E.Visible (toScreen 600 600) (Time (Time.millisToPosix 0))
    , Task.perform GotViewport Dom.getViewport
    )


{-| Animation view
-}
animationView : Animation -> (Time -> List Shape) -> Html.Html Msg
animationView (Animation _ screen time) viewFrame =
    render
        (camera Point3d.origin 0 ThirdPerson)
        screen
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
animationUpdate msg ((Animation v s t) as state) =
    case msg of
        Tick posix ->
            Animation v s (Time posix)

        VisibilityChanged vis ->
            Animation vis s t

        GotViewport { viewport } ->
            Animation v (toScreen viewport.width viewport.height) t

        Resized w h ->
            Animation v (toScreen (toFloat w) (toFloat h)) t

        KeyChanged _ _ ->
            state

        MouseMove _ _ ->
            state

        MouseClick ->
            state

        MouseButton _ ->
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
game viewMemory updateMemory initialMemory =
    let
        view model =
            { title = "Playground"
            , body = [ gameView viewMemory model ]
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


initialComputer : Computer
initialComputer =
    { mouse = Mouse 0 0 False False
    , keyboard = emptyKeyboard
    , screen = toScreen 600 600
    , time = beginOfTime
    }


{-| Game init function
-}
gameInit : memory -> () -> ( Game memory, Cmd Msg )
gameInit initialMemory () =
    ( Game E.Visible initialMemory initialComputer
    , Task.perform GotViewport Dom.getViewport
    )


{-| Game view function
-}
gameView : (Computer -> memory -> List Shape) -> Game memory -> Html.Html Msg
gameView viewMemory (Game _ memory computer) =
    render
        (camera Point3d.origin 0 ThirdPerson)
        computer.screen
        (viewMemory computer memory)



-- SUBSCRIPTIONS


{-| Game subscriptions
-}
gameSubscriptions : Game memory -> Sub Msg
gameSubscriptions (Game visibility _ _) =
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
    = Game E.Visibility memory Computer


{-| Animation message alias
-}
type alias AnimationMsg =
    Msg


{-| Game message alias
-}
type alias GameMsg =
    Msg


{-| Camera Mode type
-}
type CameraMode
    = ThirdPerson
    | FirstPerson


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


{-| Game update function
-}
gameUpdate : (Computer -> memory -> memory) -> Msg -> Game memory -> Game memory
gameUpdate updateMemory msg (Game vis memory computer) =
    case msg of
        Tick time ->
            Game vis (updateMemory computer memory) <|
                if computer.mouse.click then
                    { computer | time = Time time, mouse = mouseClick False computer.mouse }

                else
                    { computer | time = Time time }

        GotViewport { viewport } ->
            Game vis memory { computer | screen = toScreen viewport.width viewport.height }

        Resized w h ->
            Game vis memory { computer | screen = toScreen (toFloat w) (toFloat h) }

        KeyChanged isDown key ->
            Game vis memory { computer | keyboard = updateKeyboard isDown key computer.keyboard }

        MouseMove pageX pageY ->
            let
                x =
                    computer.screen.left + pageX

                y =
                    computer.screen.top - pageY
            in
            Game vis memory { computer | mouse = mouseMove x y computer.mouse }

        MouseClick ->
            Game vis memory { computer | mouse = mouseClick True computer.mouse }

        MouseButton isDown ->
            Game vis memory { computer | mouse = mouseDown isDown computer.mouse }

        VisibilityChanged visibility ->
            Game visibility
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
      --| Snake Color (List (Number, Number))
    | Sphere Color Number
    | Cylinder Color Number Number
    | Cube Color Number
    | Block Color Number Number Number


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


cylinder : Color -> Number -> Number -> Shape
cylinder color radius height =
    Shape 0 0 0 0 0 0 1 1 (Cylinder color radius height)


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


extrude h shape =
    case shape of
        Shape x y z rr rp ry s a (Circle c r) ->
            Shape x y z rr rp ry s a (Cylinder c r h)

        Shape x y z rr rp ry s a (Square c r) ->
            if h == r then
                Shape x y z rr rp ry s a (Cube c r)

            else
                Shape x y z rr rp ry s a (Block c r r h)

        Shape x y z rr rp ry s a (Rectangle c wb hb) ->
            Shape x y z rr rp ry s a (Block c wb hb h)

        _ ->
            shape


pullUp h shape =
    case shape of
        Shape x y z rr rp ry s a (Circle c r) ->
            Shape x y (z + h / 2) rr rp ry s a (Cylinder c r h)

        Shape x y z rr rp ry s a (Square c r) ->
            if h == r then
                Shape x y (z + h / 2) rr rp ry s a (Cube c r)

            else
                Shape x y (z + h / 2) rr rp ry s a (Block c r r h)

        Shape x y z rr rp ry s a (Rectangle c wb hb) ->
            Shape x y (z + h / 2) rr rp ry s a (Block c wb hb h)

        _ ->
            shape



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
            [ words black "These words are tilted!"
                |> rotate 10
            ]

The degrees go **counter-clockwise** to match the direction of the
[unit circle](https://en.wikipedia.org/wiki/Unit_circle).

-}
rotate : Number -> Shape -> Shape
rotate da (Shape x y z rr rp ry s o f) =
    Shape x y z (rr + da) rp ry s o f


roll : Number -> Shape -> Shape
roll dr (Shape x y z rr rp ry s o f) =
    Shape x y z (rr + dr) rp ry s o f


pitch : Number -> Shape -> Shape
pitch dp (Shape x y z rr rp ry s o f) =
    Shape x y z rr (rp + dp) ry s o f


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

For rgb255 each number needs to be an integer between 0 and 255.
For rgb each numer is expected to be a floating point number between 0 and 1.

It can be hard to figure out what numbers to pick, so try using a color picker
like [paletton] to find colors that look nice together. Once you find nice
colors, click on the color previews to get their RGB values.

[paletton]: http://paletton.com/

-}
rgb255 : Number -> Number -> Number -> Color
rgb255 r g b =
    Color.rgb255 (colorClamp r) (colorClamp g) (colorClamp b)


rgb : Number -> Number -> Number -> Color
rgb r g b =
    Color.rgb
        (r |> min 0 |> max 1)
        (g |> min 0 |> max 1)
        (b |> min 0 |> max 1)


colorClamp : Number -> Int
colorClamp number =
    clamp 0 255 (round number)



-- RENDER


type alias View =
    { position : Point3d Meters WorldCoordinates
    , orientation : Float
    , cameraMode : CameraMode
    }


render : Camera3d Meters WorldCoordinates -> Screen -> List Shape -> Html.Html msg
render cam screen shapes =
    Scene3d.sunny
        { camera = cam
        , clipDepth = Length.centimeters 0.5
        , dimensions =
            ( Pixels.int (round screen.width)
            , Pixels.int (round screen.height)
            )
        , background = Scene3d.transparentBackground
        , entities = List.map entity shapes
        , shadows = False
        , upDirection = Direction3d.y
        , sunlightDirection = Direction3d.yz (Angle.degrees -120)
        }


orthographic =
    Camera3d.orthographic
        { viewpoint = Viewpoint3d.isometric { focalPoint = Point3d.origin, distance = Length.meters 10 }
        , viewportHeight = Length.meters 5
        }


camera doel draaiHoek modus =
    Camera3d.perspective
        { viewpoint =
            Viewpoint3d.orbit
                { focalPoint =
                    doel
                        |> Point3d.translateIn Direction3d.z (Length.meters 2)
                , groundPlane = SketchPlane3d.xy
                , azimuth = Angle.degrees draaiHoek
                , elevation = Angle.degrees 15
                , distance =
                    case modus of
                        ThirdPerson ->
                            Length.meters 3

                        FirstPerson ->
                            Length.meters 0
                }
        , verticalFieldOfView = Angle.degrees 60
        }


withColor : Color -> Mesh coordinates { a | normals : () } -> Entity coordinates
withColor color =
    Scene3d.mesh (material color)


material color =
    Material.nonmetal
        { baseColor = color
        , roughness = 0.4
        }


entity : Shape -> Entity WorldCoordinates
entity (Shape x y z rr rp ry s alpha form) =
    renderForm form
        |> transform { x = x, y = y, z = z } { x = rr, y = rp, z = ry } s


renderForm : Form -> Entity WorldCoordinates
renderForm form =
    case form of
        Group shapes ->
            renderGroup shapes

        Circle color radius ->
            renderCircle color radius

        Cylinder color radius height ->
            renderCylinder color radius height

        Triangle color size ->
            renderTriangle color size

        Square color size ->
            renderRectangle color size size

        Rectangle color width height ->
            renderRectangle color width height

        Sphere color radius ->
            renderSphere color radius

        Cube color size ->
            renderBlock color size size size

        Block color width height depth ->
            renderBlock color width height depth



-- RENDER GROUP


renderGroup : List Shape -> Entity WorldCoordinates
renderGroup shapes =
    shapes
        |> List.map entity
        |> Scene3d.group



-- RENDER CIRCLE AND OVAL


renderCircle : Color -> Number -> Entity coordinates
renderCircle color radius =
    Shape.circle (radius / 100)
        |> withColor color


renderCylinder : Color -> Number -> Number -> Entity coordinates
renderCylinder color radius height =
    Cylinder3d.centeredOn Point3d.origin
        Direction3d.z
        { radius = Length.centimeters radius
        , length = Length.centimeters height
        }
        |> Scene3d.cylinder (material color)


renderTriangle : Color -> Number -> Entity coordinates
renderTriangle color s =
    Shape.triangle (s / 100)
        |> withColor color



-- RENDER RECTANGLE AND IMAGE


renderRectangle : Color -> Number -> Number -> Entity coordinates
renderRectangle color w h =
    Shape.rectangle (w / 100) (h / 100)
        |> withColor color



-- RENDER SPHERE


renderSphere : Color -> Number -> Entity coordinates
renderSphere color radius =
    Sphere3d.withRadius (Length.centimeters radius) Point3d.origin
        |> Scene3d.sphere (material color)



-- RENDER BLOCK


renderBlock : Color -> Number -> Number -> Number -> Entity coordinates
renderBlock color w h d =
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
        |> Scene3d.block (material color)



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


transform : Translation -> Rotation -> Scale -> Entity coordinates -> Entity coordinates
transform t r s =
    Scene3d.rotateAround Axis3d.x (Angle.degrees r.x)
        >> Scene3d.rotateAround Axis3d.y (Angle.degrees r.y)
        >> Scene3d.rotateAround Axis3d.z (Angle.degrees r.z)
        >> Scene3d.scaleAbout Point3d.origin s
        >> Scene3d.translateBy (Vector3d.centimeters t.x t.y t.z)
