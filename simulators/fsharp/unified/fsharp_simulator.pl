:- module(fsharp_simulator, [
    run_program/2,
    run_program/3,
    exec_call/5
]).

:- use_module(fsharp_state).
:- use_module(fsharp_eval).
:- use_module(fsharp_builtins).

run_program(program(Bindings), FinalState) :-
    empty_state(State),
    exec_bindings(Bindings, State, FinalState).

run_program(program(Bindings), StateIn, FinalState) :-
    exec_bindings(Bindings, StateIn, FinalState).

exec_bindings([], State, State).
exec_bindings([let(Name, [], Expr)|Rest], StateIn, StateOut) :-
    eval_expr(Expr, StateIn, State1, Val),
    set_var(Name, Val, State1, State2),
    exec_bindings(Rest, State2, StateOut).
exec_bindings([let(Name, Args, Expr)|Rest], StateIn, StateOut) :-
    Args \= [],
    % Store function as a term func(Args, Expr)
    set_var(Name, func(Args, Expr), StateIn, State1),
    exec_bindings(Rest, State1, StateOut).

exec_call(FuncName, ArgValues, StateIn, StateOut, Result) :-
    (   is_builtin(FuncName)
    ->  call_builtin(FuncName, ArgValues, StateIn, StateOut),
        Result = 0
    ;   get_var(FuncName, StateIn, func(Args, Expr)),
        push_frame(StateIn, State1),
        bind_args(Args, ArgValues, State1, State2),
        eval_expr(Expr, State2, State3, Result),
        pop_frame(State3, StateOut)
    ).
