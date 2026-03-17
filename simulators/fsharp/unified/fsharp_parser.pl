:- module(fsharp_parser, [
    parse_fsharp/2
]).

:- set_prolog_flag(double_quotes, codes).

%% ==========================================================================
%% Entry point
%% ==========================================================================

parse_fsharp(Source, AST) :-
    (   atom(Source) -> atom_codes(Source, Codes)
    ;   string(Source) -> string_codes(Source, Codes)
    ;   is_list(Source) -> Codes = Source
    ;   Codes = Source
    ),
    phrase(program(AST), Codes).

%% ==========================================================================
%% Grammar
%% ==========================================================================

program(program(Bindings)) -->
    ws,
    star(binding, Bindings),
    ws.

binding(let(Name, Args, Expr)) -->
    kw("let"), ws,
    ident(Name), ws,
    star(ident, Args), ws,
    "=", ws,
    expr(Expr), ws.

% Expressions (Precedence: lowest to highest)
expr(E) --> arith_expr(E).

arith_expr(E) --> term(T), arith_expr_rest(T, E).

arith_expr_rest(Acc, E) -->
    "+", ws, term(T), !, { NewAcc = add(Acc, T) }, arith_expr_rest(NewAcc, E).
arith_expr_rest(Acc, E) -->
    "-", ws, term(T), !, { NewAcc = sub(Acc, T) }, arith_expr_rest(NewAcc, E).
arith_expr_rest(Acc, Acc) --> [].

term(E) --> factor(F), term_rest(F, E).

term_rest(Acc, E) -->
    "*", ws, factor(F), !, { NewAcc = mul(Acc, F) }, term_rest(NewAcc, E).
term_rest(Acc, E) -->
    "/", ws, factor(F), !, { NewAcc = div(Acc, F) }, term_rest(NewAcc, E).
term_rest(Acc, Acc) --> [].

factor(E) --> app_expr(E).

% Function application: f x y
% Must not cross newlines unless indented (simplified for now: no crossing)
app_expr(E) --> primary(P), ws_no_nl, app_expr_rest(P, E).

app_expr_rest(Acc, E) -->
    \+ forbidden_start,
    primary(P), ws_no_nl, !, { NewAcc = app(Acc, P) }, app_expr_rest(NewAcc, E).
app_expr_rest(Acc, Acc) --> [].

forbidden_start --> "=", !.
forbidden_start --> "+", !.
forbidden_start --> "-", !.
forbidden_start --> "*", !.
forbidden_start --> "/", !.

primary(lit(N)) --> number(N).
primary(var(V)) --> ident(V).
primary(P) --> "(", ws, expr(P), ws, ")".

%% ==========================================================================
%% Helpers
%% ==========================================================================

ws --> [C], { C =< 32 }, !, ws.
ws --> [].

ws_no_nl --> [C], { C =< 32, C \== 10, C \== 13 }, !, ws_no_nl.
ws_no_nl --> [].

kw(S) --> S, \+ ( [C], { char_type(C, alnum) ; C == 0'_ } ).

is_keyword(let).

ident(Name) -->
    [C], { char_type(C, alpha) ; C == 0'_ },
    ident_rest(Rest),
    { atom_codes(Name, [C|Rest]), \+ is_keyword(Name) }.

ident_rest([C|Rest]) --> [C], { char_type(C, alnum) ; C == 0'_ }, !, ident_rest(Rest).
ident_rest([]) --> [].

number(N) -->
    digits(Ds),
    { Ds \= [], number_codes(N, Ds) }.

digits([D|Ds]) --> [D], { char_type(D, digit) }, !, digits(Ds).
digits([]) --> [].

:- meta_predicate star(3, -, ?, ?).
star(Goal, [X|Xs]) --> call(Goal, X), ws, !, star(Goal, Xs).
star(_, []) --> [].
