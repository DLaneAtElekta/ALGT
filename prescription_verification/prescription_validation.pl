%% prescription_validation.pl
%%
%% Validation predicates for comparing physician intent vs treatment plan
%% Provides comprehensive verification of prescription parameters
%%
%% Copyright (C) 2024 ALGT Project

:- module(prescription_validation, [
    %% Core validation
    validate_prescription/2,
    validate_intent_vs_plan/3,
    validate_intent_vs_plan/4,

    %% Specific validations
    validate_total_dose/4,
    validate_fractions/4,
    validate_dose_per_fraction/4,
    validate_biological_dose/5,
    validate_phases/4,
    validate_target_coverage/4,

    %% Tolerance specifications
    dose_tolerance/2,
    fraction_tolerance/2,
    bed_tolerance/2,

    %% Validation results
    validation_passed/1,
    validation_failed/2,
    validation_warning/2,

    %% Aggregate validation
    all_validations_pass/1,
    collect_validation_errors/2,
    collect_validation_warnings/2
]).

:- use_module(prescription_model).
:- use_module(biological_dose).

%% ============================================================
%% Tolerance Specifications
%% ============================================================
%%
%% Configurable tolerances for validation comparisons

%% dose_tolerance(+ToleranceType, -Value)
%% Dose tolerance in percentage
dose_tolerance(strict, 1.0).        %% 1% for strict validation
dose_tolerance(standard, 3.0).      %% 3% standard tolerance
dose_tolerance(relaxed, 5.0).       %% 5% for relaxed validation

%% fraction_tolerance(+ToleranceType, -Value)
%% Fraction tolerance (absolute number)
fraction_tolerance(strict, 0).
fraction_tolerance(standard, 0).
fraction_tolerance(relaxed, 1).

%% bed_tolerance(+ToleranceType, -Value)
%% BED tolerance in Gy
bed_tolerance(strict, 2.0).
bed_tolerance(standard, 5.0).
bed_tolerance(relaxed, 10.0).

%% ============================================================
%% Validation Result Types
%% ============================================================

%% validation_passed(+CheckName)
validation_passed(CheckName) :-
    atom(CheckName).

%% validation_failed(+CheckName, +Reason)
validation_failed(CheckName, Reason) :-
    atom(CheckName),
    nonvar(Reason).

%% validation_warning(+CheckName, +Message)
validation_warning(CheckName, Message) :-
    atom(CheckName),
    nonvar(Message).

%% ============================================================
%% Core Validation Predicates
%% ============================================================

%% validate_prescription(+Prescription, -Results)
%% Validates a single prescription for internal consistency
validate_prescription(Prescription, Results) :-
    prescription_id(Prescription, _),
    findall(Result,
        validate_prescription_check(Prescription, Result),
        Results).

validate_prescription_check(Prescription, Result) :-
    %% Check dose consistency: TotalDose = Fractions * DosePerFraction
    prescription_total_dose(Prescription, TotalDose),
    prescription_fractions(Prescription, Fractions),
    prescription_dose_per_fraction(Prescription, DPF),
    ExpectedTotal is Fractions * DPF,
    (   abs(TotalDose - ExpectedTotal) < 0.01
    ->  Result = validation_passed(dose_consistency)
    ;   Result = validation_failed(dose_consistency,
            dose_mismatch(expected(ExpectedTotal), actual(TotalDose)))
    ).

validate_prescription_check(Prescription, Result) :-
    %% Check phase consistency if phases exist
    prescription_phases(Prescription, Phases),
    prescription_total_dose(Prescription, TotalDose),
    (   Phases = []
    ->  Result = validation_passed(phase_consistency)
    ;   sum_phase_doses(Phases, PhaseTotal),
        (   abs(TotalDose - PhaseTotal) < 0.01
        ->  Result = validation_passed(phase_consistency)
        ;   Result = validation_failed(phase_consistency,
                phase_dose_mismatch(expected(TotalDose), actual(PhaseTotal)))
        )
    ).

