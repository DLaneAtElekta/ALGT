:- module(fsharp_eval, [
    eval_expr/4
]).

:- use_module(fsharp_state).

eval_expr(lit(N), State, State, N).
eval_expr(var(V), State, State, Val) :-
    get_var(V, State, Val).
eval_expr(add(A, B), StateIn, StateOut, Val) :-
    eval_expr(A, StateIn, State1, V1),
    eval_expr(B, State1, StateOut, V2),
    Val is V1 + V2.
eval_expr(sub(A, B), StateIn, StateOut, Val) :-
    eval_expr(A, StateIn, State1, V1),
    eval_expr(B, State1, StateOut, V2),
    Val is V1 - V2.
eval_expr(mul(A, B), StateIn, StateOut, Val) :-
    eval_expr(A, StateIn, State1, V1),
    eval_expr(B, State1, StateOut, V2),
    Val is V1 * V2.
eval_expr(div(A, B), StateIn, StateOut, Val) :-
    eval_expr(A, StateIn, State1, V1),
    eval_expr(B, State1, StateOut, V2),
    Val is V1 / V2.

% Basic function application (collecting arguments)
eval_expr(app(F, X), StateIn, StateOut, Result) :-
    eval_expr(F, StateIn, State1, FVal),
    eval_expr(X, State1, State2, XVal),
    apply(FVal, XVal, State2, StateOut, Result).

apply(func(Args, Expr), XVal, StateIn, StateOut, Result) :-
    Args = [Arg|Rest],
    (   Rest = []
    ->  % Full application
        push_frame(StateIn, S1),
        bind_args([Arg], [XVal], S1, S2),
        eval_expr(Expr, S2, S3, Result),
        pop_frame(S3, StateOut)
    ;   % Partial application
        Result = partial(Rest, [Arg], Expr, [XVal]),
        StateOut = StateIn
    ).

apply(partial(Rest, ArgNames, Expr, ArgVals), XVal, StateIn, StateOut, Result) :-
    Rest = [Arg|Rest2],
    append(ArgNames, [Arg], NewArgNames),
    append(ArgVals, [XVal], NewArgVals),
    (   Rest2 = []
    ->  % Full application
        push_frame(StateIn, S1),
        bind_args(NewArgNames, NewArgVals, S1, S2),
        eval_expr(Expr, S2, S3, Result),
        pop_frame(S3, StateOut)
    ;   % Still partial
        Result = partial(Rest2, NewArgNames, Expr, NewArgVals),
        StateOut = StateIn
    ).
