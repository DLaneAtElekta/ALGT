namespace FuelInventoryManager

module Domain =
    // --- Domain Types ---
    type FuelType = 
        | Regular
        | Unleaded
        | Premium

    type TankLevelInches = TankLevelInches of int
    type Gallons = Gallons of int

    // --- Domain Errors ---
    type DomainError =
        | InvalidTankLevel of string

    // --- Fuel Inventory Charts (from original FiCustom.pas) ---
    // Mappings from inches (0..96) to gallons for each fuel type
    let regularChart = 
        [|
            0; 18; 52; 95; 145; 202; 265; 333; 405; 482; 563; 647; 735;
            826; 920; 1016; 1116; 1218; 1322; 1428; 1537; 1648; 1760; 1875; 1991;
            2109; 2228; 2349; 2471; 2594; 2719; 2845; 2972; 3099; 3228; 3358; 3488;
            3619; 3751; 3883; 4016; 4150; 4284; 4418; 4552; 4687; 4822; 4957; 5091;
            5226; 5361; 5496; 5631; 5765; 5899; 6033; 6167; 6300; 6432; 6564; 6695;
            6825; 6955; 7084; 7212; 7338; 7464; 7589; 7712; 7834; 7955; 8074; 8192;
            8308; 8423; 8535; 8646; 8755; 8861; 8966; 9067; 9167; 9264; 9357; 9448;
            9536; 9620; 9701; 9778; 9850; 9918; 9981; 10038; 10088; 10131; 10165; 10183
        |]

    let unleadedChart = 
        [|
            0; 22; 61; 112; 171; 238; 312; 392; 478; 568; 663; 763; 866;
            973; 1084; 1198; 1315; 1435; 1558; 1683; 1811; 1942; 2075; 2209; 2346;
            2485; 2626; 2768; 2912; 3057; 3204; 3352; 3502; 3653; 3804; 3957; 4111;
            4265; 4421; 4577; 4733; 4890; 5048; 5206; 5365; 5523; 5682; 5841; 6000;
            6159; 6318; 6447; 6636; 6794; 6952; 7110; 7267; 7424; 7580; 7735; 7890;
            8043; 8196; 8348; 8499; 8648; 8796; 8943; 9089; 9233; 9375; 9515; 9654;
            9791; 9926; 10059; 10189; 10317; 10443; 10566; 10686; 10803; 10917; 11027; 11135;
            11238; 11337; 11432; 11523; 11608; 11688; 11762; 11829; 11889; 11940; 11979; 12000
        |]

    let premiumChart = 
        [|
            0; 18; 51; 94; 145; 201; 264; 322; 405; 480; 561; 644; 731;
            822; 918; 1012; 1112; 1213; 1318; 1423; 1533; 1644; 1755; 1870; 1985;
            2103; 2222; 2342; 2462; 2586; 2710; 2835; 2961; 3089; 3218; 3347; 3477;
            3608; 3740; 3972; 4004; 4136; 4269; 4402; 4536; 4671; 4806; 4941; 5076;
            5211; 5346; 5480; 5613; 5748; 5883; 6016; 6148; 6281; 6413; 6544; 6674;
            6804; 6933; 7062; 7190; 7316; 7441; 7566; 7689; 7811; 7932; 8050; 8168;
            8283; 8397; 8510; 8621; 8728; 8834; 8939; 9040; 9139; 9236; 9329; 9420;
            9507; 9590; 9672; 9747; 9820; 9887; 9951; 10006; 10058; 10101; 10134; 10152
        |]

    // --- Workflows ---

    // Convert Tank Level (inches) to Gallons based on fuel type
    let convertInchesToGallons (fuel: FuelType) (TankLevelInches inches) : Result<Gallons, DomainError> =
        if inches < 0 || inches > 96 then
            Error (InvalidTankLevel (sprintf "Inches %d is out of valid range (0-96)" inches))
        else
            let chart = 
                match fuel with
                | Regular -> regularChart
                | Unleaded -> unleadedChart
                | Premium -> premiumChart
            
            Ok (Gallons chart.[inches])

    type DeliveryRecord = {
        Fuel: FuelType
        DeliveredGallons: Gallons
        TankBeforeInches: TankLevelInches
        TankAfterInches: TankLevelInches
    }

    type DeliveryResult = {
        Fuel: FuelType
        DeliveredGallons: Gallons
        CalculatedDifference: Gallons
        Discrepancy: int
    }

    let bind f x =
        match x with
        | Ok v -> f v
        | Error e -> Error e

    let calculateDelivery (record: DeliveryRecord) : Result<DeliveryResult, DomainError> =
        convertInchesToGallons record.Fuel record.TankBeforeInches
        |> bind (fun (Gallons beforeGal) ->
            convertInchesToGallons record.Fuel record.TankAfterInches
            |> bind (fun (Gallons afterGal) ->
                let diff = afterGal - beforeGal
                let (Gallons delivered) = record.DeliveredGallons
                Ok {
                    Fuel = record.Fuel
                    DeliveredGallons = record.DeliveredGallons
                    CalculatedDifference = Gallons diff
                    Discrepancy = delivered - diff
                }
            )
        )
