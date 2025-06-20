module Eigenwijs.Playground exposing
    ( picture, animation, game
    , Shape, circle, oval, square, rectangle, triangle, pentagon, hexagon, octagon, polygon
    , lineBetween, line, svgPath
    , withOutline, withStroke, withFill
    , words, withFont
    , image
    , move, moveUp, moveDown, moveLeft, moveRight, moveX, moveY, moveAlong, moveAlongLoop
    , scale, scaleX, scaleY, rotate, fade
    , withName, clickedName, nameOf
    , group
    , Time, spin, wave, zigzag, beginOfTime
    , Computer, Mouse, Screen, Keyboard, toX, toY, toXY
    , Color, rgb, transparent, red, orange, yellow, green, blue, purple, brown
    , lightRed, lightOrange, lightYellow, lightGreen, lightBlue, lightPurple, lightBrown
    , darkRed, darkOrange, darkYellow, darkGreen, darkBlue, darkPurple, darkBrown
    , white, lightGrey, grey, darkGrey, lightCharcoal, charcoal, darkCharcoal, black
    , lightGray, gray, darkGray
    , Number
    , gameWithAudio, AudioPort
    , pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture, PictureMsg
    , animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg
    , gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg
    , center, extent, distanceTo, collidesWith, containsPoint, toPolygon
    , verticesOf, pointsOf, positionOf, scaleOf, rotationOf
    , pathFromCommands, forward, turn, turnTo
    )

{-|


# Playgrounds

@docs picture, animation, game


# Shapes

@docs Shape, circle, oval, square, rectangle, triangle, pentagon, hexagon, octagon, polygon
@docs lineBetween, line, svgPath


# Style

@docs withOutline, withStroke, withFill


# Words

@docs words, withFont


# Images

@docs image


# Move Shapes

@docs move, moveUp, moveDown, moveLeft, moveRight, moveX, moveY, moveAlong, moveAlongLoop


# Customize Shapes

@docs scale, scaleX, scaleY, rotate, fade


# Named Shapes

@docs withName, nameOf, clickedName


# Groups

@docs group


# Time

@docs Time, spin, wave, zigzag, beginOfTime


# Computer

@docs Computer, Mouse, Screen, Keyboard, toX, toY, toXY


# Colors

@docs Color, rgb, transparent, red, orange, yellow, green, blue, purple, brown


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


# Audio

@docs gameWithAudio, AudioPort


# Playground Picture embeds

@docs pictureInit, pictureView, pictureUpdate, pictureSubscriptions, Picture, PictureMsg


# Playground Animation embeds

@docs animationInit, animationView, animationUpdate, animationSubscriptions, Animation, AnimationMsg


# Playground Game embeds

@docs gameInit, gameView, gameUpdate, gameSubscriptions, Game, GameMsg


# Calculations

@docs center, extent, distanceTo, collidesWith, containsPoint, toPolygon
@docs verticesOf, pointsOf, positionOf, scaleOf, rotationOf


# Generating lists of coordinates (paths)

@docs pathFromCommands, forward, turn, turnTo

-}

import Angle
import Browser
import Browser.Dom as Dom
import Browser.Events as E
import Html
import Html.Attributes as H
import Json.Decode as D
import Json.Encode
import Point2d
import Polygon2d exposing (Polygon2d)
import Quantity exposing (Unitless)
import Set
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events
import Task
import Time
import Vector2d
import WebAudio
import WebAudio.Property



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
picture : List (Shape PictureMsg) -> Program () Picture PictureMsg
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


{-| Picture message type
-}
type alias PictureMsg =
    ( Int, Int )


{-| Picture init function
-}
pictureInit : () -> ( Picture, Cmd PictureMsg )
pictureInit () =
    ( toScreen 600 600, Cmd.none )


{-| Picture view function
-}
pictureView : Picture -> List (Shape PictureMsg) -> Html.Html PictureMsg
pictureView =
    render


{-| Picture update function
-}
pictureUpdate : PictureMsg -> Picture -> ( Picture, Cmd PictureMsg )
pictureUpdate ( width, height ) _ =
    ( toScreen (toFloat width) (toFloat height)
    , Cmd.none
    )


{-| Picture subscriptions
-}
pictureSubscriptions : Picture -> Sub PictureMsg
pictureSubscriptions _ =
    E.onResize Tuple.pair



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
while the mouse button is down, or ask for `computer.mouse.clickedNames`
to see which named shapes are clicked.

