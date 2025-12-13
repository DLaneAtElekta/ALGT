%% biological_dose.pl
%%
%% Biological dose calculations for radiation therapy
%% Includes BED (Biologically Effective Dose) and EQD2 calculations
%%
%% Copyright (C) 2024 ALGT Project

:- module(biological_dose, [
    %% Core calculations
    bed/4,
    eqd2/4,

    %% Multi-phase calculations
    total_bed/3,
    total_eqd2/3,

    %% Alpha/Beta ratios
    alpha_beta_ratio/2,
    default_alpha_beta/2,

    %% Dose conversions
    gy_to_cgy/2,
    cgy_to_gy/2,

    %% Fractionation analysis
    is_hypofractionated/2,
    is_hyperfractionated/2,
    is_conventional_fractionation/2,

    %% Time factor corrections (incomplete repair)
    bed_with_time_factor/6
]).

%% ============================================================
%% Biologically Effective Dose (BED)
%% ============================================================
%%
%% BED = n * d * (1 + d / (α/β))
%%
%% where:
%%   n = number of fractions
%%   d = dose per fraction (Gy)
%%   α/β = alpha/beta ratio (Gy)

%% bed(+TotalDose, +DosePerFraction, +AlphaBeta, -BED)
%% All doses in Gy
bed(TotalDose, DosePerFraction, AlphaBeta, BED) :-
    number(TotalDose),
    number(DosePerFraction),
    number(AlphaBeta),
    AlphaBeta > 0,
    DosePerFraction > 0,
    BED is TotalDose * (1 + DosePerFraction / AlphaBeta).

%% ============================================================
%% Equivalent Dose in 2 Gy Fractions (EQD2)
%% ============================================================
%%
%% EQD2 = BED / (1 + 2 / (α/β))
%%      = D * (d + α/β) / (2 + α/β)
%%
%% where:
%%   D = total dose
%%   d = dose per fraction
%%   α/β = alpha/beta ratio

%% eqd2(+TotalDose, +DosePerFraction, +AlphaBeta, -EQD2)
%% All doses in Gy
eqd2(TotalDose, DosePerFraction, AlphaBeta, EQD2) :-
    number(TotalDose),
    number(DosePerFraction),
    number(AlphaBeta),
    AlphaBeta > 0,
    EQD2 is TotalDose * (DosePerFraction + AlphaBeta) / (2 + AlphaBeta).

%% ============================================================
%% Multi-Phase Calculations
%% ============================================================

%% total_bed(+Phases, +AlphaBeta, -TotalBED)
%% Calculates cumulative BED across multiple phases
%% Each phase is phase(Name, Dose, Fractions, DosePerFraction, Technique)
total_bed([], _, 0).
total_bed([Phase | Rest], AlphaBeta, TotalBED) :-
    phase_dose_gy(Phase, DoseGy),
    phase_dpf_gy(Phase, DPFGy),
    bed(DoseGy, DPFGy, AlphaBeta, PhaseBED),
    total_bed(Rest, AlphaBeta, RestBED),
    TotalBED is PhaseBED + RestBED.

%% total_eqd2(+Phases, +AlphaBeta, -TotalEQD2)
%% Calculates cumulative EQD2 across multiple phases
total_eqd2([], _, 0).
total_eqd2([Phase | Rest], AlphaBeta, TotalEQD2) :-
    phase_dose_gy(Phase, DoseGy),
    phase_dpf_gy(Phase, DPFGy),
    eqd2(DoseGy, DPFGy, AlphaBeta, PhaseEQD2),
    total_eqd2(Rest, AlphaBeta, RestEQD2),
    TotalEQD2 is PhaseEQD2 + RestEQD2.

%% Helper to extract dose in Gy from phase (assumes cGy input)
phase_dose_gy(phase(_, Dose, _, _, _), DoseGy) :-
    cgy_to_gy(Dose, DoseGy).

phase_dpf_gy(phase(_, _, _, DPF, _), DPFGy) :-
    cgy_to_gy(DPF, DPFGy).

%% ============================================================
%% Alpha/Beta Ratios
%% ============================================================
%%
%% Common α/β values for different tissue types

