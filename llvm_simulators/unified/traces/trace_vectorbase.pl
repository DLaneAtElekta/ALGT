%% trace_vectorbase.pl -- Trace comparison script for VectorBase struct functions
%%
%% Outputs CALL lines for comparison against compiled C++ execution.
%%
%% Usage:
%%   cd llvm_simulators/unified
%%   swipl -g "main,halt" traces/trace_vectorbase.pl
%%
%% Compare with C++ side:
%%   diff <(swipl -g "main,halt" traces/trace_vectorbase.pl) \
%%        <(./vectorbase_test)

:- use_module('../llvm').
:- use_module('../llvm_state').

%% alloc_vec3(+Session, -Addr, -Session2)
%  Allocate 32 bytes for a Vec3 struct.
alloc_vec3(S0, Addr, S1) :-
    llvm_state:alloc_bytes(32, Addr, S0, S1).

%% init_vec3(+Session, +Addr, +X, +Y, +Z, -Session2)
%  Initialize a Vec3 struct with given values.
init_vec3(S0, Addr, X, Y, Z, S1) :-
    call_function(S0, 'Vec3_init', [Addr, X, Y, Z], _, S1).

main :-
    init_session_from_file('samples/vectorbase.ll', S),

    % GetLength({3,4,0}) = 5
    alloc_vec3(S, V1, S1),
    init_vec3(S1, V1, 3.0, 4.0, 0.0, S2),
    call_function(S2, 'Vec3_getLength', [V1], Len1, _),
    format("CALL Vec3_getLength({3,4,0}) -> ~g~n", [Len1]),

    % GetLength({1,2,3}) = sqrt(14)
    init_vec3(S2, V1, 1.0, 2.0, 3.0, S3),
    call_function(S3, 'Vec3_getLength', [V1], Len2, _),
    format("CALL Vec3_getLength({1,2,3}) -> ~g~n", [Len2]),

    % Dot({1,0,0}, {0,1,0}) = 0
    alloc_vec3(S3, V2, S4),
    init_vec3(S4, V1, 1.0, 0.0, 0.0, S5),
    init_vec3(S5, V2, 0.0, 1.0, 0.0, S6),
    call_function(S6, 'Vec3_dot', [V1, V2], Dot1, _),
    format("CALL Vec3_dot({1,0,0}, {0,1,0}) -> ~g~n", [Dot1]),

    % Dot({1,2,3}, {4,5,6}) = 32
    init_vec3(S6, V1, 1.0, 2.0, 3.0, S7),
    init_vec3(S7, V2, 4.0, 5.0, 6.0, S8),
    call_function(S8, 'Vec3_dot', [V1, V2], Dot2, _),
    format("CALL Vec3_dot({1,2,3}, {4,5,6}) -> ~g~n", [Dot2]),

    % Normalize({3,4,0}) -> {0.6, 0.8, 0}
    init_vec3(S8, V1, 3.0, 4.0, 0.0, S9),
    call_function(S9, 'Vec3_normalize', [V1], _, S10),
    call_function(S10, 'Vec3_getElement', [V1, 0], NX, _),
    call_function(S10, 'Vec3_getElement', [V1, 1], NY, _),
    call_function(S10, 'Vec3_getElement', [V1, 2], NZ, _),
    format("CALL Vec3_normalize({3,4,0}) -> {~g, ~g, ~g}~n", [NX, NY, NZ]),

    % Add({1,2,3}, {10,20,30}) -> {11, 22, 33}
    alloc_vec3(S10, VR, S11),
    init_vec3(S11, V1, 1.0, 2.0, 3.0, S12),
    init_vec3(S12, V2, 10.0, 20.0, 30.0, S13),
    call_function(S13, 'Vec3_add', [V1, V2, VR], _, S14),
    call_function(S14, 'Vec3_getElement', [VR, 0], AX, _),
    call_function(S14, 'Vec3_getElement', [VR, 1], AY, _),
    call_function(S14, 'Vec3_getElement', [VR, 2], AZ, _),
    format("CALL Vec3_add({1,2,3}, {10,20,30}) -> {~g, ~g, ~g}~n", [AX, AY, AZ]),

    % Scale({1,2,3}, 2.5) -> {2.5, 5, 7.5}
    init_vec3(S14, V1, 1.0, 2.0, 3.0, S15),
    call_function(S15, 'Vec3_scale', [V1, 2.5], _, S16),
    call_function(S16, 'Vec3_getElement', [V1, 0], SX, _),
    call_function(S16, 'Vec3_getElement', [V1, 1], SY, _),
    call_function(S16, 'Vec3_getElement', [V1, 2], SZ, _),
    format("CALL Vec3_scale({1,2,3}, 2.5) -> {~g, ~g, ~g}~n", [SX, SY, SZ]),

    % Cross({1,0,0}, {0,1,0}) -> {0, 0, 1}
    init_vec3(S16, V1, 1.0, 0.0, 0.0, S17),
    init_vec3(S17, V2, 0.0, 1.0, 0.0, S18),
    call_function(S18, 'Vec3_cross', [V1, V2, VR], _, S19),
    call_function(S19, 'Vec3_getElement', [VR, 0], CX, _),
    call_function(S19, 'Vec3_getElement', [VR, 1], CY, _),
    call_function(S19, 'Vec3_getElement', [VR, 2], CZ, _),
    format("CALL Vec3_cross({1,0,0}, {0,1,0}) -> {~g, ~g, ~g}~n", [CX, CY, CZ]).
