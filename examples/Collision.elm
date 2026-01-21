module Collision exposing (main)

import Eigenwijs.Playground exposing (..)
import Point2d
import Polygon2d


main =
    game view update init


init =
    { x = 0, y = 0 }


update computer memory =
    { memory
        | x = memory.x + toX computer.keyboard
        , y = memory.y + toY computer.keyboard
    }


view computer memory =
    let
        a =
            shapeA computer.time memory

        b =
            shapeB memory
    in
    [ a
    , toPolygon black a |> fade 0.3
    , b
    , toPolygon black b |> fade 0.3
    , minkowski
        (verticesOf (toPolygon transparent a))
        (verticesOf (toPolygon transparent b))
        |> List.map (\( x, y ) -> Point2d.unsafe { x = x, y = y })
        |> Polygon2d.convexHull
        |> Polygon2d.vertices
        |> List.map (Point2d.unwrap >> (\{ x, y } -> ( x, y )))
        |> polygon blue
        |> fade 0.5
    , words black
        (if collidesWith a b then
            "Collision"

         else
            "-"
        )
    ]


shapeA time { x, y } =
    group [ circle green 50, group [ triangle yellow 50 |> moveUp 50 ] |> rotate (spin 10 time) ]
        --triangle yellow 50
        |> move x y



--rectangle green 100 20 |> move x y


shapeB _ =
    square red 100
