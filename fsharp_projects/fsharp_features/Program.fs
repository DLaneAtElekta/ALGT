open FSharpLogicLib
open FSharpLogicLib.ImagingDomain

[<EntryPoint>]
let main argv =
    printfn "F# Logic Demonstration"
    
    // Arithmetic example
    let result = Calculator.add 5 7
    printfn "5 + 7 = %d" result
    
    // Imaging example
    let circle = Circle 5.0
    let area = calculateArea circle
    printfn "Area of circle with radius 5.0 is %f" area
    
    let rect = Rectangle (10.0, 20.0)
    let rectArea = calculateArea rect
    printfn "Area of rectangle (10.0, 20.0) is %f" rectArea
    
    0 // return an integer exit code