sum_phase_doses([], 0).
sum_phase_doses([Phase | Rest], Total) :-
    phase_dose(Phase, Dose),
    sum_phase_doses(Rest, RestTotal),
    Total is Dose + RestTotal.

%% ============================================================
%% Intent vs Plan Validation
%% ============================================================

%% validate_intent_vs_plan(+Intent, +Plan, -Results)
%% Uses standard tolerance
validate_intent_vs_plan(Intent, Plan, Results) :-
    validate_intent_vs_plan(Intent, Plan, standard, Results).

%% validate_intent_vs_plan(+Intent, +Plan, +ToleranceLevel, -Results)
%% Compares physician intent against treatment plan
validate_intent_vs_plan(Intent, Plan, ToleranceLevel, Results) :-
    physician_intent(_, IntentPrescription) = Intent,
    treatment_plan(_, PlanPrescription) = Plan,
    findall(Result,
        validate_comparison(IntentPrescription, PlanPrescription,
                           ToleranceLevel, Result),
        Results).

%% Individual comparison checks
validate_comparison(Intent, Plan, ToleranceLevel, Result) :-
    validate_total_dose(Intent, Plan, ToleranceLevel, Result).

validate_comparison(Intent, Plan, ToleranceLevel, Result) :-
    validate_fractions(Intent, Plan, ToleranceLevel, Result).

validate_comparison(Intent, Plan, ToleranceLevel, Result) :-
    validate_dose_per_fraction(Intent, Plan, ToleranceLevel, Result).

validate_comparison(Intent, Plan, ToleranceLevel, Result) :-
    validate_modality(Intent, Plan, Result).

validate_comparison(Intent, Plan, ToleranceLevel, Result) :-
    validate_biological_dose(Intent, Plan, ToleranceLevel, tumor, Result).

%% ============================================================
%% Total Dose Validation
%% ============================================================

%% validate_total_dose(+Intent, +Plan, +ToleranceLevel, -Result)
validate_total_dose(Intent, Plan, ToleranceLevel, Result) :-
    prescription_total_dose(Intent, IntentDose),
    prescription_total_dose(Plan, PlanDose),
    dose_tolerance(ToleranceLevel, TolerancePct),
    Tolerance is IntentDose * TolerancePct / 100,
    Difference is abs(IntentDose - PlanDose),
    (   Difference =< Tolerance
    ->  Result = validation_passed(total_dose)
    ;   Result = validation_failed(total_dose,
            dose_deviation(intent(IntentDose), plan(PlanDose),
                          difference(Difference), tolerance(Tolerance)))
    ).

%% ============================================================
%% Fraction Count Validation
%% ============================================================

%% validate_fractions(+Intent, +Plan, +ToleranceLevel, -Result)
validate_fractions(Intent, Plan, ToleranceLevel, Result) :-
    prescription_fractions(Intent, IntentFractions),
    prescription_fractions(Plan, PlanFractions),
    fraction_tolerance(ToleranceLevel, Tolerance),
    Difference is abs(IntentFractions - PlanFractions),
    (   Difference =< Tolerance
    ->  Result = validation_passed(fraction_count)
    ;   Result = validation_failed(fraction_count,
            fraction_deviation(intent(IntentFractions), plan(PlanFractions)))
    ).

%% ============================================================
%% Dose Per Fraction Validation
%% ============================================================

%% validate_dose_per_fraction(+Intent, +Plan, +ToleranceLevel, -Result)
validate_dose_per_fraction(Intent, Plan, ToleranceLevel, Result) :-
    prescription_dose_per_fraction(Intent, IntentDPF),
    prescription_dose_per_fraction(Plan, PlanDPF),
    dose_tolerance(ToleranceLevel, TolerancePct),
    Tolerance is IntentDPF * TolerancePct / 100,
    Difference is abs(IntentDPF - PlanDPF),
    (   Difference =< Tolerance
    ->  Result = validation_passed(dose_per_fraction)
    ;   Result = validation_failed(dose_per_fraction,
            dpf_deviation(intent(IntentDPF), plan(PlanDPF),
                         difference(Difference)))
    ).