-}
type alias Mouse =
    { x : Number
    , y : Number
    , down : Bool
    , click : Bool
    , clickedNames : List String
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
animation : (Time -> List (Shape Msg)) -> Program () Animation Msg
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
animationView : Animation -> (Time -> List (Shape Msg)) -> Html.Html Msg
animationView (Animation _ screen time) viewFrame =
    render screen (viewFrame time)


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

        ClickedName _ ->
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
game : (Computer -> memory -> List (Shape Msg)) -> (Computer -> memory -> memory) -> memory -> Program () (Game memory) Msg
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
    { mouse = Mouse 0 0 False False []
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
gameView : (Computer -> memory -> List (Shape Msg)) -> Game memory -> Html.Html Msg
gameView viewMemory (Game _ memory computer) =
    render computer.screen (viewMemory computer memory)



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
    | ClickedName String


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
                    , mouse = Mouse computer.mouse.x computer.mouse.y False False []
                }

        ClickedName n ->
            let
                mouse =
                    computer.mouse
            in
            Game vis
                memory
                { computer
                    | keyboard = emptyKeyboard
                    , mouse = { mouse | clickedNames = n :: mouse.clickedNames }
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
    if bool then
        { mouse | click = True }

    else
        { mouse | click = False, clickedNames = [] }


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
type Shape msg
    = Shape
        Number
        -- x
        Number
        -- y
        Number
        -- angle
        Number
        -- scale width
        Number
        -- scale height
        Number
        -- alpha
        (Maybe msg)
        -- message to send on click (to make the shape clickable and identifiable)
        (Form msg)


type Form msg
    = Circle Color Outline Number
    | Oval Color Outline Number Number
    | Rectangle Color Outline Number Number
    | Ngon Color Outline Int Number
    | Polygon Color Outline (List ( Number, Number ))
    | Image Number Number String
    | SvgPath Color Outline String
    | Words Color Outline Font String
    | Group (List (Shape msg))


type alias Font =
    Maybe String


type Outline
    = NoOutline
    | Outline Color Float


{-| Add an outline to shapes with specified color and thickness.
-}
withOutline : Color -> Float -> Shape msg -> Shape msg
withOutline color thickness ((Shape x y a sx sy o n f) as shape) =
    case f of
        Circle c _ r ->
            Shape x y a sx sy o n (Circle c (Outline color thickness) r)

        Oval c _ w h ->
            Shape x y a sx sy o n (Oval c (Outline color thickness) w h)

        Rectangle c _ w h ->
            Shape x y a sx sy o n (Rectangle c (Outline color thickness) w h)

        Ngon c _ i s ->
            Shape x y a sx sy o n (Ngon c (Outline color thickness) i s)

        Polygon c _ cs ->
            Shape x y a sx sy o n (Polygon c (Outline color thickness) cs)

        Words c _ ff t ->
            Shape x y a sx sy o n (Words c (Outline color thickness) ff t)

        SvgPath c _ s ->
            Shape x y a sx sy o n (SvgPath c (Outline color thickness) s)

        _ ->
            shape


{-| Add an outline to shapes with specified color and thickness.
-}
withStroke : Color -> Float -> Shape msg -> Shape msg
withStroke =
    withOutline


{-| Change the fill color of a shape. This also enables you to add a fill color
to a line or svgPath shape.
-}
withFill : Color -> Shape msg -> Shape msg
withFill color ((Shape x y a sx sy o n f) as shape) =
    case f of
        Circle _ l r ->
            Shape x y a sx sy o n (Circle color l r)

        Oval _ l w h ->
            Shape x y a sx sy o n (Oval color l w h)

        Rectangle _ l w h ->
            Shape x y a sx sy o n (Rectangle color l w h)

        Ngon _ l i s ->
            Shape x y a sx sy o n (Ngon color l i s)

        Polygon _ l cs ->
            Shape x y a sx sy o n (Polygon color l cs)

        Words _ l ff t ->
            Shape x y a sx sy o n (Words color l ff t)

        SvgPath _ l s ->
            Shape x y a sx sy o n (SvgPath color l s)

        _ ->
            shape


{-| Make circles:

    dot =
        circle red 10

    sun =
        circle yellow 300

You give a color and then the radius. So the higher the number, the larger
the circle.

-}
circle : Color -> Number -> Shape msg
circle color radius =
    Shape 0 0 0 1 1 1 Nothing (Circle color NoOutline radius)


{-| Make ovals:

    football =
        oval brown 200 100

You give the color, and then the width and height. So our `football` example
is 200 pixels wide and 100 pixels tall.

-}
oval : Color -> Number -> Number -> Shape msg
oval color width height =
    Shape 0 0 0 1 1 1 Nothing (Oval color NoOutline width height)


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
square : Color -> Number -> Shape msg
square color n =
    Shape 0 0 0 1 1 1 Nothing (Rectangle color NoOutline n n)


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
rectangle : Color -> Number -> Number -> Shape msg
rectangle color width height =
    Shape 0 0 0 1 1 1 Nothing (Rectangle color NoOutline width height)


{-| Make triangles. So if you wanted to draw the Egyptian pyramids, you could
do a simple version like this:

    import Playground exposing (..)

    main =
        picture
            [ triangle darkYellow 200
            ]

The number is the "radius", so the distance from the center to each point of
the pyramid is `200`. Pretty big!

-}
triangle : Color -> Number -> Shape msg
triangle color radius =
    Shape 0 0 0 1 1 1 Nothing (Ngon color NoOutline 3 radius)


{-| Make pentagons:

    import Playground exposing (..)

    main =
        picture
            [ pentagon darkGrey 100
            ]

You give the color and then the radius. So the distance from the center to each
of the five points is 100 pixels.

-}
pentagon : Color -> Number -> Shape msg
pentagon color radius =
    Shape 0 0 0 1 1 1 Nothing (Ngon color NoOutline 5 radius)


{-| Make hexagons:

    import Playground exposing (..)

    main =
        picture
            [ hexagon lightYellow 50
            ]

The number is the radius, the distance from the center to each point.

If you made more hexagons, you could [`move`](#move) them around to make a
honeycomb pattern!

-}
hexagon : Color -> Number -> Shape msg
hexagon color radius =
    Shape 0 0 0 1 1 1 Nothing (Ngon color NoOutline 6 radius)


{-| Make octogons:

    import Playground exposing (..)

    main =
        picture
            [ octagon red 100
            ]

You give the color and radius, so each point of this stop sign is 100 pixels
from the center.

-}
octagon : Color -> Number -> Shape msg
octagon color radius =
    Shape 0 0 0 1 1 1 Nothing (Ngon color NoOutline 8 radius)


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
polygon : Color -> List ( Number, Number ) -> Shape msg
polygon color points =
    Shape 0 0 0 1 1 1 Nothing (Polygon color NoOutline points)


{-| Add some image from the internet:

    import Playground exposing (..)

    main =
        picture
            [ image 96 96 "https://elm-lang.org/images/turtle.gif"
            ]

You provide the width, height, and then the URL of the image you want to show.

-}
image : Number -> Number -> String -> Shape msg
image w h src =
    Shape 0 0 0 1 1 1 Nothing (Image w h src)


{-| Show some words!

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello! How are you?"
            ]

You can use [`scale`](#scale) to make the words bigger or smaller.

-}
words : Color -> String -> Shape msg
words color string =
    Shape 0 0 0 1 1 1 Nothing (Words color NoOutline Nothing string)


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
group : List (Shape msg) -> Shape msg
group shapes =
    Shape 0 0 0 1 1 1 Nothing (Group shapes)



-- TRANSFORMS


{-| Move a shape by some number of pixels:

    import Playground exposing (..)

    main =
        picture
            [ square red 100
                |> move -60 60
            , square yellow 100
                |> move 60 60
            , square green 100
                |> move 60 -60
            , square blue 100
                |> move -60 -60
            ]

-}
move : Number -> Number -> Shape msg -> Shape msg
move dx dy (Shape x y a sx sy o n f) =
    Shape (x + dx) (y + dy) a sx sy o n f


{-| Move a shape up by some number of pixels. So if you wanted to make a tree
you could move the leaves up above the trunk:

    import Playground exposing (..)

    main =
        picture
            [ rectangle brown 40 200
            , circle green 100
                |> moveUp 180
            ]

-}
moveUp : Number -> Shape msg -> Shape msg
moveUp =
    moveY


{-| Move a shape down by some number of pixels. So if you wanted to put the sky
above the ground, you could move the sky up and the ground down:

    import Playground exposing (..)

    main =
        picture
            [ rectangle lightBlue 200 100
                |> moveUp 50
            , rectangle lightGreen 200 100
                |> moveDown 50
            ]

-}
moveDown : Number -> Shape msg -> Shape msg
moveDown dy (Shape x y a sx sy o n f) =
    Shape x (y - dy) a sx sy o n f


{-| Move shapes to the left.

    import Playground exposing (..)

    main =
        picture
            [ circle yellow 10
                |> moveLeft 80
                |> moveUp 30
            ]

-}
moveLeft : Number -> Shape msg -> Shape msg
moveLeft dx (Shape x y a sx sy o n f) =
    Shape (x - dx) y a sx sy o n f


{-| Move shapes to the right.

    import Playground exposing (..)

    main =
        picture
            [ square purple 20
                |> moveRight 80
                |> moveDown 100
            ]

-}
moveRight : Number -> Shape msg -> Shape msg
moveRight =
    moveX


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
moveX : Number -> Shape msg -> Shape msg
moveX dx (Shape x y a sx sy o n f) =
    Shape (x + dx) y a sx sy o n f


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
moveY : Number -> Shape msg -> Shape msg
moveY dy (Shape x y a sx sy o n f) =
    Shape x (y + dy) a sx sy o n f


{-| Move a shape along a path, specified by a list of coordinate-pairs,
and a number between 0 and 1, where 0 corresponds with the start of the
path and 1 indicates arriving at the end, the last coordinate in the list.
So in the example below, the circle is moved halfway on the path:

    circle red 50
        |> moveAlong [ ( 100, 0 ), ( 200, 200 ), ( 400, 200 ) ] 0.5

-}
moveAlong : List ( Number, Number ) -> Number -> Shape msg -> Shape msg
moveAlong coords amount ((Shape x y a sx sy o n f) as shape) =
    let
        totalLength =
            case coords of
                ( x1, y1 ) :: rest ->
                    rest
                        |> List.foldl
                            (\( x3, y3 ) ( length, ( x2, y2 ) ) ->
                                ( length + sqrt ((x3 - x2) ^ 2 + (y3 - y2) ^ 2), ( x3, y3 ) )
                            )
                            ( 0, ( x1, y1 ) )
                        |> Tuple.first

                _ ->
                    0

        ( nx, ny ) =
            case coords of
                [] ->
                    ( 0, 0 )

                [ ( x1, y1 ) ] ->
                    ( x1, y1 )

                ( x1, y1 ) :: rest ->
                    rest
                        |> List.foldl
                            (\( x3, y3 ) ( ( x2, y2 ), amountLeft ) ->
                                if amountLeft < 0 then
                                    ( ( x2, y2 ), 0 )

                                else
                                    let
                                        length =
                                            sqrt ((x3 - x2) ^ 2 + (y3 - y2) ^ 2)

                                        factor =
                                            if length == 0 then
                                                0

                                            else
                                                Basics.min amountLeft length / length
                                    in
                                    ( ( x2 + (x3 - x2) * factor, y2 + (y3 - y2) * factor ), amountLeft - length )
                            )
                            ( ( x1, y1 ), amount * totalLength )
                        |> Tuple.first
    in
    Shape (x + nx) (y + ny) a sx sy o n f


{-| Move a shape along a path, just like with moveAlong, but by adding the first
point also as the last one, we make sure that when amount reaches 1, we end up
back at the beginning of the path. In this way you can keep looping from 0 to 1
and continue from 0 again.
-}
moveAlongLoop : List ( Number, Number ) -> Number -> Shape msg -> Shape msg
moveAlongLoop coords amount shape =
    let
        loop =
            case coords of
                [] ->
                    []

                [ point ] ->
                    [ point ]

                point :: rest ->
                    point :: rest ++ [ point ]
    in
    moveAlong loop amount shape


{-| Make a shape bigger or smaller. So if you wanted some [`words`](#words) to
be larger, you could say:

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello, nice to see you!"
                |> scale 3
            ]

-}
scale : Number -> Shape msg -> Shape msg
scale ns (Shape x y a sx sy o n f) =
    Shape x y a (sx * ns) (sy * ns) o n f


{-| Make a shape's width bigger or smaller. So if you wanted a [`triangle`](#triangle) to
be wider, you could say:

    import Playground exposing (..)

    main =
        picture
            [ triangle black 20
                |> scaleX 3
            ]

-}
scaleX : Number -> Shape msg -> Shape msg
scaleX ns (Shape x y a sx sy o n f) =
    Shape x y a (sx * ns) sy o n f


{-| Make a shape's height bigger or smaller. So if you wanted a [`triangle`](#triangle) to
be taller, you could say:

    import Playground exposing (..)

    main =
        picture
            [ triangle black 20
                |> scaleY 3
            ]

-}
scaleY : Number -> Shape msg -> Shape msg
scaleY ns (Shape x y a sx sy o n f) =
    Shape x y a sx (sy * ns) o n f


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
rotate : Number -> Shape msg -> Shape msg
rotate da (Shape x y a sx sy o n f) =
    Shape x y (a + da) sx sy o n f


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
fade : Number -> Shape msg -> Shape msg
fade o (Shape x y a sx sy _ n f) =
    Shape x y a sx sy o n f


{-| Name a shape. This lets you set a name for a shape, so you can detect when
it is clicked.

    import Playground exposing (..)

    main =
        game view update {}

    view computer memory =
        [ square
            (if computer.mouse |> clickedName "little square" then
                red

             else
                green
            )
            30
            |> withName "little square"
        ]

    update computer memory =
        memory

-}
withName : String -> Shape Msg -> Shape Msg
withName n (Shape x y a sx sy o _ f) =
    Shape x y a sx sy o (Just (ClickedName n)) f

{-| Return the name of a shape if it was given one.

    let
        namedSquare = square red 50 |> withName "The Square"
    in
    case nameOf namedSquare of
        Nothing -> "unnamed shape"
        Just name -> "a shape named " ++ name

-}
nameOf : Shape Msg -> Maybe String
nameOf (Shape _ _ _ _ _ _ maybeMessage _) =
    case maybeMessage of
        Just (ClickedName name) -> Just name
        _ -> Nothing



{-| Detect when a named shape is clicked. Use with `withName`.
-}
clickedName : String -> Mouse -> Bool
clickedName n { clickedNames } =
    List.member n clickedNames


{-| Change the font used for the words within shapes:

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello world"
                |> withFont "sans-serif"
            ]

-}
withFont : String -> Shape msg -> Shape msg
withFont fontname ((Shape x y a sx sy o n f) as shape) =
    case f of
        Words c outline _ w ->
            Shape x y a sx sy o n (Words c outline (Just fontname) w)

        Group shapes ->
            Shape x y a sx sy o n (Group (List.map (withFont fontname) shapes))

        _ ->
            Shape x y a sx sy o n f



-- COLOR


{-| Represents a color.

The colors below, like `red` and `green`, come from the [Tango palette][tango].
It provides a bunch of aesthetically reasonable colors. Each color comes with a
light and dark version, so you always get a set like `lightYellow`, `yellow`,
and `darkYellow`.

[tango]: https://en.wikipedia.org/wiki/Tango_Desktop_Project

-}
type Color
    = Hex String
    | Rgb Int Int Int
    | None


{-| -}
transparent : Color
transparent =
    None


{-| -}
lightYellow : Color
lightYellow =
    Hex "#fce94f"


{-| -}
yellow : Color
yellow =
    Hex "#edd400"


{-| -}
darkYellow : Color
darkYellow =
    Hex "#c4a000"


{-| -}
lightOrange : Color
lightOrange =
    Hex "#fcaf3e"


{-| -}
orange : Color
orange =
    Hex "#f57900"


{-| -}
darkOrange : Color
darkOrange =
    Hex "#ce5c00"


{-| -}
lightBrown : Color
lightBrown =
    Hex "#e9b96e"


{-| -}
brown : Color
brown =
    Hex "#c17d11"


{-| -}
darkBrown : Color
darkBrown =
    Hex "#8f5902"


{-| -}
lightGreen : Color
lightGreen =
    Hex "#8ae234"


{-| -}
green : Color
green =
    Hex "#73d216"


{-| -}
darkGreen : Color
darkGreen =
    Hex "#4e9a06"


{-| -}
lightBlue : Color
lightBlue =
    Hex "#729fcf"


{-| -}
blue : Color
blue =
    Hex "#3465a4"


{-| -}
darkBlue : Color
darkBlue =
    Hex "#204a87"


{-| -}
lightPurple : Color
lightPurple =
    Hex "#ad7fa8"


{-| -}
purple : Color
purple =
    Hex "#75507b"


{-| -}
darkPurple : Color
darkPurple =
    Hex "#5c3566"


{-| -}
lightRed : Color
lightRed =
    Hex "#ef2929"


{-| -}
red : Color
red =
    Hex "#cc0000"


{-| -}
darkRed : Color
darkRed =
    Hex "#a40000"


{-| -}
lightGrey : Color
lightGrey =
    Hex "#eeeeec"


{-| -}
grey : Color
grey =
    Hex "#d3d7cf"


{-| -}
darkGrey : Color
darkGrey =
    Hex "#babdb6"


{-| -}
lightCharcoal : Color
lightCharcoal =
    Hex "#888a85"


{-| -}
charcoal : Color
charcoal =
    Hex "#555753"


{-| -}
darkCharcoal : Color
darkCharcoal =
    Hex "#2e3436"


{-| -}
white : Color
white =
    Hex "#FFFFFF"


{-| -}
black : Color
black =
    Hex "#000000"



-- ALTERNATE SPELLING GREYS


{-| -}
lightGray : Color
lightGray =
    Hex "#eeeeec"


{-| -}
gray : Color
gray =
    Hex "#d3d7cf"


{-| -}
darkGray : Color
darkGray =
    Hex "#babdb6"



-- CUSTOM COLORS


{-| RGB stands for Red-Green-Blue. With these three parts, you can create any
color you want. For example:

    brightBlue =
        rgb 18 147 216

    brightGreen =
        rgb 119 244 8

    brightPurple =
        rgb 94 28 221

Each number needs to be between 0 and 255.

It can be hard to figure out what numbers to pick, so try using a color picker
like [paletton] to find colors that look nice together. Once you find nice
colors, click on the color previews to get their RGB values.

[paletton]: http://paletton.com/

-}
rgb : Number -> Number -> Number -> Color
rgb r g b =
    Rgb (colorClamp r) (colorClamp g) (colorClamp b)


colorClamp : Number -> Int
colorClamp number =
    clamp 0 255 (round number)



-- COLLISIONS


{-| Indicates whether two (groups of) shapes collide.
-}
collidesWith : Shape msg -> Shape msg -> Bool
collidesWith shape2 shape1 =
    (shape1 |> distanceTo shape2) <= 0


{-| Calculates the distance between two shapes, taking their sizes into account:

    shape1 =
        circle red 50

    shape2 =
        circle red 20
            |> move 100 40

    distanceToCollision =
        shape2
            |> distanceTo shape1

-}
distanceTo : Shape msg -> Shape msg -> Number
distanceTo shape2 shape1 =
    case ( formOf shape1, formOf shape2 ) of
        ( Group shapes, _ ) ->
            shapes
                |> List.map (transformUsing shape1 >> distanceTo shape2)
                |> List.minimum
                |> Maybe.withDefault 0

        ( _, Group shapes ) ->
            shapes
                |> List.map (transformUsing shape2 >> distanceTo shape1)
                |> List.minimum
                |> Maybe.withDefault 0

        ( Rectangle _ _ w h, _ ) ->
            let
                ( x, y ) =
                    positionOf shape1

                ( c, e ) =
                    ( positionOf shape2, extent shape2 )
            in
            distanceFromCircle c e { x = x, y = y, width = w, height = h, angle = rotationOf shape1 }

        ( _, Rectangle _ _ w h ) ->
            let
                ( x, y ) =
                    positionOf shape2

                ( c, e ) =
                    ( positionOf shape1, extent shape1 )
            in
            distanceFromCircle c e { x = x, y = y, width = w, height = h, angle = rotationOf shape2 }

        _ ->
            let
                ( cx1, cy1 ) =
                    center shape1

                ( cx2, cy2 ) =
                    center shape2

                -- potential contact point c1 + df(angle(c1->c2))*(c1->c2)
                -- potential contact point c2 + df(angle(c2->c1))*(c2->c1)
                -- simplification: circles
                e1 =
                    extent shape1

                -- TODO: needs to take angle and radially parametrized distance to edge function
                e2 =
                    extent shape2
            in
            sqrt ((cx2 - cx1) ^ 2 + (cy2 - cy1) ^ 2) - e1 - e2


distanceFromCircle ( cx, cy ) cr { x, y, width, height, angle } =
    let
        rad =
            degrees angle

        -- move the center of the circle back relative to the
        -- rectangle (so the latter is centered around the origin)
        ( dx, dy ) =
            ( cx - x, cy - y )

        -- calculate the distance between the centers and rotate
        -- the circle back, so the distance function for the
        -- rectangle can be stationary (not rotated)
        d =
            sqrt (dx ^ 2 + dy ^ 2)

        cosalpha =
            dx / d

        theta =
            rad
                - (if dy >= 0 then
                    acos cosalpha

                   else
                    -(acos cosalpha)
                  )

        ( cx_, cy_ ) =
            ( d * cos -theta, d * sin -theta )

        hw =
            width / 2

        hh =
            height / 2
    in
    if abs (tan theta) <= hh / hw then
        d - cr - (hw / abs (cos theta))

    else
        d - cr - (hh / abs (sin theta))


{-| Returns true if the point (x, y) lies within the shape.
-}
containsPoint : ( Number, Number ) -> Shape msg -> Bool
containsPoint ( x, y ) shape =
    case shape of
        Shape x_ y_ _ sx sy _ _ (Circle _ _ r) ->
            let
                ( a, b ) =
                    ( sx * (x - x_), sy * (y - y_) )
            in
            sqrt (a ^ 2 + b ^ 2) <= r

        Shape x_ y_ _ sx sy _ _ (Group shapes) ->
            if sx == 0 || sy == 0 then
                False

            else
                shapes
                    |> List.any (containsPoint ( (x - x_) / sx, (y - y_) / sy ))

        _ ->
            shape
                |> toPolygon2d
                |> Polygon2d.contains (Point2d.unitless x y)


{-| This function is the same as `verticesOf` ("vertices" is a more formal way
of saying "points" or "coordinates").
-}
pointsOf : Shape msg -> List ( Number, Number )
pointsOf =
    verticesOf


{-| Returns a list of vertices (points) corresponding to the circumference of
the shape. If the shape is circular, this returns an approximating polygon.
-}
verticesOf : Shape msg -> List ( Number, Number )
verticesOf shape =
    case shape of
        Shape x y r sx sy _ _ (Polygon _ _ points) ->
            points
                |> List.map (transformCoordinates x y r sx sy)

        _ ->
            shape
                |> toPolygon2d
                |> Polygon2d.vertices
                |> List.map (Point2d.unwrap >> (\{ x, y } -> ( x, y )))


{-| Convert any shape to a polygon representation of it (a circle would get
translated into an approximation of a circle using line segments, currently
an octagon). This can be used to create a polygon from a group of arranged
basic shapes, as an alternative way definition; it is sometimes easier than
enumerating all the points one by one as coordinate pairs.
-}
toPolygon : Color -> Shape msg -> Shape msg
toPolygon color ((Shape _ _ _ _ _ o name _) as shape) =
    toPolygon2d shape
        |> Polygon2d.vertices
        |> List.map (Point2d.unwrap >> (\{ x, y } -> ( x, y )))
        |> Polygon color NoOutline
        |> Shape 0 0 0 1 1 o name


{-| Convert an elm-geometry Polygon2d to a polygone Shape with specified color.
-}
polygonFromPolygon2d : Color -> Polygon2d unit coords -> Shape msg
polygonFromPolygon2d color p2d =
    p2d
        |> Polygon2d.vertices
        |> List.map (Point2d.unwrap >> (\{ x, y } -> ( x, y )))
        |> Polygon color NoOutline
        |> Shape 0 0 0 1 1 1 Nothing


toPolygon2d : Shape msg -> Polygon2d Unitless coords
toPolygon2d (Shape x y rot sx sy o name f) =
    let
        transform =
            Polygon2d.translateBy (Vector2d.unitless x y)
                >> Polygon2d.rotateAround Point2d.origin (Angle.degrees rot)
    in
    case f of
        -- Crude octagonal approximation
        Circle color outline r ->
            toPolygon2d (Shape x y rot sx sy o name (Ngon color outline 8 r))

        -- Crude single-axis scaled octagonal approximation
        Oval color outline w h ->
            let
                sy_ =
                    sy
                        * (if w == 0 then
                            0

                           else
                            h / w
                          )
            in
            toPolygon2d (Shape x y rot sx sy_ o name (Ngon color outline 8 (w / 2)))

        Rectangle _ _ w h ->
            let
                ( hw, hh ) =
                    ( sx * w / 2, sy * h / 2 )
            in
            [ Point2d.unitless hw hh
            , Point2d.unitless -hw hh
            , Point2d.unitless -hw -hh
            , Point2d.unitless hw -hh
            ]
                |> Polygon2d.singleLoop
                |> transform

        Ngon _ _ 0 _ ->
            Polygon2d.singleLoop []

        Ngon _ _ n r ->
            let
                point a =
                    Point2d.unitless (sx * r * cos a) (sy * r * sin a)
            in
            List.range 0 (n - 1)
                |> List.map
                    (\i -> toFloat i / toFloat n - 0.25 |> turns |> point)
                |> Polygon2d.singleLoop
                |> transform

        Polygon _ _ points ->
            points
                |> List.map (\( x_, y_ ) -> Point2d.unitless (sx * x_) (sy * y_))
                |> Polygon2d.singleLoop
                |> transform

        Image w h _ ->
            toPolygon2d (Shape x y rot sx sy o name (Rectangle white NoOutline w h))

        Words _ _ _ _ ->
            Polygon2d.singleLoop []

        Group shapes ->
            shapes
                |> List.concatMap (toPolygon2d >> Polygon2d.vertices)
                |> Polygon2d.convexHull
                |> transform

        SvgPath _ _ _ ->
            Polygon2d.singleLoop []


{-| Returns the position of a shape, as a pair (x, y).
-}
positionOf : Shape msg -> ( Number, Number )
positionOf (Shape x y _ _ _ _ _ _) =
    ( x, y )


{-| Returns the angle of rotation of a shape.
-}
rotationOf : Shape msg -> Number
rotationOf (Shape _ _ r _ _ _ _ _) =
    r


{-| Returns the scaling set on a shape, as a pair (horizontalScaling, verticalScaling).
-}
scaleOf : Shape msg -> ( Number, Number )
scaleOf (Shape _ _ _ sx sy _ _ _) =
    ( sx, sy )


formOf (Shape _ _ _ _ _ _ _ form) =
    form


{-| Extracts the center from any shape.
-}
center : Shape msg -> ( Number, Number )
center (Shape x y _ _ _ _ _ shape) =
    case shape of
        Group [] ->
            ( x, y )

        Group shapes ->
            let
                count =
                    List.length shapes
                        |> toFloat
            in
            shapes
                |> List.foldl
                    (\s ( sumx, sumy ) ->
                        let
                            ( sx, sy ) =
                                center s
                        in
                        ( sumx + sx, sumy + sy )
                    )
                    ( 0, 0 )
                |> (\( sumx, sumy ) -> ( x + (sumx / count), y + (sumy / count) ))

        _ ->
            ( x, y )


{-| Calculates (the currently very crude approximation of) the extent (size) of any (group of) shape(s).
-}
extent : Shape msg -> Number
extent (Shape _ _ _ _ _ _ _ form) =
    case form of
        Circle _ _ size ->
            size

        Oval _ _ s1 s2 ->
            -- This is only a very crude approximation
            (s1 + s2) / 2

        Rectangle _ _ s1 s2 ->
            -- This is only a very crude approximation
            (s1 + s2) / 4

        Ngon _ _ _ size ->
            size

        Polygon _ _ points ->
            let
                ( ( minx, miny ), ( maxx, maxy ) ) =
                    List.foldl
                        (\( x, y ) ( ( minx1, miny1 ), ( maxx1, maxy1 ) ) ->
                            ( ( Basics.min x minx1, Basics.min y miny1 )
                            , ( Basics.max x maxx1, Basics.max y maxy1 )
                            )
                        )
                        ( ( 0, 0 ), ( 0, 0 ) )
                        points
            in
            ((maxx - minx) + (maxy - miny)) / 2

        Image s1 s2 _ ->
            (s1 + s2) / 2

        Words _ _ _ _ ->
            0

        Group shapes ->
            List.foldl (\s e -> Basics.max e (extent s)) 0 shapes

        SvgPath _ _ segments ->
            0


transformCoordinates x y a sx sy ( cx, cy ) =
    let
        px =
            sx * cx

        py =
            sy * cy

        d =
            degrees a
    in
    ( (px * cos d) + (py * sin -d) + x, (px * sin d) + (py * cos -d) + y )


transformUsing shape (Shape x y r sx sy alpha msg form) =
    let
        ( cx, cy ) =
            positionOf shape

        ( ssx, ssy ) =
            scaleOf shape

        ( px, py ) =
            ( ssx * x, ssy * y )

        sr =
            rotationOf shape
    in
    Shape ((px * cos sr) + (py * sin sr) + cx) ((px * sin sr) + (py * cos sr) + cy) (r + sr) (sx + ssx) (sy + ssy) alpha msg form



-- GENERATING COORDINATES


type alias Cursor =
    ( ( Number, Number ), Number )


type alias CursorTransform =
    Cursor -> Cursor


{-| Make a list of coordinates starting from point (0, 0) adding new points
from a recipe; a list of commands, such as:

    main =
        picture [ polygon green trousers ]

    trousers =
        pathFromCommands
            [ forward 55
            , turn -92
            , forward 100
            , turnTo 180
            , forward 20
            , turn -88
            , forward 80
            , turn 176
            , forward 80
            , turnTo 180
            , forward 20
            , turn -88
            ]

-}
pathFromCommands : List CursorTransform -> List ( Number, Number )
pathFromCommands commands =
    commands
        |> List.foldl
            (\cmd ( ( lastPoint, lastRotation ), points ) ->
                let
                    ( point, rotation ) =
                        cmd ( lastPoint, lastRotation )
                in
                if lastPoint == point then
                    ( ( point, rotation ), points )

                else
                    ( ( point, rotation ), point :: points )
            )
            ( ( ( 0, 0 ), 0 ), [ ( 0, 0 ) ] )
        |> Tuple.second
        |> List.reverse


{-| For use with pathFromCommands: move n steps forward.
-}
forward : Number -> CursorTransform
forward n ( ( x, y ), r ) =
    ( ( x + n * cos r, y + n * sin r ), r )


{-| For use with pathFromCommands: turn n degrees counter clockwise.
-}
turn : Number -> CursorTransform
turn n ( ( x, y ), r ) =
    ( ( x, y ), r + degrees n )


{-| For use with pathFromCommands: change direction to the angle n in degrees, turning counter clockwise.
-}
turnTo : Number -> CursorTransform
turnTo n ( ( x, y ), _ ) =
    ( ( x, y ), degrees n )



-- RENDER


render : Screen -> List (Shape msg) -> Html.Html msg
render screen shapes =
    let
        w =
            String.fromFloat screen.width

        h =
            String.fromFloat screen.height

        x =
            String.fromFloat screen.left

        y =
            String.fromFloat screen.bottom
    in
    svg
        [ viewBox (x ++ " " ++ y ++ " " ++ w ++ " " ++ h)
        , H.style "position" "absolute"
        , H.style "top" "0"
        , H.style "left" "0"
        , H.style "width" "100%"
        , H.style "height" "100%"
        , width "100%"
        , height "100%"
        ]
        (List.map renderShape shapes)



-- TODO try adding Svg.Lazy to renderShape
--


renderShape : Shape msg -> Svg msg
renderShape (Shape x y angle sx sy alpha msg form) =
    case form of
        Circle color outline radius ->
            renderCircle color outline radius x y angle sx sy alpha msg

        Oval color outline width height ->
            renderOval color outline width height x y angle sx sy alpha msg

        Rectangle color outline width height ->
            renderRectangle color outline width height x y angle sx sy alpha msg

        Ngon color outline n radius ->
            renderNgon color outline n radius x y angle sx sy alpha msg

        Polygon color outline points ->
            renderPolygon color outline points x y angle sx sy alpha msg

        Image width height src ->
            renderImage width height src x y angle sx sy alpha msg

        Words color outline font string ->
            renderWords color outline font string x y angle sx sy alpha msg

        SvgPath color outline segments ->
            renderPath color outline segments x y angle sx sy alpha msg

        Group shapes ->
            g (transform (renderTransform x y angle sx sy) :: renderAlpha alpha ++ renderOnClick msg)
                (List.map renderShape shapes)



-- RENDER CIRCLE AND OVAL


renderCircle : Color -> Outline -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderCircle color outline radius x y angle sx sy alpha msg =
    Svg.circle
        (r (String.fromFloat radius)
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ renderOutline outline
        )
        []


renderOval : Color -> Outline -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderOval color outline width height x y angle sx sy alpha msg =
    ellipse
        (rx (String.fromFloat (width / 2))
            :: ry (String.fromFloat (height / 2))
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ renderOutline outline
        )
        []



-- RENDER RECTANGLE AND IMAGE


renderRectangle : Color -> Outline -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderRectangle color outline w h x y angle sx sy alpha msg =
    rect
        (width (String.fromFloat w)
            :: height (String.fromFloat h)
            :: fill (renderColor color)
            :: transform (renderRectTransform w h x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ renderOutline outline
        )
        []


renderRectTransform : Number -> Number -> Number -> Number -> Number -> Number -> Number -> String
renderRectTransform width height x y angle sx sy =
    renderTransform x y angle sx sy
        ++ " translate("
        ++ String.fromFloat (-width / 2)
        ++ ","
        ++ String.fromFloat (-height / 2)
        ++ ")"


renderImage : Number -> Number -> String -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderImage w h src x y angle sx sy alpha msg =
    Svg.image
        (xlinkHref src
            :: imageRendering "pixelated"
            :: width (String.fromFloat w)
            :: height (String.fromFloat h)
            :: transform (renderRectTransform w h x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
        )
        []



-- RENDER NGON


renderNgon : Color -> Outline -> Int -> Number -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderNgon color outline n radius x y angle sx sy alpha msg =
    Svg.polygon
        (points (toNgonPoints 0 n radius "")
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ renderOutline outline
        )
        []


toNgonPoints : Int -> Int -> Float -> String -> String
toNgonPoints i n radius string =
    if i == n then
        string

    else
        let
            a =
                turns (toFloat i / toFloat n - 0.25)

            x =
                radius * cos a

            y =
                radius * sin a
        in
        toNgonPoints (i + 1) n radius (string ++ String.fromFloat x ++ "," ++ String.fromFloat y ++ " ")



-- RENDER POLYGON


renderPolygon : Color -> Outline -> List ( Number, Number ) -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderPolygon color outline coordinates x y angle sx sy alpha msg =
    Svg.polygon
        (points (List.foldl addPoint "" coordinates)
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ renderOutline outline
        )
        []


addPoint : ( Float, Float ) -> String -> String
addPoint ( x, y ) str =
    str ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ " "



-- RENDER PATH


renderPath : Color -> Outline -> String -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderPath color outline p x y angle sx sy alpha msg =
    Svg.path
        (d p
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ (case outline of
                    NoOutline ->
                        []

                    Outline c w ->
                        [ stroke (renderColor c), strokeWidth (String.fromFloat w) ]
               )
            ++ renderOnClick msg
        )
        []



-- RENDER WORDS


renderWords : Color -> Outline -> Font -> String -> Number -> Number -> Number -> Number -> Number -> Number -> Maybe msg -> Svg msg
renderWords color outline maybeFont string x y angle sx sy alpha msg =
    let
        font =
            maybeFont
                |> Maybe.map (fontFamily >> List.singleton)
                |> Maybe.withDefault []
    in
    text_
        (textAnchor "middle"
            :: dominantBaseline "central"
            :: fill (renderColor color)
            :: transform (renderTransform x y angle sx sy)
            :: renderAlpha alpha
            ++ renderOnClick msg
            ++ font
            ++ renderOutline outline
        )
        [ text string
        ]



-- RENDER OUTLINE


renderOutline : Outline -> List (Svg.Attribute msg)
renderOutline outline =
    case outline of
        NoOutline ->
            []

        Outline outlinecolor thickness ->
            [ stroke (renderColor outlinecolor), strokeWidth (String.fromFloat thickness) ]



-- RENDER COLOR


renderColor : Color -> String
renderColor color =
    case color of
        None ->
            "none"

        Hex str ->
            str

        Rgb r g b ->
            "rgb(" ++ String.fromInt r ++ "," ++ String.fromInt g ++ "," ++ String.fromInt b ++ ")"



-- RENDER ALPHA


renderAlpha : Number -> List (Svg.Attribute msg)
renderAlpha alpha =
    if alpha == 1 then
        []

    else
        [ opacity (String.fromFloat (clamp 0 1 alpha)) ]



-- RENDER TRANFORMS


renderTransform : Number -> Number -> Number -> Number -> Number -> String
renderTransform x y a sx sy =
    if a == 0 then
        if sx == 1 && sy == 1 then
            "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ")"

        else if sx == sy then
            "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") scale(" ++ String.fromFloat sx ++ ")"

        else if sx == 1 then
            "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") scale(1, " ++ String.fromFloat sy ++ ")"

        else if sy == 1 then
            "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") scale(" ++ String.fromFloat sx ++ ", 1)"

        else
            "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") scale(" ++ String.fromFloat sx ++ ", " ++ String.fromFloat sy ++ ")"

    else if sx == 1 && sy == 1 then
        "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") rotate(" ++ String.fromFloat -a ++ ")"

    else if sx == sy then
        "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") rotate(" ++ String.fromFloat -a ++ ") scale(" ++ String.fromFloat sx ++ ")"

    else if sx == 1 then
        "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") rotate(" ++ String.fromFloat -a ++ ") scale(1, " ++ String.fromFloat sy ++ ")"

    else if sy == 1 then
        "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") rotate(" ++ String.fromFloat -a ++ ") scale(" ++ String.fromFloat sx ++ ", 1)"

    else
        "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat -y ++ ") rotate(" ++ String.fromFloat -a ++ ") scale(" ++ String.fromFloat sx ++ ", " ++ String.fromFloat sy ++ ")"


