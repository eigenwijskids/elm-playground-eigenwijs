# Elm Playground (Eigenwijs kids edition)

Create pictures, animations, and games with Elm!

This package can be used to program 2D and 3D graphics in the familiar way of Elm Playground.
The graphics can be integrated into your Html and Scene3d based apps.
The code started out in fact as a fork of https://github.com/evancz/elm-playground

This is the package we wanted when we were learning programming. Start by putting shapes on
screen and work up to making games. We hope this package will be fun for a broad range of
ages and backgrounds!

The Eigenwijs kids edition adds some features useful in our primary school workshops.

It is currently under heavy construction: For instance, the first release collided with the
original Playground package when installed side-by-side. The intention is to allow this, so
the current version leaves out the Playground module itself (it would intentionally be
identical anyway), offering Eigenwijs.Playground for 2D and Eigenwijs.Playground3D for 3D
graphics.

## Pictures

A picture is a list of shapes. For example, this picture combines a brown rectangle and a green circle to make a tree:

```elm
import Eigenwijs.Playground exposing (..)

main =
  picture
    [ rectangle brown 40 200
    , circle green 100
        |> moveUp 100
    ]
```

Play around to get familiar with all the different shapes and transformations in the library.


## 3D Pictures 😎

``` elm
import Eigenwijs.Playground3d exposing (..)

main =
  picture
    [ rectangle brown 40 200
    , circle green 100
      |> moveY -50
      |> moveZ 100
      |> extrude 50
    , cube red 50
      |> move -50 0 0
    ]
```

Note that it looks very similar to the 2D version above, with the same basic flat shapes you can
use to make 3D shapes (an "extruded" circle makes a cylinder for instance), and some extra shape
names, like "cube", "cylinder" and "block" to create 3D shapes in one go.

Note: At the moment not all 2D shapes of Playground are available in 3D - they are supposed to get
added soon!


## Animations

An animation is a list of shapes that changes over time. For example, here is a spinning triangle:

```elm
import Eigenwijs.Playground exposing (..)

main =
  animation view

view time =
  [ triangle orange 50
      |> rotate (spin 8 time)
  ]
```

It will do a full spin every 8 seconds.

Maybe try making a car with spinning octogons as wheels? Try using [`wave`](https://package.elm-lang.org/packages/evancz/elm-playground/latest/Playground#wave) to move things back-and-forth? Try using [`zigzag`](https://package.elm-lang.org/packages/evancz/elm-playground/latest/Playground#zigzag) to fade things in-and-out?


## Games

A game lets you use input from the mouse and keyboard to change your picture. For example, here is a square that moves around based on the arrow keys:

```elm
import Eigenwijs.Playground exposing (..)

main =
  game view update (0,0)

view computer (x,y) =
  [ square blue 40
      |> move x y
  ]

update computer (x,y) =
  ( x + toX computer.keyboard
  , y + toY computer.keyboard
  )
```

Every game has three important parts:

1. `memory` - Store information. Our examples stores `(x,y)` coordinates.
2. `update` - Update the memory based on mouse movements, key presses, etc. Our example moves the `(x,y)` coordinate around based on the arrow keys.
3. `view` - Turn the memory into a picture. Our example just shows one blue square at the `(x,y)` coordinate we have been tracking in memory.

When you start making fancier games, you will store fancier things in memory. There is a lot of room to develop your programming skills here: Making lists, using records, creating custom types, etc.

I started off trying to make Pong, then worked on games like Breakout and Space Invaders as I learned more and more. It was really fun, and I hope it will be for you as well!


# Share Your Results :D

The original Playground package already encourages publishing work based on and use of the Playground.
I would like to add another way of sharing:

One of the biggest issues with IT nowadays is mental accessibility of technology, both for the general
public and even for developers themselves. Elm is doing a good job in offering a way to increase mental
accessibility of code, but the other part is visibility and availability of a stimulating and inspiring
environment for having discussions about technology, dreaming and building together, and helping one
another out in discovering and learning to wield the super power of independent collaborative
software development.

So, let's have recurring "public coding" sessions in our local communities, like in a public library
or cultural hotspot! It would be awesome to spark local technology engagement and cool new open source
projects this way, as wel as increase visibility of Elm as a very helpful and powerful tool.
