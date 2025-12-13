# Prescription Verification Module

Prolog predicates for validating radiation therapy prescriptions, comparing physician intent against treatment plans, and verifying treatment records.

## Overview

This module provides formal verification capabilities for radiation oncology workflows:

1. **Prescription Modeling** - Domain model for prescriptions, phases, and targets
2. **Biological Dose Calculations** - BED and EQD2 computations
3. **Intent vs Plan Validation** - Compare physician intent against treatment plan
4. **Treatment Record Verification** - Verify delivered treatments against plan

## Modules

### prescription_model.pl

Domain model for radiation therapy prescriptions.

```prolog
%% Create a prescription
Prescription = prescription(
    rx_001,                                    %% ID
    target_volume(ptv_prostate, ptv, pelvis),  %% Target
    7800,                                      %% Total dose (cGy)
    39,                                        %% Fractions
    200,                                       %% Dose per fraction (cGy)
    imrt,                                      %% Modality
    []                                         %% Phases
).

%% Wrap as physician intent
Intent = physician_intent(intent_001, Prescription).

%% Or as treatment plan
Plan = treatment_plan(plan_001, Prescription).
```

**Supported Modalities:**
- `photon`, `electron`, `proton`, `carbon_ion`
- `imrt`, `vmat`, `tomo`, `3dcrt`
- `sbrt`, `srs`, `brachytherapy`

**Target Volume Types:**
- `gtv`, `ctv`, `ptv`, `itv`
- `gtv_n`, `ctv_n`, `ptv_n` (nodal)
- `oar` (organs at risk)

### biological_dose.pl

Biological dose calculations including BED and EQD2.

```prolog
%% Calculate BED (Biologically Effective Dose)
%% BED = D * (1 + d / (α/β))
?- bed(60, 2, 10, BED).
BED = 72.0    %% 60 Gy at 2 Gy/fx, α/β=10

%% Calculate EQD2 (Equivalent Dose in 2 Gy Fractions)
?- eqd2(54, 18, 10, EQD2).
EQD2 = 126.0  %% SBRT: 54 Gy at 18 Gy/fx

%% Multi-phase BED calculation
?- Phases = [phase(primary, 5000, 25, 200, imrt),
             phase(boost, 1000, 5, 200, electrons)],
   total_bed(Phases, 10, TotalBED).
TotalBED = 72.0
```

**Alpha/Beta Ratios:**

| Tissue Type | α/β (Gy) |
|-------------|----------|
| Most tumors | 10 |
| Prostate | 1.5 |
| Breast | 4 |
| Late-responding tissue | 3 |
| Spinal cord | 2 |

### prescription_validation.pl

Validation predicates for comparing intent vs plan.

```prolog
%% Validate intent against plan with standard tolerance
?- validate_intent_vs_plan(Intent, Plan, Results).

%% Validate with specific tolerance level
?- validate_intent_vs_plan(Intent, Plan, strict, Results).

%% Check if all validations passed
?- validate_intent_vs_plan(Intent, Plan, Results),
   all_validations_pass(Results).
true.

%% Get validation errors
?- validate_intent_vs_plan(Intent, Plan, Results),
   collect_validation_errors(Results, Errors).
Errors = [validation_failed(total_dose, dose_deviation(...))]
```

**Tolerance Levels:**

| Level | Dose | BED |
|-------|------|-----|
| strict | 1% | 2 Gy |
| standard | 3% | 5 Gy |
| relaxed | 5% | 10 Gy |

**Validation Checks:**
- Total dose comparison
- Fraction count comparison
- Dose per fraction comparison
- Modality compatibility
- Biological dose (BED) equivalence
- Multi-phase consistency

### treatment_record_verification.pl

Verify treatment delivery against plan.