%% alpha_beta_ratio(+TissueType, -Ratio)
alpha_beta_ratio(tumor_high, 10).           %% Most tumors
alpha_beta_ratio(tumor_low, 3).             %% Prostate, melanoma
alpha_beta_ratio(early_responding, 10).     %% Acute effects
alpha_beta_ratio(late_responding, 3).       %% Late effects
alpha_beta_ratio(prostate, 1.5).            %% Prostate cancer
alpha_beta_ratio(breast, 4).                %% Breast cancer
alpha_beta_ratio(melanoma, 2.5).            %% Melanoma
alpha_beta_ratio(lung_nsclc, 10).           %% Non-small cell lung
alpha_beta_ratio(head_neck, 10).            %% Head and neck
alpha_beta_ratio(spinal_cord, 2).           %% Spinal cord (late)
alpha_beta_ratio(brain, 2).                 %% Brain (late effects)
alpha_beta_ratio(lung_normal, 3).           %% Normal lung tissue
alpha_beta_ratio(rectum, 3).                %% Rectum (late)
alpha_beta_ratio(bladder, 6).               %% Bladder

%% default_alpha_beta(+Context, -Ratio)
%% Context is either 'tumor' or 'normal_tissue'
default_alpha_beta(tumor, 10).
default_alpha_beta(normal_tissue, 3).

%% ============================================================
%% Dose Unit Conversions
%% ============================================================

%% gy_to_cgy(+Gy, -cGy)
gy_to_cgy(Gy, CGy) :-
    number(Gy),
    CGy is Gy * 100.

%% cgy_to_gy(+cGy, -Gy)
cgy_to_gy(CGy, Gy) :-
    number(CGy),
    Gy is CGy / 100.

%% ============================================================
%% Fractionation Classification
%% ============================================================

%% is_hypofractionated(+DosePerFraction, +AlphaBeta)
%% True if dose per fraction > 2.5 Gy (for α/β = 10)
%% Adjusts threshold based on α/β
is_hypofractionated(DosePerFractionGy, AlphaBeta) :-
    Threshold is 2.5 * (10 / AlphaBeta),
    DosePerFractionGy > Threshold.

%% is_hyperfractionated(+DosePerFraction, +AlphaBeta)
%% True if dose per fraction < 1.8 Gy
is_hyperfractionated(DosePerFractionGy, _AlphaBeta) :-
    DosePerFractionGy < 1.8.

%% is_conventional_fractionation(+DosePerFraction, +AlphaBeta)
%% True if dose per fraction is between 1.8 and 2.5 Gy
is_conventional_fractionation(DosePerFractionGy, AlphaBeta) :-
    DosePerFractionGy >= 1.8,
    Threshold is 2.5 * (10 / AlphaBeta),
    DosePerFractionGy =< Threshold.

%% ============================================================
%% Time Factor Corrections (Incomplete Repair Model)
%% ============================================================
%%
%% For treatments with multiple fractions per day, incomplete
%% repair between fractions must be considered.
%%
%% BED_corrected = n * d * (1 + d * H_m / (α/β))
%%
%% where H_m accounts for incomplete repair

%% bed_with_time_factor(+TotalDose, +DosePerFraction, +AlphaBeta,
%%                      +FractionsPerDay, +HoursBetween, -BED)
%%
%% Simplified model assuming exponential repair
bed_with_time_factor(TotalDose, DosePerFraction, AlphaBeta,
                     FractionsPerDay, HoursBetween, BED) :-
    number(TotalDose),
    number(DosePerFraction),
    number(AlphaBeta), AlphaBeta > 0,
    integer(FractionsPerDay), FractionsPerDay > 0,
    number(HoursBetween),

    %% Repair half-time typically 1.5 hours
    RepairHalfTime = 1.5,

    %% Calculate incomplete repair factor
    (   FractionsPerDay > 1
    ->  Mu is log(2) / RepairHalfTime,
        Theta is exp(-Mu * HoursBetween),
        %% Hm factor for m fractions per day
        M = FractionsPerDay,
        Hm is 1 + (2 * Theta / (M * (1 - Theta))) *
             (M - (1 - Theta^M) / (1 - Theta))
    ;   Hm = 1
    ),

    %% Calculate BED with time factor
    BED is TotalDose * (1 + DosePerFraction * Hm / AlphaBeta).
