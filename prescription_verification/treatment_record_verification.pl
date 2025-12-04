%% treatment_record_verification.pl
%%
%% Verification predicates for comparing treatment records against
%% physician intent and treatment plan
%%
%% Copyright (C) 2024 ALGT Project

:- module(treatment_record_verification, [
    %% Treatment record structures
    treatment_record/6,
    fraction_record/5,

    %% Verification predicates
    verify_record_vs_plan/3,
    verify_record_vs_intent/3,
    verify_cumulative_dose/4,
    verify_fraction_sequence/3,

    %% Cumulative tracking
    cumulative_delivered_dose/2,
    remaining_fractions/3,
    remaining_dose/3,

    %% Deviation analysis
    analyze_delivery_deviations/3,
    significant_deviation/3,

    %% Treatment completion
    treatment_complete/2,
    treatment_on_track/3
]).

:- use_module(prescription_model).
:- use_module(prescription_validation).
:- use_module(biological_dose).

%% ============================================================
%% Treatment Record Structures
%% ============================================================

%% treatment_record(RecordId, PlanRef, PatientId, StartDate, FractionRecords, Status)
%%
%% - RecordId: Unique record identifier
%% - PlanRef: Reference to the treatment plan
%% - PatientId: Patient identifier
%% - StartDate: Treatment start date (date/3)
%% - FractionRecords: List of delivered fraction records
%% - Status: in_progress | completed | on_hold | discontinued

treatment_record(RecordId, PlanRef, PatientId, StartDate, FractionRecords, Status) :-
    atom(RecordId),
    atom(PlanRef),
    atom(PatientId),
    valid_date(StartDate),
    is_list(FractionRecords),
    valid_status(Status).

valid_date(date(Y, M, D)) :-
    integer(Y), Y > 2000, Y < 2100,
    integer(M), M >= 1, M =< 12,
    integer(D), D >= 1, D =< 31.

valid_status(in_progress).
valid_status(completed).
valid_status(on_hold).
valid_status(discontinued).

%% fraction_record(FractionNum, Date, DeliveredDose, MU, DeliveryNotes)
%%
%% - FractionNum: Fraction number (1-indexed)
%% - Date: Delivery date
%% - DeliveredDose: Actual delivered dose in cGy
%% - MU: Monitor units delivered
%% - DeliveryNotes: List of notes/flags

fraction_record(FractionNum, Date, DeliveredDose, MU, DeliveryNotes) :-
    integer(FractionNum), FractionNum > 0,
    valid_date(Date),
    number(DeliveredDose), DeliveredDose >= 0,
    number(MU), MU >= 0,
    is_list(DeliveryNotes).

%% ============================================================
%% Record vs Plan Verification
%% ============================================================

%% verify_record_vs_plan(+TreatmentRecord, +Plan, -Results)
verify_record_vs_plan(TreatmentRecord, Plan, Results) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    treatment_plan(_, PlanPrescription) = Plan,
    findall(Result,
        verify_record_check(FractionRecords, PlanPrescription, Result),
        Results).

verify_record_check(FractionRecords, Plan, Result) :-
    %% Verify each delivered fraction against planned dose
    member(FractionRec, FractionRecords),
    fraction_record(FracNum, _, DeliveredDose, _, _) = FractionRec,
    prescription_dose_per_fraction(Plan, PlannedDPF),
    dose_tolerance(standard, TolerancePct),
    Tolerance is PlannedDPF * TolerancePct / 100,
    Deviation is abs(DeliveredDose - PlannedDPF),
    (   Deviation =< Tolerance
    ->  Result = validation_passed(fraction_dose(FracNum))
    ;   Result = validation_failed(fraction_dose(FracNum),
            fraction_deviation(planned(PlannedDPF), delivered(DeliveredDose),
                              deviation(Deviation)))
    ).

%% ============================================================
%% Record vs Intent Verification
%% ============================================================

