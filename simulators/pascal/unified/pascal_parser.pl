% pascal_parser.pl — DCG grammar for the Object Pascal / Lazarus subset → AST
%
% Scope: a small slice of FPC's {$mode objfpc} sufficient for MUZAQ form modules.
%   - unit / interface / implementation / uses
%   - class declarations with fields, methods, properties (visibility sections)
%   - procedure / function bodies with begin/end blocks
%   - if/then/else, while/do, for/to/do, repeat/until, case/of, with/do
%   - assignment (:=), member access (.), method calls
%   - integer, float, string, identifier literals
%   - comments: //, { ... }, (* ... *)
%
% Out of scope (intentional, can be extended): generics, anonymous methods,
% inline assembler, advanced RTTI, operator overloading, variant records.

:- module(pascal_parser, [
    parse_pascal/2,        % parse_pascal(+Source, -AST)
    unit//1,
    is_keyword/1
]).

:- set_prolog_flag(double_quotes, codes).
:- discontiguous statement//1.

%% ==========================================================================
%% AST shape (produced by this parser)
%% ==========================================================================
%
%   unit(Name, Interface, Implementation, Init)
%     Interface       = interface(Uses, Decls)
%     Implementation  = implementation(Uses, Decls)
%     Init            = init(Stmts) | none
%
%   Decls (in either section):
%     class_decl(Name, Parent, Members)
%       Members = [field(Vis,Name,Type), method_decl(Vis,Kind,Name,Params,Ret),
%                  property_decl(Vis,Name,Type,Read,Write), ...]
%     method_def(ClassName, Kind, Name, Params, Ret, Locals, Body)
%       Kind = procedure | function | constructor | destructor
%     proc_def(Kind, Name, Params, Ret, Locals, Body)
%     var_decl(Name, Type, Init)
%     const_decl(Name, Type, Value)
%     type_decl(Name, TypeExpr)
%
%   Statements:
%     assign(Lhs, Rhs)
%     call(Callee, Args)
%     if(Cond, Then, Else)
%     while(Cond, Body)
%     for(Var, Start, End, Dir, Body)         % Dir = up | down
%     repeat(Body, Cond)
%     case(Expr, Arms, Else)                  % Arms = [arm(Labels, Stmt), ...]
%     with(Targets, Body)
%     try_except(Body, Handlers, Finally)
%     compound(Stmts)
%     break | continue | exit | exit_with(Expr)
%
%   Expressions:
%     int(N), float(F), str(S), bool(true|false), nil
%     ident(Name)
%     dot(Recv, Field)                        % member / qualified access
%     call(Callee, Args)
%     binop(Op, A, B)                         % +, -, *, /, div, mod, =, <>, <, >, <=, >=, and, or, xor, shl, shr
%     unop(Op, A)                             % -, not, +
%     index(Arr, Indices)
%
%   Types:
%     type_ref(Name)                          % e.g. Integer, String, TForm

%% ==========================================================================
%% Entry point
%% ==========================================================================

parse_pascal(Source, AST) :-
    ( atom(Source)  -> atom_codes(Source, Codes0)
    ; string(Source)-> string_codes(Source, Codes0)
    ; Codes0 = Source
    ),
    strip_comments(Codes0, Codes),
    phrase(unit(AST), Codes, Rest),
    ( Rest = [] -> true
    ; format(user_error, "parse_pascal: trailing text not consumed: ~s~n", [Rest]),
      fail
    ).

%% ==========================================================================
%% Comment stripping (single pass, keeps strings intact)
%% ==========================================================================

strip_comments([], []).
strip_comments([0'/, 0'/ | T], Out) :- !,
    skip_to_eol(T, Rest),
    strip_comments(Rest, Out).