renderOnClick : Maybe msg -> List (Svg.Attribute msg)
renderOnClick m =
    case m of
        Nothing ->
            []

        Just msg ->
            [ Svg.Events.onClick msg ]



-- AUDIO


{-| The AudioPort connects our Elm game to a piece of javascript in the html file the game is embedded in,
so it can access the WebAudio API. Use in your game program as follows:

    port module Main exposing (main)

    import Eigenwijs.Playground

    port toWebAudio : Eigenwijs.Playground.AudioPort msg

-}
type alias AudioPort msg =
    Json.Encode.Value -> Cmd msg


{-| Create a game with web audio elements such as oscillators.

This is still a work in progress, more documentation and tuning of the api is to come.

-}
gameWithAudio : AudioPort Msg -> (Computer -> memory -> List WebAudio.Node) -> (Computer -> memory -> List (Shape Msg)) -> (Computer -> memory -> memory) -> memory -> Program () (Game memory) Msg
gameWithAudio toWebAudio audioForMemory viewMemory updateMemory initialMemory =
    let
        view model =
            { title = "Playground"
            , body = [ gameView viewMemory model ]
            }

        update msg ((Game vis memory computer) as model) =
            ( gameUpdate updateMemory msg model
            , audioForMemory computer memory
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


{-| Create a path from svg path string
-}
svgPath : Color -> String -> Shape msg
svgPath color p =
    Shape 0 0 0 1 1 1 Nothing (SvgPath transparent (Outline color 1) p)


{-| Draw a line with specified thickness from a list of coordinates
-}
line : Color -> Number -> List ( Number, Number ) -> Shape msg
line color thickness coordlist =
    let
        p =
            case coordlist of
                [] ->
                    ""

                ( x, y ) :: rest ->
                    "M "
                        ++ String.fromFloat x
                        ++ ","
                        ++ String.fromFloat -y
                        ++ " "
                        ++ String.join " "
                            (rest
                                |> List.map
                                    (\( u, v ) ->
                                        "L "
                                            ++ String.fromFloat u
                                            ++ ","
                                            ++ String.fromFloat -v
                                    )
                            )
    in
    Shape 0 0 0 1 1 1 Nothing (SvgPath transparent (Outline color thickness) p)


{-| Draw a line between two points with specified thickness
-}
lineBetween : ( Number, Number ) -> ( Number, Number ) -> Color -> Number -> Shape msg
lineBetween ( x1, y1 ) ( x2, y2 ) color thickness =
    let
        dx =
            x2 - x1

        dy =
            y2 - y1

        length =
            sqrt (dx * dx + dy * dy)

        angle =
            atan2 dy dx * 180 / pi

        -- direct naar graden omzetten
    in
    rectangle color length thickness
        |> move (x1 + dx / 2) (y1 + dy / 2)
        |> rotate angle


{-| Calculate arctangent of y/x, taking into account which quadrant the point is in
-}
atan2 : Number -> Number -> Number
atan2 y x =
    if x > 0 then
        atan (y / x)

    else if x < 0 && y >= 0 then
        atan (y / x) + pi

    else if x < 0 && y < 0 then
        atan (y / x) - pi

    else if x == 0 && y > 0 then
        pi / 2

    else if x == 0 && y < 0 then
        -pi / 2

    else
        0
