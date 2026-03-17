:- module(fsharp, [
    run_fsharp/1,
    run_fsharp/2,
    exec_procedure/4
]).

:- use_module(fsharp_parser).
:- use_module(fsharp_simulator).
:- use_module(fsharp_state).

run_fsharp(Source) :-
    parse_fsharp(Source, AST),
    run_program(AST, _).

run_fsharp(Source, FinalState) :-
    parse_fsharp(Source, AST),
    run_program(AST, FinalState).

exec_procedure(Source, FuncName, Args, Result) :-
    parse_fsharp(Source, AST),
    run_program(AST, State0),
    exec_call(FuncName, Args, State0, _, Result).
