% lfm_parser.pl — Parser for Lazarus form resource files (.lfm)
%
% Lazarus stores form layout in a text resource file:
%
%   object MainForm: TMainForm
%     Left = 100
%     Top  = 100
%     Caption = 'MUZAQ'
%     object Button1: TButton
%       Left    = 16
%       Top     = 16
%       Caption = 'Save'
%       OnClick = Button1Click
%     end
%     object MyDataSet: TSQLQuery
%       SQL.Strings = ('SELECT * FROM patients')
%     end
%   end
%
% AST shape:
%   form(Name, Class, Properties, Children)
%     Properties = [prop(Name, Value), ...]
%     Children   = [form(...), ...]
%
%   Value = int(N) | str(S) | ident(Name) | strings([S, ...]) | tuple([V,...])

:- module(lfm_parser, [
    parse_lfm/2          % parse_lfm(+Source, -Form)
]).

:- set_prolog_flag(double_quotes, codes).
:- use_module(pascal_parser, []).

parse_lfm(Source, Form) :-
    ( atom(Source)  -> atom_codes(Source, Codes)
    ; string(Source)-> string_codes(Source, Codes)
    ; Codes = Source
    ),
    phrase(form(Form), Codes, Rest),
    ( all_ws(Rest) -> true
    ; format(user_error, "parse_lfm: trailing text not consumed: ~s~n", [Rest]),
      fail
    ).

all_ws([]).
all_ws([C | T]) :- ( C == 0' ; C == 0'\t ; C == 0'\n ; C == 0'\r ), all_ws(T).

form(form(Name, Class, Props, Children)) -->
    ws, kw("object"), ws, ident(Name), ws, ":", ws, ident(Class), ws,
    body(Props, Children),
    ws, kw("end").

body(Props, Children) -->
    properties(Props), ws, sub_objects(Children).

properties([prop(N, V) | Ps]) -->
    \+ kw("object"), \+ kw("end"),
    property_name(N), ws, "=", ws, value(V), ws, !,
    properties(Ps).
properties([]) --> [].

property_name(Name) -->
    ident(Head), property_qual(Tail),
    { atom_concat(Head, Tail, Name) }.

property_qual(Q) -->
    ".", ident(Sub), property_qual(Rest),
    { atom_concat('.', Sub, Q1), atom_concat(Q1, Rest, Q) }.
property_qual('') --> [].

value(strings(Lines)) --> "(", ws, str_list(Lines), ws, ")", !.
value(tuple(Vs))      --> "(", ws, value_list(Vs), ws, ")", !.
value(str(S))         --> str_lit(S), !.
value(int(N))         --> integer(N), !.
value(ident(I))       --> ident(I), !.

str_list([S | Ss]) --> str_lit(S), ws, str_list(Ss).
str_list([])       --> [].

value_list([V | Vs]) --> value(V), ws, value_list_rest(Vs).
value_list_rest([V | Vs]) --> ",", ws, value(V), ws, value_list_rest(Vs).
value_list_rest([]) --> [].

sub_objects([F | Fs]) --> form(F), ws, !, sub_objects(Fs).
sub_objects([]) --> [].

%% --- shared lexical helpers (kept local to avoid coupling to pascal_parser) ---

ws --> [C], { C == 0' ; C == 0'\t ; C == 0'\n ; C == 0'\r }, ws.
ws --> [].

ident(Atom) -->
    [C], { ident_start(C) }, ident_rest(Cs),
    { atom_codes(Atom, [C | Cs]) }.
ident_rest([C | Cs]) --> [C], { ident_cont(C) }, !, ident_rest(Cs).
ident_rest([]) --> [].

ident_start(C) :- C >= 0'a, C =< 0'z.
ident_start(C) :- C >= 0'A, C =< 0'Z.
ident_start(0'_).
ident_cont(C)  :- ident_start(C), !.
ident_cont(C)  :- C >= 0'0, C =< 0'9.

kw(Word) --> kw_chars(Word), \+ ident_continue.
kw_chars([])       --> [].
kw_chars([C | Cs]) --> [Ch], { ci_eq(Ch, C) }, kw_chars(Cs).
ident_continue --> [C], { ident_cont(C) }.

ci_eq(A, B) :- A == B, !.
ci_eq(A, B) :- to_lower(A, A1), to_lower(B, B1), A1 =:= B1.
to_lower(C, L) :- C >= 0'A, C =< 0'Z, !, L is C + 32.
to_lower(C, C).

integer(N) --> digit(D), digits(Ds), { number_codes(N, [D | Ds]) }.
digit(C)  --> [C], { C >= 0'0, C =< 0'9 }.
digits([D | Ds]) --> [D], { D >= 0'0, D =< 0'9 }, !, digits(Ds).
digits([]) --> [].

str_lit(Atom) --> "'", str_chars(Cs), { atom_codes(Atom, Cs) }.
str_chars([0'' | Cs]) --> "''", !, str_chars(Cs).
str_chars([]) --> "'", !.
str_chars([C | Cs]) --> [C], str_chars(Cs).
