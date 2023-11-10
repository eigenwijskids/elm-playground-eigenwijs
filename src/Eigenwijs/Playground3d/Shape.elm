module Eigenwijs.Playground3d.Shape exposing (circle, rectangle, triangle)

import Angle
import Array
import Direction2d
import Direction3d exposing (Direction3d)
import Length exposing (Length, Meters)
import Parameter1d
import Point3d exposing (Point3d)
import Quantity exposing (Quantity, zero)
import Scene3d.Mesh as Mesh exposing (Mesh)
import SketchPlane3d
import Triangle3d exposing (Triangle3d)
import TriangularMesh
import Vector3d exposing (Vector3d)


circle : Float -> Mesh.Uniform coordinates
circle radius =
    let
        center =
            Point3d.unsafe { x = 0, y = 0, z = 0 }

        normal =
            Vector3d.unsafe { x = 0, y = 0, z = 1 }
    in
    (\u ->
        let
            theta =
                2 * pi * u
        in
        Point3d.unsafe { x = radius * cos theta, y = radius * sin theta, z = 0 }
    )
        |> Parameter1d.leading 72
        |> TriangularMesh.radial center
        |> Mesh.indexedFacets


triangle : Float -> Mesh.Uniform coordinates
triangle s =
    let
        p1 =
            Point3d.unsafe
                { x = 0, y = s, z = 0 }

        p2 =
            Point3d.unsafe
                { x = s * sin (2 / 3 * pi), y = s * cos (2 / 3 * pi), z = 0 }

        p3 =
            Point3d.unsafe
                { x = s * sin (4 / 3 * pi), y = s * cos (4 / 3 * pi), z = 0 }
    in
    Mesh.facets [ Triangle3d.from p1 p2 p3 ]


rectangle : Float -> Float -> Mesh.Uniform coordinates
rectangle w h =
    let
        rw =
            w / 2

        rh =
            h / 2

        vertices =
            Array.fromList
                [ Point3d.unsafe { x = -rw, y = -rh, z = 0 }
                , Point3d.unsafe { x = rw, y = -rh, z = 0 }
                , Point3d.unsafe { x = rw, y = rh, z = 0 }
                , Point3d.unsafe { x = -rw, y = rh, z = 0 }
                ]

        faceIndices =
            [ ( 0, 1, 2 ), ( 0, 2, 3 ) ]
    in
    TriangularMesh.indexed vertices faceIndices
        |> Mesh.indexedFacets
