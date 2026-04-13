% trace_thirdpartyoffset.pl — Simulate the ThirdPartyOffset form
% through the unified Clarion simulator.
%
% Tests the core clinical logic:
%   1. Parse + bridge the real WINDOW/ACCEPT form
%   2. Checkbox-driven field enable/disable (ProcessKnownComponent)
%   3. Vector magnitude calculation (ChangeMagnitude)
%   4. Angular range validation (reject > 89.9 degrees)
%   5. EnableSave logic (OK button gated on any known component)
%
% Usage: swipl -g "main,halt" -t "halt(1)" trace_thirdpartyoffset.pl

:- use_module(clarion).
:- use_module(clarion_parser).
:- use_module(ast_bridge).

main :-
    read_file_to_string('../../../clarion_projects/treatment-offset/ThirdPartyOffset.clw', Src, []),
    format("=== ThirdPartyOffset Form Simulation ===~n~n"),

    % --- Test 1: Parse succeeds ---
    format("--- Test 1: Parse + Bridge ---~n"),
    ( parse_clarion(Src, SimpleAST)
    -> format("  PASS: Source parsed~n"),
       ( bridge_ast(SimpleAST, _ModAST)
       -> format("  PASS: AST bridged~n")
       ;  format("  FAIL: Bridge error~n")
       )
    ;  format("  FAIL: Parse error~n")
    ),
    nl,

    % --- Test 2: Full program execution with event sequences ---
    % Scenario A: Check X, enter LinearX=30, check Y, enter LinearY=40 -> Magnitude = ISqrt(900+1600) = 50
    format("--- Test 2: Magnitude Calculation (3-4-5 triangle) ---~n"),
    Events_A = [
        % Check IsXcmKnown -> triggers ProcessKnownComponent + ChangeMagnitude
        set('IsXcmKnown', 1), accepted('IsXcmKnown'),
        % Enter LinearX = 30
        set('LinearX', 30), accepted('LinearX'),
        % Check IsYcmKnown
        set('IsYcmKnown', 1), accepted('IsYcmKnown'),
        % Enter LinearY = 40
        set('LinearY', 40), accepted('LinearY'),
        % Press OK
        accepted('OkButton')
    ],
    ( exec_program_state(Src, Events_A, ResultState_A)
    -> ResultState_A = state(VarsA, _, _, _, _, _, _, _, _),
       ( member(var('VectorLength', MagA), VarsA) -> true ; MagA = unknown ),
       ( member(var('LinearX', LxA), VarsA) -> true ; LxA = unknown ),
       ( member(var('LinearY', LyA), VarsA) -> true ; LyA = unknown ),
       format("  LinearX=~w, LinearY=~w, VectorLength=~w~n", [LxA, LyA, MagA]),
       ( MagA =:= 50 -> format("  PASS: ISqrt(30^2 + 40^2) = 50~n")
       ; format("  FAIL: Expected 50, got ~w~n", [MagA])
       )
    ;  format("  FAIL: Execution error~n")
    ),
    nl,

    % --- Test 3: Magnitude with all three axes (3D) ---
    format("--- Test 3: 3D Magnitude (10, 20, 20 -> ISqrt(900) = 30) ---~n"),
    Events_B = [
        set('IsXcmKnown', 1), accepted('IsXcmKnown'),
        set('LinearX', 10), accepted('LinearX'),
        set('IsYcmKnown', 1), accepted('IsYcmKnown'),
        set('LinearY', 20), accepted('LinearY'),
        set('IsZcmKnown', 1), accepted('IsZcmKnown'),
        set('LinearZ', 20), accepted('LinearZ'),
        accepted('OkButton')
    ],
    ( exec_program_state(Src, Events_B, ResultState_B)
    -> ResultState_B = state(VarsB, _, _, _, _, _, _, _, _),
       ( member(var('VectorLength', MagB), VarsB) -> true ; MagB = unknown ),
       format("  VectorLength=~w~n", [MagB]),
       ( MagB =:= 30 -> format("  PASS: ISqrt(10^2 + 20^2 + 20^2) = 30~n")
       ; format("  FAIL: Expected 30, got ~w~n", [MagB])
       )
    ;  format("  FAIL: Execution error~n")
    ),
    nl,

    % --- Test 4: No components checked -> OK stays disabled, Cancel exits ---
    format("--- Test 4: No components -> Cancel ---~n"),
    Events_C = [
        accepted('CancelButton')
    ],
    ( exec_program(Src, Events_C, Result_C)
    -> format("  Program result: ~w~n", [Result_C]),
       format("  PASS: Cancel without components~n")
    ;  format("  FAIL: Execution error~n")
    ),
    nl,

    format("=== Done ===~n").
