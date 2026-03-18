open FuelInventoryManager.Domain

[<EntryPoint>]
let main argv =
    printfn "Fuel Inventory Manager (F# Version)"
    printfn "==================================="

    // Test converting inches to gallons
    let testTankLevel fuel inches =
        match convertInchesToGallons fuel (TankLevelInches inches) with
        | Ok (Gallons g) -> printfn "  %A tank at %d inches = %d gallons" fuel inches g
        | Error (InvalidTankLevel msg) -> printfn "  Error: %s" msg

    printfn "\nChecking Tank Levels:"
    testTankLevel Regular 48
    testTankLevel Unleaded 48
    testTankLevel Premium 48
    testTankLevel Regular 100 // Should error

    // Test a fuel delivery
    printfn "\nProcessing Delivery:"
    let delivery = {
        Fuel = Unleaded
        DeliveredGallons = Gallons 4000
        TankBeforeInches = TankLevelInches 30
        TankAfterInches = TankLevelInches 56
    }

    match calculateDelivery delivery with
    | Ok result ->
        let (Gallons diff) = result.CalculatedDifference
        let (Gallons delivered) = result.DeliveredGallons
        printfn "  Fuel: %A" result.Fuel
        printfn "  Delivered Gallons: %d" delivered
        printfn "  Tank Difference: %d gallons" diff
        printfn "  Discrepancy (Delivered - Tank Diff): %d gallons" result.Discrepancy
        if result.Discrepancy > 0 then
            printfn "  -> Warning: Tank received %d less gallons than delivered!" result.Discrepancy
        elif result.Discrepancy < 0 then
            printfn "  -> Warning: Tank received %d more gallons than delivered!" (abs result.Discrepancy)
        else
            printfn "  -> Delivery perfectly matches tank level difference."
    | Error (InvalidTankLevel msg) ->
        printfn "  Delivery Error: %s" msg

    0
