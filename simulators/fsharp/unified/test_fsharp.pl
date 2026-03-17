:- module(test_fsharp, [main/0]).

:- use_module(fsharp).
:- use_module(fsharp_parser).
:- use_module(fsharp_state).

main :-
    run_tests.

run_tests :-
    format("Running F# Simulator Tests...~n"),
    test_parsing,
    test_execution,
    test_functions,
    format("All F# tests passed!~n").

test_parsing :-
    format("  Test: Parsing simple let bindings... "),
    Source = "let x = 5\nlet y = x + 10",
    string_codes(Source, Codes),
    (   phrase(fsharp_parser:program(AST), Codes, Rest)
    ->  (   Rest = []
        ->  (   AST = program([let(x, [], lit(5)), let(y, [], add(var(x), lit(10)))])
            ->  format("Passed~n")
            ;   format("Failed: AST mismatch: ~w~n", [AST]), fail
            )
        ;   length(Rest, Len),
            length(Codes, FullLen),
            Pos is FullLen - Len,
            format("Failed: Partial parse at pos ~w, rest: ~s~n", [Pos, Rest]), fail
        )
    ;   format("Failed: Could not parse at all~n"), fail
    ).

test_execution :-
    format("  Test: Executing simple expressions... "),
    Source = "let x = 5\nlet y = x + 10",
    (   run_fsharp(Source, State)
    ->  (   get_var(x, State, 5), get_var(y, State, 15)
        ->  format("Passed~n")
        ;   format("Failed: Value mismatch in state~n"), fail
        )
    ;   format("Failed: Execution error~n"), fail
    ).

test_functions :-
    format("  Test: Function calls... "),
    Source = "let add x y = x + y\nlet result = add 5 10",
    (   run_fsharp(Source, State)
    ->  (   get_var(result, State, 15)
        ->  format("Passed~n")
        ;   format("Failed: Value mismatch in state: ~w~n", [State]), fail
        )
    ;   format("Failed: Execution error~n"), fail
    ).

get_var(Name, State, Value) :-
    fsharp_state:get_var(Name, State, Value).
