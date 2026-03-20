namespace OrderDomain

// --- 1. Simple/Constrained Types ---
// Instead of primitive obsession (string), we use wrapper types for validation.
type OrderId = OrderId of string
type ProductCode = ProductCode of string
type Quantity = Quantity of int

// --- 2. Result Type for Error Handling (Railway Oriented Programming) ---
type Result<'Success, 'Failure> = 
    | Success of 'Success
    | Failure of 'Failure

// --- 3. Domain Entities and Value Objects ---
type OrderLine = {
    OrderId : OrderId
    ProductCode : ProductCode
    Quantity : Quantity
}

// --- 4. Representing States with Discriminated Unions ---
// This makes "illegal states unrepresentable" (Wlaschin's core principle).
type UnvalidatedOrder = {
    OrderId : string
    ProductCode : string
    Quantity : int
}

type ValidatedOrder = {
    OrderId : OrderId
    ProductCode : ProductCode
    Quantity : Quantity
}

type PricedOrder = {
    OrderId : OrderId
    ProductCode : ProductCode
    Quantity : Quantity
    Price : decimal
}

// --- 5. Workflows as Functions ---
// A workflow is a function that transforms one domain object to another.
module OrderWorkflow =

    // Validation step
    let validateOrder (unvalidated: UnvalidatedOrder) : Result<ValidatedOrder, string> =
        if unvalidated.Quantity <= 0 then 
            Failure "Quantity must be positive"
        else
            Success {
                OrderId = OrderId unvalidated.OrderId
                ProductCode = ProductCode unvalidated.ProductCode
                Quantity = Quantity unvalidated.Quantity
            }

    // Pricing step (Simulated)
    let priceOrder (validated: ValidatedOrder) : PricedOrder =
        {
            OrderId = validated.OrderId
            ProductCode = validated.ProductCode
            Quantity = validated.Quantity
            Price = 10.0m // Constant for demo
        }

    // Pipeline composition (Railway Oriented)
    let bind f result =
        match result with
        | Success x -> f x |> Success
        | Failure e -> Failure e

    let placeOrderWorkflow unvalidated =
        unvalidated
        |> validateOrder
        |> bind priceOrder