```prolog
%% Create treatment record
FractionRecords = [
    fraction_record(1, date(2024, 1, 1), 200, 250, []),
    fraction_record(2, date(2024, 1, 2), 200, 250, []),
    fraction_record(3, date(2024, 1, 3), 198, 248, [])
],
Record = treatment_record(rec_001, plan_001, patient_001,
                          date(2024, 1, 1), FractionRecords, in_progress).

%% Verify cumulative dose
?- verify_cumulative_dose(Record, Plan, standard, Result).
Result = validation_passed(cumulative_dose)

%% Check remaining treatment
?- remaining_fractions(Record, Plan, Remaining).
Remaining = 36

?- remaining_dose(Record, Plan, RemainingDose).
RemainingDose = 7202  %% cGy
```

## Usage Examples

### Example 1: Standard Prostate Treatment

```prolog
:- use_module(prescription_model).
:- use_module(prescription_validation).
:- use_module(biological_dose).

%% Physician intent: 78 Gy in 39 fractions
prostate_intent(Intent) :-
    Target = target_volume(ptv_prostate, ptv, pelvis),
    Rx = prescription(rx_001, Target, 7800, 39, 200, imrt, []),
    Intent = physician_intent(intent_001, Rx).

%% Treatment plan
prostate_plan(Plan) :-
    Target = target_volume(ptv_prostate, ptv, pelvis),
    Rx = prescription(plan_001, Target, 7800, 39, 200, vmat, []),
    Plan = treatment_plan(plan_001, Rx).

%% Validate
validate_prostate :-
    prostate_intent(Intent),
    prostate_plan(Plan),
    validate_intent_vs_plan(Intent, Plan, standard, Results),
    (   all_validations_pass(Results)
    ->  writeln('Prescription validated successfully')
    ;   collect_validation_errors(Results, Errors),
        format('Validation errors: ~w~n', [Errors])
    ).
```

### Example 2: Multi-Phase Breast Treatment

```prolog
breast_treatment(Intent) :-
    Target = target_volume(ptv_breast, ptv, chest),
    Phase1 = phase(whole_breast, 5000, 25, 200, tangents),
    Phase2 = phase(boost, 1000, 5, 200, electrons),
    Rx = prescription(rx_breast, Target, 6000, 30, 200, photon,
                      [Phase1, Phase2]),
    Intent = physician_intent(intent_breast, Rx).

%% Calculate total BED
breast_bed(TotalBED) :-
    breast_treatment(physician_intent(_, Rx)),
    prescription_phases(Rx, Phases),
    alpha_beta_ratio(breast, AlphaBeta),
    total_bed(Phases, AlphaBeta, TotalBED).
```

### Example 3: SBRT Biological Dose Analysis

```prolog
%% Compare SBRT vs conventional fractionation
compare_fractionation :-
    %% SBRT: 54 Gy in 3 fractions
    bed(54, 18, 10, SBRT_BED),
    eqd2(54, 18, 10, SBRT_EQD2),

    %% Conventional: 60 Gy in 30 fractions
    bed(60, 2, 10, Conv_BED),
    eqd2(60, 2, 10, Conv_EQD2),

    format('SBRT (54 Gy/3 fx): BED=~1f Gy, EQD2=~1f Gy~n',
           [SBRT_BED, SBRT_EQD2]),
    format('Conv (60 Gy/30 fx): BED=~1f Gy, EQD2=~1f Gy~n',
           [Conv_BED, Conv_EQD2]).

%% Output:
%% SBRT (54 Gy/3 fx): BED=151.2 Gy, EQD2=126.0 Gy
%% Conv (60 Gy/30 fx): BED=72.0 Gy, EQD2=60.0 Gy
```

## Running Tests

```bash
cd prescription_verification
swipl -g run_tests -t halt prescription_tests.pl
```

## Future Extensions

The module is designed to be extended for:

1. **DVH Integration** - Validate against dose-volume histograms
2. **OAR Constraints** - Organ-at-risk dose limits
3. **Adaptive Planning** - Re-planning based on delivered dose
4. **Machine Learning** - Predict optimal fractionation
5. **DICOM Integration** - Import/export RT prescriptions

## References

- **BED Formula**: BED = D × (1 + d/[α/β])
- **EQD2 Formula**: EQD2 = D × (d + α/β) / (2 + α/β)
- **Linear-Quadratic Model**: S = exp(-αD - βD²)

## License

Copyright (C) 2024 ALGT Project
