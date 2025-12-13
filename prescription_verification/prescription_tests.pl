%% prescription_tests.pl
%%
%% Test cases for prescription validation system
%%
%% Run with: swipl -g run_tests -t halt prescription_tests.pl
%%
%% Copyright (C) 2024 ALGT Project

:- use_module(prescription_model).
:- use_module(biological_dose).
:- use_module(prescription_validation).
:- use_module(treatment_record_verification).

:- use_module(library(plunit)).

%% ============================================================
%% Test Data
%% ============================================================

%% Standard prostate prescription (78 Gy in 39 fractions)
test_prostate_intent(Intent) :-
    Target = target_volume(ptv_prostate, ptv, pelvis),
    Prescription = prescription(
        rx_prostate_001,
        Target,
        7800,           %% 78 Gy total in cGy
        39,             %% 39 fractions
        200,            %% 2 Gy per fraction in cGy
        imrt,
        []              %% No phases
    ),
    Intent = physician_intent(intent_001, Prescription).

%% Matching plan (within tolerance)
test_prostate_plan_matching(Plan) :-
    Target = target_volume(ptv_prostate, ptv, pelvis),
    Prescription = prescription(
        plan_prostate_001,
        Target,
        7800,
        39,
        200,
        vmat,           %% Different but compatible modality
        []
    ),
    Plan = treatment_plan(plan_001, Prescription).

%% Plan with dose deviation
test_prostate_plan_deviated(Plan) :-
    Target = target_volume(ptv_prostate, ptv, pelvis),
    Prescription = prescription(
        plan_prostate_002,
        Target,
        7600,           %% 76 Gy - 2.6% under
        38,             %% One less fraction
        200,
        vmat,
        []
    ),
    Plan = treatment_plan(plan_002, Prescription).

%% Multi-phase breast prescription
test_breast_intent(Intent) :-
    Target = target_volume(ptv_breast, ptv, chest_wall),
    Phase1 = phase(whole_breast, 5000, 25, 200, tangents),
    Phase2 = phase(boost, 1000, 5, 200, electrons),
    Prescription = prescription(
        rx_breast_001,
        Target,
        6000,           %% 60 Gy total
        30,             %% 30 total fractions
        200,            %% 2 Gy per fraction
        photon,
        [Phase1, Phase2]
    ),
    Intent = physician_intent(intent_breast_001, Prescription).

%% SBRT lung prescription (hypofractionated)
test_sbrt_intent(Intent) :-
    Target = target_volume(ptv_lung, ptv, lung_right),
    Prescription = prescription(
        rx_sbrt_001,
        Target,
        5400,           %% 54 Gy total
        3,              %% 3 fractions
        1800,           %% 18 Gy per fraction
        sbrt,
        []
    ),
    Intent = physician_intent(intent_sbrt_001, Prescription).

%% ============================================================
%% Biological Dose Tests
%% ============================================================

:- begin_tests(biological_dose).

test(bed_calculation) :-
    %% Standard 2 Gy fractions, 60 Gy total, α/β = 10
    bed(60, 2, 10, BED),
    abs(BED - 72) < 0.01.  %% BED = 60 * (1 + 2/10) = 72 Gy

test(bed_hypofractionated) :-
    %% SBRT: 54 Gy in 3 fractions (18 Gy/fx), α/β = 10
    bed(54, 18, 10, BED),
    abs(BED - 151.2) < 0.1.  %% BED = 54 * (1 + 18/10) = 151.2 Gy

test(eqd2_calculation) :-
    %% Convert SBRT to EQD2
    eqd2(54, 18, 10, EQD2),
    abs(EQD2 - 126) < 0.1.  %% EQD2 = 54 * (18 + 10) / (2 + 10) = 126 Gy

test(eqd2_conventional) :-
    %% 60 Gy at 2 Gy/fx should give EQD2 = 60 Gy
    eqd2(60, 2, 10, EQD2),
    abs(EQD2 - 60) < 0.01.

test(bed_prostate_low_alpha_beta) :-
    %% Prostate with α/β = 1.5
    %% 78 Gy at 2 Gy/fx
    bed(78, 2, 1.5, BED),
    ExpectedBED is 78 * (1 + 2/1.5),
    abs(BED - ExpectedBED) < 0.01.

test(is_hypofractionated_true) :-
    is_hypofractionated(5.0, 10).  %% 5 Gy/fx is hypofractionated

test(is_hypofractionated_false, [fail]) :-
    is_hypofractionated(2.0, 10).  %% 2 Gy/fx is not hypofractionated

test(is_conventional_true) :-
    is_conventional_fractionation(2.0, 10).

test(dose_conversion) :-
    gy_to_cgy(2, CGy),
    CGy =:= 200,
    cgy_to_gy(200, Gy),
    Gy =:= 2.

:- end_tests(biological_dose).

%% ============================================================
%% Prescription Validation Tests
%% ============================================================

:- begin_tests(prescription_validation).

test(validate_matching_prescriptions) :-
    test_prostate_intent(Intent),
    test_prostate_plan_matching(Plan),
    validate_intent_vs_plan(Intent, Plan, standard, Results),
    all_validations_pass(Results).

test(validate_dose_deviation) :-
    test_prostate_intent(Intent),
    test_prostate_plan_deviated(Plan),
    validate_intent_vs_plan(Intent, Plan, standard, Results),
    collect_validation_errors(Results, Errors),
    length(Errors, ErrorCount),
    ErrorCount > 0.

test(validate_total_dose_within_tolerance) :-
    test_prostate_intent(physician_intent(_, IntentRx)),
    test_prostate_plan_matching(treatment_plan(_, PlanRx)),
    validate_total_dose(IntentRx, PlanRx, standard, Result),
    Result = validation_passed(total_dose).