strip_comments([0'{ | T], Out) :- !,
    skip_to_close_brace(T, Rest),
    strip_comments(Rest, Out).
strip_comments([0'(, 0'* | T], Out) :- !,
    skip_to_close_paren_star(T, Rest),
    strip_comments(Rest, Out).
strip_comments([0'' | T], Out) :- !,
    copy_pascal_string(T, Body, Rest),
    strip_comments(Rest, Out2),
    append([0'' | Body], Out2, Out).
strip_comments([C | T], [C | Out]) :- strip_comments(T, Out).

skip_to_eol([], []).
skip_to_eol([0'\n | T], [0'\n | T]) :- !.
skip_to_eol([_ | T], R) :- skip_to_eol(T, R).

skip_to_close_brace([], []).
skip_to_close_brace([0'} | T], T) :- !.
skip_to_close_brace([_ | T], R) :- skip_to_close_brace(T, R).

skip_to_close_paren_star([], []).
skip_to_close_paren_star([0'*, 0') | T], T) :- !.
skip_to_close_paren_star([_ | T], R) :- skip_to_close_paren_star(T, R).

% Copy the body of a Pascal '...' string literal up to and including its
% closing quote, honoring '' as an embedded quote. The leading quote has
% already been consumed by the caller; the closing quote is included in
% the output so that the parser still sees a balanced literal.
copy_pascal_string([], [], []).
copy_pascal_string([0'', 0'' | T], [0'', 0'' | O], R) :- !, copy_pascal_string(T, O, R).
copy_pascal_string([0'' | T], [0''], T) :- !.
copy_pascal_string([C | T], [C | O], R) :- copy_pascal_string(T, O, R).

%% ==========================================================================
%% Top-level grammar: a unit
%% ==========================================================================

unit(unit(Name, Iface, Impl, Init)) -->
    ws, kw("unit"), ws, ident(Name), ws, ";", ws,
    interface_section(Iface), ws,
    implementation_section(Impl), ws,
    initialization_section(Init), ws,
    kw("end"), ws, ".", ws.

interface_section(interface(Uses, Decls)) -->
    kw("interface"), ws,
    optional_uses(Uses), ws,
    decls(Decls).

implementation_section(implementation(Uses, Decls)) -->
    kw("implementation"), ws,
    optional_uses(Uses), ws,
    decls(Decls).

initialization_section(init(Stmts)) -->
    kw("initialization"), ws, statements(Stmts), ws, !.
initialization_section(none) --> [].

optional_uses(Names) -->
    kw("uses"), ws, ident_list(Names), ws, ";", ws, !.
optional_uses([]) --> [].

ident_list([N | Ns]) --> ident(N), ws, ident_list_rest(Ns).
ident_list_rest([N | Ns]) --> ",", ws, ident(N), ws, ident_list_rest(Ns).
ident_list_rest([]) --> [].

%% ==========================================================================
%% Declarations
%% ==========================================================================

decls([D | Ds]) --> decl(D), ws, decls(Ds).
decls([])       --> [].

decl(D) --> type_block(D), !.
decl(D) --> var_block(D), !.
decl(D) --> const_block(D), !.
decl(D) --> method_def(D), !.
decl(D) --> proc_def(D), !.

% type Foo = class(...) ... end;
type_block(type_decl(Name, Type)) -->
    kw("type"), ws, ident(Name), ws, "=", ws, type_expr(Type), ws, ";", ws.

type_expr(class_type(Parent, Members)) -->
    kw("class"), ws, optional_parent(Parent), ws,
    class_members([], Members),
    kw("end").
type_expr(type_ref(Name)) --> ident(Name).

optional_parent(Parent) -->
    "(", ws, ident(Parent), ws, ")", ws, !.
optional_parent(none) --> [].

class_members(Acc, Members) -->
    class_section(Vis, MS), ws, !,
    { append(Acc, MS, Acc1) },
    class_members(Acc1, Rest),
    { tag_visibility(MS, Vis, Tagged),
      replace_tail(Acc, Tagged, Members0, Rest),
      Members = Members0
    }.
class_members(Acc, Acc) --> [].

% Each "section" is a visibility marker followed by zero or more members.
class_section(Vis, Members) -->
    visibility(Vis), ws, class_member_list(Members).
class_section(default, Members) -->
    class_member_list(Members), { Members \= [] }.

visibility(private)   --> kw("private").
visibility(protected) --> kw("protected").
visibility(public)    --> kw("public").
visibility(published) --> kw("published").

class_member_list([M | Ms]) --> class_member(M), ws, class_member_list(Ms).
class_member_list([])       --> [].

class_member(field(default, Names, Type)) -->
    \+ class_member_keyword,
    ident_list(Names), ws, ":", ws, type_expr(Type), ws, ";".
class_member(method_decl(default, Kind, Name, Params, Ret)) -->
    method_kind(Kind), ws, ident(Name), ws,
    optional_params(Params), ws, optional_return(Ret), ws, ";",
    ws, optional_method_attrs.
class_member(property_decl(default, Name, Type, Read, Write)) -->
    kw("property"), ws, ident(Name), ws, ":", ws, type_expr(Type), ws,
    optional_read(Read), ws, optional_write(Write), ws, ";".

class_member_keyword --> kw("private"), !.
class_member_keyword --> kw("protected"), !.
class_member_keyword --> kw("public"), !.
class_member_keyword --> kw("published"), !.
class_member_keyword --> kw("end"), !.
class_member_keyword --> kw("procedure"), !.
class_member_keyword --> kw("function"), !.
class_member_keyword --> kw("constructor"), !.
class_member_keyword --> kw("destructor"), !.
class_member_keyword --> kw("property"), !.

method_kind(procedure)   --> kw("procedure").
method_kind(function)    --> kw("function").
method_kind(constructor) --> kw("constructor").
method_kind(destructor)  --> kw("destructor").

optional_method_attrs --> kw("override"), ws, ";", ws, !.
optional_method_attrs --> kw("virtual"), ws, ";", ws, !.
optional_method_attrs --> kw("overload"), ws, ";", ws, !.
optional_method_attrs --> [].

optional_read(Read)   --> kw("read"),  ws, ident(Read), !.
optional_read(none)   --> [].
optional_write(Write) --> kw("write"), ws, ident(Write), !.
optional_write(none)  --> [].

% Re-tag the most recent batch of members with their visibility.
tag_visibility([], _, []).
tag_visibility([M0 | Ms], Vis, [M | Ts]) :-
    retag(M0, Vis, M),
    tag_visibility(Ms, Vis, Ts).

retag(field(_, N, T), V, field(V, N, T)).
retag(method_decl(_, K, N, P, R), V, method_decl(V, K, N, P, R)).
retag(property_decl(_, N, T, R, W), V, property_decl(V, N, T, R, W)).

% Splice the freshly-tagged members onto the accumulator without losing order.
replace_tail(_, Tagged, Tagged, _).

% var Name : Type;  (single line for now)
var_block(var_decl(Names, Type, none)) -->
    kw("var"), ws, ident_list(Names), ws, ":", ws, type_expr(Type), ws, ";".

const_block(const_decl(Name, Type, Value)) -->
    kw("const"), ws, ident(Name), ws,
    optional_const_type(Type), ws, "=", ws, expression(Value), ws, ";".

optional_const_type(Type) --> ":", ws, type_expr(Type), !.
optional_const_type(none) --> [].

% Stand-alone procedure / function (not bound to a class).
proc_def(proc_def(Kind, Name, Params, Ret, Locals, Body)) -->
    method_kind(Kind), ws, ident(Name), ws,
    optional_params(Params), ws, optional_return(Ret), ws, ";", ws,
    locals(Locals), ws,
    kw("begin"), ws, statements(Body), ws, kw("end"), ws, ";".

% Method body bound to a class:  procedure TFoo.Bar(...);
method_def(method_def(ClassName, Kind, Name, Params, Ret, Locals, Body)) -->
    method_kind(Kind), ws, ident(ClassName), ws, ".", ws, ident(Name), ws,
    optional_params(Params), ws, optional_return(Ret), ws, ";", ws,
    locals(Locals), ws,
    kw("begin"), ws, statements(Body), ws, kw("end"), ws, ";".

optional_params([]) --> "(", ws, ")", !.
optional_params(Ps) --> "(", ws, params(Ps), ws, ")", !.
optional_params([]) --> [].

params([P | Ps]) --> param(P), ws, params_rest(Ps).
params_rest([P | Ps]) --> ";", ws, param(P), ws, params_rest(Ps).
params_rest([]) --> [].

param(param(Mode, Names, Type)) -->
    optional_param_mode(Mode), ws,
    ident_list(Names), ws, ":", ws, type_expr(Type).

optional_param_mode(var)   --> kw("var"), !.
optional_param_mode(const) --> kw("const"), !.
optional_param_mode(out)   --> kw("out"), !.
optional_param_mode(value) --> [].

optional_return(Ret) --> ":", ws, type_expr(Ret), !.
optional_return(none) --> [].

locals([L | Ls]) --> local(L), ws, locals(Ls).
locals([]) --> [].

local(local(Names, Type)) -->
    kw("var"), ws, ident_list(Names), ws, ":", ws, type_expr(Type), ws, ";".

%% ==========================================================================
%% Statements
%% ==========================================================================

statements([S | Ss]) -->
    statement(S), ws, statement_sep, ws, statements(Ss), !.
statements([S]) -->
    statement(S), !.
statements([]) --> [].

statement_sep --> ";", !.
statement_sep --> [].

statement(compound(Ss))    --> kw("begin"), ws, statements(Ss), ws, kw("end").
statement(if(C, T, E))     --> kw("if"), ws, expression(C), ws, kw("then"), ws,
                                statement(T), ws, optional_else(E).
statement(while(C, B))     --> kw("while"), ws, expression(C), ws, kw("do"), ws, statement(B).
statement(for(V, S, E, Dir, B)) -->
    kw("for"), ws, ident(V), ws, ":=", ws, expression(S), ws,
    for_dir(Dir), ws, expression(E), ws, kw("do"), ws, statement(B).
statement(repeat(B, C))    --> kw("repeat"), ws, statements(B), ws, kw("until"), ws, expression(C).
statement(case(E, Arms, Else)) -->
    kw("case"), ws, expression(E), ws, kw("of"), ws,
    case_arms(Arms), ws, optional_case_else(Else), kw("end").
statement(with(Ts, B))     --> kw("with"), ws, with_targets(Ts), ws, kw("do"), ws, statement(B).
statement(try_except(B, H, F)) -->
    kw("try"), ws, statements(B), ws,
    try_tail(H, F).
statement(break)           --> kw("break").
statement(continue)        --> kw("continue").
statement(exit_with(E))    --> kw("exit"), ws, "(", ws, expression(E), ws, ")".
statement(exit)            --> kw("exit").
statement(assign(L, R))    --> lvalue(L), ws, ":=", ws, expression(R).
statement(call(C, A))      --> primary(C), ws, call_args_or_empty(A).

optional_else(E) --> kw("else"), ws, statement(E), !.
optional_else(none) --> [].

for_dir(up)   --> kw("to").
for_dir(down) --> kw("downto").

case_arms([A | As]) --> case_arm(A), ws, ";", ws, case_arms(As).
case_arms([A])      --> case_arm(A), ws.
case_arms([])       --> [].

case_arm(arm(Labels, Stmt)) -->
    case_labels(Labels), ws, ":", ws, statement(Stmt).

case_labels([L | Ls]) --> expression(L), ws, case_label_rest(Ls).
case_label_rest([L | Ls]) --> ",", ws, expression(L), ws, case_label_rest(Ls).
case_label_rest([]) --> [].

optional_case_else(Else) --> kw("else"), ws, statements(Else), ws, !.
optional_case_else([]) --> [].

with_targets([T | Ts]) --> expression(T), ws, with_targets_rest(Ts).
with_targets_rest([T | Ts]) --> ",", ws, expression(T), ws, with_targets_rest(Ts).
with_targets_rest([]) --> [].

try_tail(H, []) --> kw("except"), ws, statements(H), ws, kw("end"), !.
try_tail([], F) --> kw("finally"), ws, statements(F), ws, kw("end"), !.

call_args_or_empty(A) --> "(", ws, expr_list(A), ws, ")", !.
call_args_or_empty([]) --> [].

%% ==========================================================================
%% Expressions  (precedence: or < and < relational < additive < multiplicative < unary < primary)
%% ==========================================================================

expression(E) --> or_expr(E).

or_expr(E) --> and_expr(L), or_rest(L, E).
or_rest(L, E) --> ws, kw("or"),  ws, and_expr(R), { L1 = binop(or,  L, R) }, or_rest(L1, E).
or_rest(L, E) --> ws, kw("xor"), ws, and_expr(R), { L1 = binop(xor, L, R) }, or_rest(L1, E).
or_rest(E, E) --> [].

and_expr(E) --> rel_expr(L), and_rest(L, E).
and_rest(L, E) --> ws, kw("and"), ws, rel_expr(R), { L1 = binop(and, L, R) }, and_rest(L1, E).
and_rest(E, E) --> [].

rel_expr(E) --> add_expr(L), rel_rest(L, E).
rel_rest(L, binop(Op, L, R)) --> ws, rel_op(Op), ws, add_expr(R), !.
rel_rest(E, E) --> [].

rel_op('<>') --> "<>".
rel_op('<=') --> "<=".
rel_op('>=') --> ">=".
rel_op('=')  --> "=".
rel_op('<')  --> "<".
rel_op('>')  --> ">".

add_expr(E) --> mul_expr(L), add_rest(L, E).
add_rest(L, E) --> ws, "+", ws, mul_expr(R), { L1 = binop('+', L, R) }, add_rest(L1, E).
add_rest(L, E) --> ws, "-", ws, mul_expr(R), { L1 = binop('-', L, R) }, add_rest(L1, E).
add_rest(E, E) --> [].

mul_expr(E) --> unary(L), mul_rest(L, E).
mul_rest(L, E) --> ws, "*", ws, unary(R), { L1 = binop('*', L, R) }, mul_rest(L1, E).
mul_rest(L, E) --> ws, "/", ws, unary(R), { L1 = binop('/', L, R) }, mul_rest(L1, E).
mul_rest(L, E) --> ws, kw("div"), ws, unary(R), { L1 = binop(div, L, R) }, mul_rest(L1, E).
mul_rest(L, E) --> ws, kw("mod"), ws, unary(R), { L1 = binop(mod, L, R) }, mul_rest(L1, E).
mul_rest(E, E) --> [].

unary(unop('-', X))   --> "-", ws, unary(X), !.
unary(unop('+', X))   --> "+", ws, unary(X), !.
unary(unop(not, X))   --> kw("not"), ws, unary(X), !.
unary(X)              --> primary(X).

primary(P) --> "(", ws, expression(E), ws, ")", primary_tail(E, P).
primary(P) --> str_lit(S),   primary_tail(str(S),   P).
primary(P) --> float_lit(F), primary_tail(float(F), P).
primary(P) --> int_lit(N),   primary_tail(int(N),   P).
primary(P) --> kw("nil"),    primary_tail(nil,      P).
primary(P) --> kw("true"),   primary_tail(bool(true), P).
primary(P) --> kw("false"),  primary_tail(bool(false), P).
primary(P) --> ident(N),     primary_tail(ident(N), P).

primary_tail(Recv, Out) --> ws, ".", ws, ident(F), { R1 = dot(Recv, F) }, primary_tail(R1, Out).
primary_tail(Recv, Out) --> ws, "(", ws, expr_list(As), ws, ")", { R1 = call(Recv, As) }, primary_tail(R1, Out).
primary_tail(Recv, Out) --> ws, "[", ws, expr_list(Is), ws, "]", { R1 = index(Recv, Is) }, primary_tail(R1, Out).
primary_tail(P, P) --> [].

% L-value: identifier with optional .field / [index] / (args) chain.
% Function calls in the middle are common in Pascal property idioms, e.g.
%   MyDataSet.FieldByName('Name').AsString := 'foo'
lvalue(L) --> ident(N), lvalue_tail(ident(N), L).
lvalue_tail(R, Out) --> ws, ".", ws, ident(F), { R1 = dot(R, F) }, lvalue_tail(R1, Out).
lvalue_tail(R, Out) --> ws, "[", ws, expr_list(Is), ws, "]", { R1 = index(R, Is) }, lvalue_tail(R1, Out).
lvalue_tail(R, Out) --> ws, "(", ws, expr_list(As), ws, ")", { R1 = call(R, As) }, lvalue_tail(R1, Out).
lvalue_tail(L, L) --> [].

expr_list([E | Es]) --> expression(E), ws, expr_list_rest(Es).
expr_list_rest([E | Es]) --> ",", ws, expression(E), ws, expr_list_rest(Es).
expr_list_rest([]) --> [].

%% ==========================================================================
%% Lexical tokens
%% ==========================================================================

ws --> [C], { ws_char(C) }, ws.
ws --> [].

ws_char(0' ).
ws_char(0'\t).
ws_char(0'\n).
ws_char(0'\r).

% Case-insensitive keyword: matches Word if next char is not an identifier char.
kw(Word) -->
    kw_chars(Word),
    \+ ident_continue.

kw_chars([]) --> [].
kw_chars([C | Cs]) --> [Ch], { code_eq_ci(Ch, C) }, kw_chars(Cs).

code_eq_ci(A, B) :- A == B, !.
code_eq_ci(A, B) :- to_lower_code(A, A1), to_lower_code(B, B1), A1 =:= B1.

to_lower_code(C, L) :- C >= 0'A, C =< 0'Z, !, L is C + 32.
to_lower_code(C, C).

ident_continue --> [C], { ident_cont_char(C) }.

ident_start_char(C) :- C >= 0'a, C =< 0'z, !.
ident_start_char(C) :- C >= 0'A, C =< 0'Z, !.
ident_start_char(0'_).

ident_cont_char(C) :- ident_start_char(C), !.
ident_cont_char(C) :- C >= 0'0, C =< 0'9.

ident(Atom) -->
    [C], { ident_start_char(C) },
    ident_rest(Cs),
    { atom_codes(A0, [C | Cs]),
      \+ is_keyword(A0),
      Atom = A0
    }.

ident_rest([C | Cs]) --> [C], { ident_cont_char(C) }, !, ident_rest(Cs).
ident_rest([]) --> [].

int_lit(N) -->
    digits([D | Ds]),
    \+ ".",
    { number_codes(N, [D | Ds]) }.

float_lit(F) -->
    digits([D | Ds]), ".", digits(Fs),
    { append([D | Ds], [0'. | Fs], Codes), number_codes(F, Codes) }.

digits([C | Cs]) --> [C], { C >= 0'0, C =< 0'9 }, digits_rest(Cs).
digits_rest([C | Cs]) --> [C], { C >= 0'0, C =< 0'9 }, !, digits_rest(Cs).
digits_rest([]) --> [].

str_lit(Atom) --> "'", str_chars(Cs), { atom_codes(Atom, Cs) }.
str_chars([0'' | Cs]) --> "''", !, str_chars(Cs).
str_chars([])         --> "'", !.
str_chars([C | Cs])   --> [C], str_chars(Cs).

%% ==========================================================================
%% Reserved keywords
%% ==========================================================================

is_keyword(K) :- pascal_keyword(K0), ci_eq(K, K0).

ci_eq(A, B) :-
    atom_codes(A, AC), atom_codes(B, BC),
    maplist(to_lower_code, AC, AL),
    maplist(to_lower_code, BC, BL),
    AL == BL.

pascal_keyword(unit).        pascal_keyword(uses).
pascal_keyword(interface).   pascal_keyword(implementation).
pascal_keyword(initialization). pascal_keyword(finalization).
pascal_keyword(begin).       pascal_keyword(end).
pascal_keyword(type).        pascal_keyword(class).
pascal_keyword(var).         pascal_keyword(const).
pascal_keyword(procedure).   pascal_keyword(function).
pascal_keyword(constructor). pascal_keyword(destructor).
pascal_keyword(property).    pascal_keyword(read).      pascal_keyword(write).
pascal_keyword(private).     pascal_keyword(protected).
pascal_keyword(public).      pascal_keyword(published).
pascal_keyword(if).          pascal_keyword(then).      pascal_keyword(else).
pascal_keyword(while).       pascal_keyword(do).
pascal_keyword(for).         pascal_keyword(to).        pascal_keyword(downto).
pascal_keyword(repeat).      pascal_keyword(until).
pascal_keyword(case).        pascal_keyword(of).
pascal_keyword(with).
pascal_keyword(try).         pascal_keyword(except).    pascal_keyword(finally).
pascal_keyword(break).       pascal_keyword(continue).  pascal_keyword(exit).
pascal_keyword(and).         pascal_keyword(or).        pascal_keyword(not).
pascal_keyword(div).         pascal_keyword(mod).       pascal_keyword(xor).
pascal_keyword(true).        pascal_keyword(false).     pascal_keyword(nil).
pascal_keyword(override).    pascal_keyword(virtual).   pascal_keyword(overload).