%% verify_record_vs_intent(+TreatmentRecord, +Intent, -Results)
verify_record_vs_intent(TreatmentRecord, Intent, Results) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    physician_intent(_, IntentPrescription) = Intent,

    %% Calculate cumulative delivered
    cumulative_delivered_dose(FractionRecords, CumulativeDose),
    prescription_total_dose(IntentPrescription, IntentTotal),

    length(FractionRecords, DeliveredFractions),
    prescription_fractions(IntentPrescription, IntentFractions),

    %% Generate results
    Results = [
        cumulative_dose_check(delivered(CumulativeDose), intended(IntentTotal)),
        fraction_progress(delivered(DeliveredFractions), intended(IntentFractions))
    ].

%% ============================================================
%% Cumulative Dose Verification
%% ============================================================

%% verify_cumulative_dose(+TreatmentRecord, +Plan, +ToleranceLevel, -Result)
verify_cumulative_dose(TreatmentRecord, Plan, ToleranceLevel, Result) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    treatment_plan(_, PlanPrescription) = Plan,

    %% Calculate what cumulative dose should be
    length(FractionRecords, DeliveredCount),
    prescription_dose_per_fraction(PlanPrescription, PlannedDPF),
    ExpectedCumulative is DeliveredCount * PlannedDPF,

    %% Calculate actual cumulative
    cumulative_delivered_dose(FractionRecords, ActualCumulative),

    %% Check tolerance
    dose_tolerance(ToleranceLevel, TolerancePct),
    Tolerance is ExpectedCumulative * TolerancePct / 100,
    Deviation is abs(ActualCumulative - ExpectedCumulative),

    (   Deviation =< Tolerance
    ->  Result = validation_passed(cumulative_dose)
    ;   Result = validation_failed(cumulative_dose,
            cumulative_deviation(
                expected(ExpectedCumulative), actual(ActualCumulative),
                deviation_pct(Deviation / ExpectedCumulative * 100)))
    ).

%% ============================================================
%% Fraction Sequence Verification
%% ============================================================

%% verify_fraction_sequence(+TreatmentRecord, +MaxGapDays, -Result)
%% Verifies treatment continuity (no gaps > MaxGapDays)
verify_fraction_sequence(TreatmentRecord, MaxGapDays, Result) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    extract_dates(FractionRecords, Dates),
    sort(Dates, SortedDates),
    find_gaps(SortedDates, MaxGapDays, Gaps),
    (   Gaps = []
    ->  Result = validation_passed(treatment_continuity)
    ;   Result = validation_warning(treatment_continuity,
            treatment_gaps(Gaps))
    ).

extract_dates([], []).
extract_dates([fraction_record(_, Date, _, _, _) | Rest], [Date | Dates]) :-
    extract_dates(Rest, Dates).

find_gaps([], _, []).
find_gaps([_], _, []).
find_gaps([Date1, Date2 | Rest], MaxGap, Gaps) :-
    days_between(Date1, Date2, DaysBetween),
    find_gaps([Date2 | Rest], MaxGap, RestGaps),
    (   DaysBetween > MaxGap
    ->  Gaps = [gap(Date1, Date2, DaysBetween) | RestGaps]
    ;   Gaps = RestGaps
    ).

%% Simplified days_between (placeholder)
days_between(date(Y1, M1, D1), date(Y2, M2, D2), Days) :-
    Days is (Y2 - Y1) * 365 + (M2 - M1) * 30 + (D2 - D1).

%% ============================================================
%% Cumulative Tracking
%% ============================================================

%% cumulative_delivered_dose(+FractionRecords, -TotalDose)
cumulative_delivered_dose([], 0).
cumulative_delivered_dose([FracRec | Rest], Total) :-
    fraction_record(_, _, Dose, _, _) = FracRec,
    cumulative_delivered_dose(Rest, RestTotal),
    Total is Dose + RestTotal.

%% remaining_fractions(+TreatmentRecord, +Plan, -Remaining)
remaining_fractions(TreatmentRecord, Plan, Remaining) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    treatment_plan(_, PlanPrescription) = Plan,
    length(FractionRecords, Delivered),
    prescription_fractions(PlanPrescription, Planned),
    Remaining is Planned - Delivered.

%% remaining_dose(+TreatmentRecord, +Plan, -RemainingDose)
remaining_dose(TreatmentRecord, Plan, RemainingDose) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    treatment_plan(_, PlanPrescription) = Plan,
    cumulative_delivered_dose(FractionRecords, Delivered),
    prescription_total_dose(PlanPrescription, Planned),
    RemainingDose is Planned - Delivered.