%% ============================================================
%% Modality Validation
%% ============================================================

%% validate_modality(+Intent, +Plan, -Result)
validate_modality(Intent, Plan, Result) :-
    prescription_modality(Intent, IntentModality),
    prescription_modality(Plan, PlanModality),
    (   compatible_modalities(IntentModality, PlanModality)
    ->  Result = validation_passed(modality)
    ;   Result = validation_failed(modality,
            modality_mismatch(intent(IntentModality), plan(PlanModality)))
    ).

%% compatible_modalities(+Modality1, +Modality2)
%% Defines which modalities are considered compatible
compatible_modalities(M, M) :- !.  %% Same modality always compatible
compatible_modalities(photon, imrt).
compatible_modalities(photon, vmat).
compatible_modalities(photon, '3dcrt').
compatible_modalities(photon, tomo).
compatible_modalities(imrt, vmat).
compatible_modalities(imrt, tomo).
compatible_modalities(sbrt, vmat).
compatible_modalities(sbrt, imrt).
compatible_modalities(M1, M2) :- compatible_modalities(M2, M1).

%% ============================================================
%% Biological Dose Validation
%% ============================================================

%% validate_biological_dose(+Intent, +Plan, +ToleranceLevel,
%%                          +TissueType, -Result)
validate_biological_dose(Intent, Plan, ToleranceLevel, TissueType, Result) :-
    %% Get prescription parameters
    prescription_total_dose(Intent, IntentDose),
    prescription_dose_per_fraction(Intent, IntentDPF),
    prescription_total_dose(Plan, PlanDose),
    prescription_dose_per_fraction(Plan, PlanDPF),

    %% Convert to Gy
    cgy_to_gy(IntentDose, IntentDoseGy),
    cgy_to_gy(IntentDPF, IntentDPFGy),
    cgy_to_gy(PlanDose, PlanDoseGy),
    cgy_to_gy(PlanDPF, PlanDPFGy),

    %% Get alpha/beta ratio
    (   alpha_beta_ratio(TissueType, AlphaBeta)
    ->  true
    ;   default_alpha_beta(tumor, AlphaBeta)
    ),

    %% Calculate BED values
    bed(IntentDoseGy, IntentDPFGy, AlphaBeta, IntentBED),
    bed(PlanDoseGy, PlanDPFGy, AlphaBeta, PlanBED),

    %% Calculate EQD2 values
    eqd2(IntentDoseGy, IntentDPFGy, AlphaBeta, IntentEQD2),
    eqd2(PlanDoseGy, PlanDPFGy, AlphaBeta, PlanEQD2),

    %% Check tolerance
    bed_tolerance(ToleranceLevel, BEDTol),
    BEDDiff is abs(IntentBED - PlanBED),
    EQD2Diff is abs(IntentEQD2 - PlanEQD2),

    (   BEDDiff =< BEDTol
    ->  Result = validation_passed(biological_dose)
    ;   Result = validation_failed(biological_dose,
            bed_deviation(
                intent_bed(IntentBED), plan_bed(PlanBED),
                intent_eqd2(IntentEQD2), plan_eqd2(PlanEQD2),
                bed_difference(BEDDiff), eqd2_difference(EQD2Diff),
                alpha_beta(AlphaBeta)))
    ).

%% ============================================================
%% Multi-Phase Validation
%% ============================================================

%% validate_phases(+Intent, +Plan, +ToleranceLevel, -Results)
validate_phases(Intent, Plan, ToleranceLevel, Results) :-
    prescription_phases(Intent, IntentPhases),
    prescription_phases(Plan, PlanPhases),
    (   IntentPhases = [], PlanPhases = []
    ->  Results = [validation_passed(phases_not_applicable)]
    ;   length(IntentPhases, IntentCount),
        length(PlanPhases, PlanCount),
        (   IntentCount =\= PlanCount
        ->  Results = [validation_failed(phase_count,
                count_mismatch(intent(IntentCount), plan(PlanCount)))]
        ;   findall(PhaseResult,
                validate_phase_pair(IntentPhases, PlanPhases,
                                   ToleranceLevel, PhaseResult),
                Results)
        )
    ).

