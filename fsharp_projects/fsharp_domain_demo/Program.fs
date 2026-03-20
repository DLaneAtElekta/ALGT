open OrderDomain

[<EntryPoint>]
let main argv =
    printfn "Domain Modeling Made Functional Demo"
    
    // --- Positive Case ---
    // Explicitly type as UnvalidatedOrder because ValidatedOrder has same field names
    let order1 : UnvalidatedOrder = { OrderId = "O1"; ProductCode = "P1"; Quantity = 5 }
    printfn "\nProcessing order: %A" order1
    
    match OrderWorkflow.placeOrderWorkflow order1 with
    | Success pricedOrder -> 
        printfn "SUCCESS: Priced Order: %A" pricedOrder
    | Failure errorMsg -> 
        printfn "FAILURE: %s" errorMsg

    // --- Negative Case (Validation failure) ---
    let order2 : UnvalidatedOrder = { OrderId = "O2"; ProductCode = "P2"; Quantity = -1 }
    printfn "\nProcessing order: %A" order2
    
    match OrderWorkflow.placeOrderWorkflow order2 with
    | Success pricedOrder -> 
        printfn "SUCCESS: Priced Order: %A" pricedOrder
    | Failure errorMsg -> 
        printfn "FAILURE: %s" errorMsg

    0 // return an integer exit code