%% ============================================================
%% Deviation Analysis
%% ============================================================

%% analyze_delivery_deviations(+TreatmentRecord, +Plan, -Analysis)
analyze_delivery_deviations(TreatmentRecord, Plan, Analysis) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    treatment_plan(_, PlanPrescription) = Plan,
    prescription_dose_per_fraction(PlanPrescription, PlannedDPF),

    %% Calculate deviations for each fraction
    findall(deviation(FracNum, DevPct),
        (   member(FracRec, FractionRecords),
            fraction_record(FracNum, _, Delivered, _, _) = FracRec,
            DevPct is (Delivered - PlannedDPF) / PlannedDPF * 100
        ),
        Deviations),

    %% Calculate statistics
    extract_deviation_values(Deviations, Values),
    (   Values = []
    ->  Analysis = no_fractions_delivered
    ;   average(Values, MeanDev),
        max_abs_deviation(Values, MaxDev),
        Analysis = deviation_analysis(
            mean_deviation_pct(MeanDev),
            max_deviation_pct(MaxDev),
            fraction_deviations(Deviations))
    ).

extract_deviation_values([], []).
extract_deviation_values([deviation(_, V) | Rest], [V | Values]) :-
    extract_deviation_values(Rest, Values).

average(List, Avg) :-
    length(List, N), N > 0,
    sumlist(List, Sum),
    Avg is Sum / N.

max_abs_deviation(List, Max) :-
    maplist(abs, List, AbsList),
    max_list(AbsList, Max).

%% significant_deviation(+Deviation, +Threshold, -Significant)
significant_deviation(deviation(FracNum, DevPct), Threshold, Result) :-
    (   abs(DevPct) > Threshold
    ->  Result = significant(FracNum, DevPct)
    ;   Result = within_tolerance(FracNum, DevPct)
    ).

%% ============================================================
%% Treatment Completion Checks
%% ============================================================

%% treatment_complete(+TreatmentRecord, +Plan)
%% True if all planned fractions have been delivered
treatment_complete(TreatmentRecord, Plan) :-
    remaining_fractions(TreatmentRecord, Plan, 0),
    treatment_record(_, _, _, _, _, completed) = TreatmentRecord.

%% treatment_on_track(+TreatmentRecord, +Plan, +ToleranceLevel)
%% True if treatment is progressing within tolerance
treatment_on_track(TreatmentRecord, Plan, ToleranceLevel) :-
    verify_cumulative_dose(TreatmentRecord, Plan, ToleranceLevel, Result),
    Result = validation_passed(_).

%% ============================================================
%% Biological Dose Tracking
%% ============================================================

%% cumulative_bed(+TreatmentRecord, +AlphaBeta, -CumulativeBED)
%% Calculates cumulative BED from delivered fractions
cumulative_bed(TreatmentRecord, AlphaBeta, CumulativeBED) :-
    treatment_record(_, _, _, _, FractionRecords, _) = TreatmentRecord,
    findall(FracBED,
        (   member(FracRec, FractionRecords),
            fraction_record(_, _, DoseCGy, _, _) = FracRec,
            cgy_to_gy(DoseCGy, DoseGy),
            bed(DoseGy, DoseGy, AlphaBeta, FracBED)  %% Single fraction
        ),
        FracBEDs),
    sumlist(FracBEDs, CumulativeBED).

%% remaining_bed(+TreatmentRecord, +Plan, +AlphaBeta, -RemainingBED)
remaining_bed(TreatmentRecord, Plan, AlphaBeta, RemainingBED) :-
    %% Calculate total planned BED
    treatment_plan(_, PlanPrescription) = Plan,
    prescription_total_dose(PlanPrescription, TotalDoseCGy),
    prescription_dose_per_fraction(PlanPrescription, DPFCGy),
    cgy_to_gy(TotalDoseCGy, TotalDoseGy),
    cgy_to_gy(DPFCGy, DPFGy),
    bed(TotalDoseGy, DPFGy, AlphaBeta, PlannedBED),

    %% Calculate delivered BED
    cumulative_bed(TreatmentRecord, AlphaBeta, DeliveredBED),

    RemainingBED is PlannedBED - DeliveredBED.
