% simulator_eval.pl — Expression evaluation for the Pascal simulator.

:- module(simulator_eval, [
    eval_expr/3                % eval_expr(+Expr, +State, -Value)
]).

:- use_module(simulator_state, [
    get_var/3,
    lookup_object/3
]).

eval_expr(int(N), _, N).
eval_expr(float(F), _, F).
eval_expr(str(S), _, S).
eval_expr(bool(B), _, B).
eval_expr(nil, _, nil).
eval_expr(ident(Name), S, V) :-
    get_var(Name, S, V0),
    ( V0 == unbound -> V = ident(Name)   % unresolved → keep as symbol
    ; V = V0
    ).
eval_expr(dot(Recv, Field), S, V) :-
    eval_expr(Recv, S, RecvV),
    resolve_member(RecvV, Field, S, V).
eval_expr(call(Callee, Args), S, call_result(Callee, ArgVs)) :-
    eval_expr(Callee, S, _),
    maplist(eval_arg(S), Args, ArgVs).
eval_expr(binop(Op, A, B), S, V) :-
    eval_expr(A, S, AV),
    eval_expr(B, S, BV),
    apply_binop(Op, AV, BV, V).
eval_expr(unop(Op, A), S, V) :-
    eval_expr(A, S, AV),
    apply_unop(Op, AV, V).
eval_expr(index(Arr, Idxs), S, index_value(ArrV, IdxVs)) :-
    eval_expr(Arr, S, ArrV),
    maplist(eval_arg(S), Idxs, IdxVs).

eval_arg(S, E, V) :- eval_expr(E, S, V).

% Member access: if the receiver is an object, look up its fields; otherwise
% keep the access as a symbolic dot for downstream pattern matching.
resolve_member(ident(Name), Field, S, V) :-
    lookup_object(Name, S, object(_, Fields)),
    ( member(Field=V0, Fields) -> V = V0
    ; V = dot(ident(Name), Field)
    ),
    !.
resolve_member(R, F, _, dot(R, F)).

% Arithmetic / relational / boolean operators. Falls through to a symbolic
% term when the operands are non-numeric — useful for partial evaluation
% during static analysis.
apply_binop('+', A, B, R) :- number(A), number(B), !, R is A + B.
apply_binop('-', A, B, R) :- number(A), number(B), !, R is A - B.
apply_binop('*', A, B, R) :- number(A), number(B), !, R is A * B.
apply_binop('/', A, B, R) :- number(A), number(B), B =\= 0, !, R is A / B.
apply_binop(div, A, B, R) :- integer(A), integer(B), B =\= 0, !, R is A // B.
apply_binop(mod, A, B, R) :- integer(A), integer(B), B =\= 0, !, R is A mod B.
apply_binop('=',  A, B, R) :- !, ( A == B -> R = true ; R = false ).
apply_binop('<>', A, B, R) :- !, ( A \== B -> R = true ; R = false ).
apply_binop('<',  A, B, R) :- number(A), number(B), !, ( A <  B -> R = true ; R = false ).
apply_binop('>',  A, B, R) :- number(A), number(B), !, ( A >  B -> R = true ; R = false ).
apply_binop('<=', A, B, R) :- number(A), number(B), !, ( A =< B -> R = true ; R = false ).
apply_binop('>=', A, B, R) :- number(A), number(B), !, ( A >= B -> R = true ; R = false ).
apply_binop(and, A, B, R) :- !, ( (A == true ; A == bool(true)), (B == true ; B == bool(true)) -> R = true ; R = false ).
apply_binop(or,  A, B, R) :- !, ( (A == true ; A == bool(true)) ; (B == true ; B == bool(true)) -> R = true ; R = false ).
apply_binop(xor, A, B, R) :- !, ( A \== B -> R = true ; R = false ).
apply_binop(Op, A, B, binop(Op, A, B)).

apply_unop('-', A, R)   :- number(A), !, R is -A.
apply_unop('+', A, A)   :- number(A), !.
apply_unop(not, true,  false) :- !.
apply_unop(not, false, true)  :- !.
apply_unop(Op, A, unop(Op, A)).
