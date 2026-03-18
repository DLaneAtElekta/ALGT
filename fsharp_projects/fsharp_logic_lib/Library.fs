namespace FSharpLogicLib

module Calculator =
    let add a b = a + b
    let subtract a b = a - b
    let multiply a b = a * b
    let divide a b =
        if b = 0 then None
        else Some (a / b)

module ImagingDomain =
    type Point = { X: float; Y: float }
    type Shape =
        | Circle of radius: float
        | Rectangle of width: float * height: float

    let calculateArea shape =
        match shape with
        | Circle r -> System.Math.PI * r * r
        | Rectangle (w, h) -> w * h