validate_phase_pair(IntentPhases, PlanPhases, ToleranceLevel, Result) :-
    member(IntentPhase, IntentPhases),
    phase_name(IntentPhase, PhaseName),
    (   find_phase_by_name(PlanPhases, PhaseName, PlanPhase)
    ->  validate_single_phase(IntentPhase, PlanPhase, ToleranceLevel, Result)
    ;   Result = validation_failed(phase_missing,
            missing_phase(PhaseName))
    ).

find_phase_by_name([Phase | _], Name, Phase) :-
    phase_name(Phase, Name), !.
find_phase_by_name([_ | Rest], Name, Phase) :-
    find_phase_by_name(Rest, Name, Phase).

validate_single_phase(IntentPhase, PlanPhase, ToleranceLevel, Result) :-
    phase_name(IntentPhase, PhaseName),
    phase_dose(IntentPhase, IntentDose),
    phase_dose(PlanPhase, PlanDose),
    dose_tolerance(ToleranceLevel, TolerancePct),
    Tolerance is IntentDose * TolerancePct / 100,
    Difference is abs(IntentDose - PlanDose),
    (   Difference =< Tolerance
    ->  Result = validation_passed(phase_dose(PhaseName))
    ;   Result = validation_failed(phase_dose(PhaseName),
            phase_deviation(intent(IntentDose), plan(PlanDose)))
    ).

%% ============================================================
%% Target Coverage Validation
%% ============================================================

%% validate_target_coverage(+Intent, +PlanDVH, +CoverageSpec, -Result)
%% PlanDVH is a structure containing DVH data
%% CoverageSpec defines required coverage (e.g., V95 > 95%)
validate_target_coverage(Intent, PlanDVH, CoverageSpec, Result) :-
    prescription_target(Intent, Target),
    target_volume(TargetName, _, _) = Target,

    %% Extract coverage requirement
    coverage_requirement(CoverageSpec, DoseLevel, MinCoverage),

    %% Get actual coverage from DVH
    (   dvh_coverage(PlanDVH, TargetName, DoseLevel, ActualCoverage)
    ->  (   ActualCoverage >= MinCoverage
        ->  Result = validation_passed(target_coverage(TargetName))
        ;   Result = validation_failed(target_coverage(TargetName),
                insufficient_coverage(
                    required(MinCoverage), actual(ActualCoverage),
                    dose_level(DoseLevel)))
        )
    ;   Result = validation_warning(target_coverage(TargetName),
            dvh_data_not_available)
    ).

%% coverage_requirement(+Spec, -DoseLevel, -MinCoverage)
%% Parses coverage specification
coverage_requirement(v95_gt(Min), 95, Min).
coverage_requirement(v100_gt(Min), 100, Min).
coverage_requirement(v(DoseLevel, Min), DoseLevel, Min).

%% dvh_coverage(+DVH, +TargetName, +DoseLevel, -Coverage)
%% Placeholder for DVH lookup
dvh_coverage(DVH, TargetName, DoseLevel, Coverage) :-
    is_dict(DVH),
    get_dict(TargetName, DVH, TargetDVH),
    get_dict(DoseLevel, TargetDVH, Coverage).

%% ============================================================
%% Aggregate Validation Helpers
%% ============================================================

%% all_validations_pass(+Results)
%% True if all results are passed
all_validations_pass([]).
all_validations_pass([validation_passed(_) | Rest]) :-
    all_validations_pass(Rest).

%% collect_validation_errors(+Results, -Errors)
collect_validation_errors(Results, Errors) :-
    findall(Error,
        (   member(Result, Results),
            Result = validation_failed(_, _),
            Error = Result
        ),
        Errors).

%% collect_validation_warnings(+Results, -Warnings)
collect_validation_warnings(Results, Warnings) :-
    findall(Warning,
        (   member(Result, Results),
            Result = validation_warning(_, _),
            Warning = Result
        ),
        Warnings).
