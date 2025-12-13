%% prescription_model.pl
%%
%% Domain model for radiation therapy prescriptions
%% Defines structures for physician intent, treatment plans, and phases
%%
%% Copyright (C) 2024 ALGT Project

:- module(prescription_model, [
    %% Prescription constructors and accessors
    prescription/7,
    prescription_id/2,
    prescription_target/2,
    prescription_total_dose/2,
    prescription_fractions/2,
    prescription_dose_per_fraction/2,
    prescription_modality/2,
    prescription_phases/2,

    %% Phase constructors and accessors
    phase/5,
    phase_name/2,
    phase_dose/2,
    phase_fractions/2,
    phase_dose_per_fraction/2,
    phase_technique/2,

    %% Intent and Plan wrappers
    physician_intent/2,
    treatment_plan/2,

    %% Target volume types
    target_volume/3,
    is_valid_target_type/1,

    %% Modality types
    is_valid_modality/1
]).

%% ============================================================
%% Prescription Structure
%% ============================================================
%%
%% prescription(Id, Target, TotalDose, Fractions, DosePerFraction, Modality, Phases)
%%
%% - Id: Unique identifier
%% - Target: Target volume (target_volume/3)
%% - TotalDose: Total prescribed dose in cGy
%% - Fractions: Total number of fractions
%% - DosePerFraction: Dose per fraction in cGy
%% - Modality: Treatment modality (photon, electron, proton, etc.)
%% - Phases: List of phase/5 structures for multi-phase treatments

prescription(Id, Target, TotalDose, Fractions, DosePerFraction, Modality, Phases) :-
    atom(Id),
    is_valid_target(Target),
    number(TotalDose), TotalDose > 0,
    integer(Fractions), Fractions > 0,
    number(DosePerFraction), DosePerFraction > 0,
    is_valid_modality(Modality),
    is_list(Phases).

%% Accessors
prescription_id(prescription(Id, _, _, _, _, _, _), Id).
prescription_target(prescription(_, Target, _, _, _, _, _), Target).
prescription_total_dose(prescription(_, _, TotalDose, _, _, _, _), TotalDose).
prescription_fractions(prescription(_, _, _, Fractions, _, _, _), Fractions).
prescription_dose_per_fraction(prescription(_, _, _, _, DPF, _, _), DPF).
prescription_modality(prescription(_, _, _, _, _, Modality, _), Modality).
prescription_phases(prescription(_, _, _, _, _, _, Phases), Phases).

%% ============================================================
%% Phase Structure (for multi-phase treatments)
%% ============================================================
%%
%% phase(Name, Dose, Fractions, DosePerFraction, Technique)
%%
%% Represents a single phase in a multi-phase treatment

phase(Name, Dose, Fractions, DosePerFraction, Technique) :-
    atom(Name),
    number(Dose), Dose > 0,
    integer(Fractions), Fractions > 0,
    number(DosePerFraction), DosePerFraction > 0,
    atom(Technique).

%% Accessors
phase_name(phase(Name, _, _, _, _), Name).
phase_dose(phase(_, Dose, _, _, _), Dose).
phase_fractions(phase(_, _, Fractions, _, _), Fractions).
phase_dose_per_fraction(phase(_, _, _, DPF, _), DPF).
phase_technique(phase(_, _, _, _, Technique), Technique).

%% ============================================================
%% Intent and Plan Wrappers
%% ============================================================

%% physician_intent(IntentId, Prescription)
%% Wraps a prescription as a physician's intent
physician_intent(IntentId, Prescription) :-
    atom(IntentId),
    prescription_id(Prescription, _).

%% treatment_plan(PlanId, Prescription)
%% Wraps a prescription as a treatment plan
treatment_plan(PlanId, Prescription) :-
    atom(PlanId),
    prescription_id(Prescription, _).

%% ============================================================
%% Target Volume Types
%% ============================================================
%%
%% target_volume(Name, Type, Location)
%% - Name: Volume identifier
%% - Type: GTV, CTV, PTV, etc.
%% - Location: Anatomical location

target_volume(Name, Type, Location) :-
    atom(Name),
    is_valid_target_type(Type),
    atom(Location).

is_valid_target(target_volume(_, _, _)).

is_valid_target_type(gtv).      %% Gross Tumor Volume
is_valid_target_type(ctv).      %% Clinical Target Volume
is_valid_target_type(ptv).      %% Planning Target Volume
is_valid_target_type(itv).      %% Internal Target Volume
is_valid_target_type(gtv_n).    %% Nodal GTV
is_valid_target_type(ctv_n).    %% Nodal CTV
is_valid_target_type(ptv_n).    %% Nodal PTV
is_valid_target_type(oar).      %% Organ at Risk (for constraints)

%% ============================================================
%% Treatment Modalities
%% ============================================================

is_valid_modality(photon).
is_valid_modality(electron).
is_valid_modality(proton).
is_valid_modality(carbon_ion).
is_valid_modality(brachytherapy).
is_valid_modality(sbrt).        %% Stereotactic Body RT
is_valid_modality(srs).         %% Stereotactic Radiosurgery
is_valid_modality(imrt).        %% Intensity Modulated RT
is_valid_modality(vmat).        %% Volumetric Arc Therapy
is_valid_modality(tomo).        %% Tomotherapy
is_valid_modality('3dcrt').     %% 3D Conformal RT