test(validate_biological_dose_match) :-
    test_prostate_intent(physician_intent(_, IntentRx)),
    test_prostate_plan_matching(treatment_plan(_, PlanRx)),
    validate_biological_dose(IntentRx, PlanRx, standard, tumor, Result),
    Result = validation_passed(biological_dose).

test(compatible_modalities) :-
    compatible_modalities(photon, imrt),
    compatible_modalities(imrt, vmat),
    compatible_modalities(sbrt, vmat).

test(incompatible_modalities, [fail]) :-
    compatible_modalities(photon, proton).

:- end_tests(prescription_validation).

%% ============================================================
%% Multi-Phase Tests
%% ============================================================

:- begin_tests(multi_phase).

test(phase_dose_sum) :-
    test_breast_intent(physician_intent(_, Rx)),
    prescription_phases(Rx, Phases),
    prescription_total_dose(Rx, TotalDose),
    sum_phase_doses(Phases, PhaseSum),
    abs(TotalDose - PhaseSum) < 0.01.

test(total_bed_multiphase) :-
    Phase1 = phase(primary, 5000, 25, 200, imrt),
    Phase2 = phase(boost, 1000, 5, 200, electrons),
    Phases = [Phase1, Phase2],
    total_bed(Phases, 10, TotalBED),
    %% Phase 1: 50 Gy * (1 + 2/10) = 60 Gy BED
    %% Phase 2: 10 Gy * (1 + 2/10) = 12 Gy BED
    %% Total: 72 Gy BED
    abs(TotalBED - 72) < 0.1.

:- end_tests(multi_phase).

%% ============================================================
%% Treatment Record Tests
%% ============================================================

:- begin_tests(treatment_records).

test(cumulative_dose_calculation) :-
    FractionRecords = [
        fraction_record(1, date(2024, 1, 1), 200, 250, []),
        fraction_record(2, date(2024, 1, 2), 200, 250, []),
        fraction_record(3, date(2024, 1, 3), 198, 248, [])
    ],
    cumulative_delivered_dose(FractionRecords, Total),
    Total =:= 598.

test(remaining_fractions_calc) :-
    test_prostate_plan_matching(Plan),
    FractionRecords = [
        fraction_record(1, date(2024, 1, 1), 200, 250, []),
        fraction_record(2, date(2024, 1, 2), 200, 250, [])
    ],
    Record = treatment_record(rec_001, plan_001, patient_001,
                              date(2024, 1, 1), FractionRecords, in_progress),
    remaining_fractions(Record, Plan, Remaining),
    Remaining =:= 37.

test(treatment_on_track) :-
    test_prostate_plan_matching(Plan),
    FractionRecords = [
        fraction_record(1, date(2024, 1, 1), 200, 250, []),
        fraction_record(2, date(2024, 1, 2), 200, 250, []),
        fraction_record(3, date(2024, 1, 3), 200, 250, [])
    ],
    Record = treatment_record(rec_001, plan_001, patient_001,
                              date(2024, 1, 1), FractionRecords, in_progress),
    treatment_on_track(Record, Plan, standard).

:- end_tests(treatment_records).

%% ============================================================
%% Integration Tests
%% ============================================================

:- begin_tests(integration).

test(full_workflow_prostate) :-
    %% 1. Create intent
    test_prostate_intent(Intent),

    %% 2. Create matching plan
    test_prostate_plan_matching(Plan),

    %% 3. Validate intent vs plan
    validate_intent_vs_plan(Intent, Plan, Results),
    all_validations_pass(Results),

    %% 4. Simulate treatment delivery (first 5 fractions)
    FractionRecords = [
        fraction_record(1, date(2024, 1, 1), 200, 250, []),
        fraction_record(2, date(2024, 1, 2), 200, 250, []),
        fraction_record(3, date(2024, 1, 3), 201, 251, []),
        fraction_record(4, date(2024, 1, 4), 199, 249, []),
        fraction_record(5, date(2024, 1, 5), 200, 250, [])
    ],
    Record = treatment_record(rec_001, plan_001, patient_001,
                              date(2024, 1, 1), FractionRecords, in_progress),

    %% 5. Verify treatment record vs plan
    verify_cumulative_dose(Record, Plan, standard, DoseResult),
    DoseResult = validation_passed(_),

    %% 6. Check remaining treatment
    remaining_fractions(Record, Plan, RemFrac),
    RemFrac =:= 34,
    remaining_dose(Record, Plan, RemDose),
    RemDose =:= 6800.

test(biological_dose_comparison_sbrt_vs_conventional) :-
    %% Compare SBRT (54 Gy / 3 fx) vs conventional (60 Gy / 30 fx)
    %% Using α/β = 10 for tumor

    %% SBRT
    bed(54, 18, 10, SBRT_BED),
    eqd2(54, 18, 10, SBRT_EQD2),

    %% Conventional
    bed(60, 2, 10, Conv_BED),
    eqd2(60, 2, 10, Conv_EQD2),

    %% SBRT has higher biological effect
    SBRT_BED > Conv_BED,
    SBRT_EQD2 > Conv_EQD2,

    %% Print comparison (for documentation)
    format("SBRT: BED=~2f Gy, EQD2=~2f Gy~n", [SBRT_BED, SBRT_EQD2]),
    format("Conv: BED=~2f Gy, EQD2=~2f Gy~n", [Conv_BED, Conv_EQD2]).

:- end_tests(integration).

%% Helper predicate used in tests
sum_phase_doses([], 0).
sum_phase_doses([Phase | Rest], Total) :-
    phase_dose(Phase, Dose),
    sum_phase_doses(Rest, RestTotal),
    Total is Dose + RestTotal.

%% Run all tests
:- initialization(run_tests, main).
