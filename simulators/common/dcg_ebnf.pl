% dcg_ebnf.pl — Convert DCG rules to Mermaid railroad diagrams (Universal Version)
%
% Usage:
%   swipl -l dcg_ebnf.pl -g main -t halt -- --in <file.pl> --out <file.md> [--top <names>] [--ignore <names>]
%
% Example (Clarion):
%   swipl -l dcg_ebnf.pl -g main -t halt -- --in clarion_parser.pl --out clarion_railroad.md
%
% Example (F#):
%   swipl -l dcg_ebnf.pl -g main -t halt -- --in fsharp_parser.pl --out fsharp_railroad.md

:- module(dcg_ebnf, [
    main/0,
    generate_ebnf/4
]).

:- use_module(library(lists)).
:- use_module(library(apply)).

%% ==========================================================================
%% Entry point
%% ==========================================================================

main :-
    current_prolog_flag(argv, Argv),
    (   parse_args(Argv, In, Out, Top, Ignore)
    ->  generate_ebnf(In, Out, Top, Ignore)
    ;   usage
    ).

usage :-
    format("Usage: swipl -l dcg_ebnf.pl -g main -t halt -- --in <file.pl> --out <file.md> [--top <name1,name2>] [--ignore <name1,name2>]~n").

parse_args(Argv, In, Out, Top, Ignore) :-
    ( member('--in', Argv) -> select('--in', Argv, InRest), [In|InRest2] = InRest ; In = 'clarion_parser.pl', InRest2 = Argv ),
    ( member('--out', Argv) -> select('--out', InRest2, OutRest), [Out|OutRest2] = OutRest ; Out = 'clarion_railroad.md', OutRest2 = InRest2 ),
    ( member('--top', OutRest2) -> select('--top', OutRest2, TopRest), [TopStr|TopRest2] = TopRest, split_string(TopStr, ",", " ", TopStrs), maplist(atom_string, Top, TopStrs) ; Top = all, TopRest2 = OutRest2 ),
    ( member('--ignore', TopRest2) -> select('--ignore', TopRest2, IgnoreRest), [IgnoreStr|_] = IgnoreRest, split_string(IgnoreStr, ",", " ", IgnoreStrs), maplist(atom_string, Ignore, IgnoreStrs) ; Ignore = default ).

%% ==========================================================================
%% Core Logic
%% ==========================================================================

generate_ebnf(In, Out, Top, Ignore) :-
    ( Ignore == default ->
        IgnoreList = [ws, ws_nonnl, ws_no_nl, comment_body, line_continuation,
                      kw, digit, digits, qchars, ident_rest,
                      to_upper, number, digits,
                      star, comma_list, comma_list_rest, comma_attrs]
    ;   IgnoreList = Ignore
    ),
    extract_dcg_rules(In, IgnoreList, Rules),
    group_rules(Rules, Grouped),
    filter_productions(Top, Grouped, Selected),
    generate_markdown(In, Selected, MD),
    setup_call_cleanup(
        open(Out, write, Stream),
        write(Stream, MD),
        close(Stream)
    ),
    length(Selected, N),
    format("Generated ~w from ~w (~w production diagrams).~n", [Out, In, N]).

extract_dcg_rules(File, Ignore, Rules) :-
    current_prolog_flag(double_quotes, OldFlag),
    set_prolog_flag(double_quotes, codes),
    setup_call_cleanup(
        open(File, read, In),
        read_all_terms(In, Terms),
        close(In)
    ),
    set_prolog_flag(double_quotes, OldFlag),
    include(is_dcg_rule(Ignore), Terms, Rules).

read_all_terms(In, Terms) :-
    read_term(In, T, []),
    ( T == end_of_file
    -> Terms = []
    ; Terms = [T|Rest],
      read_all_terms(In, Rest)
    ).

is_dcg_rule(Ignore, (Head --> _Body)) :-
    callable(Head),
    functor(Head, Name, _),
    \+ member(Name, Ignore).

group_rules(Rules, Grouped) :-
    map_list_to_pairs(rule_key, Rules, Pairs),
    keysort(Pairs, Sorted),
    group_pairs_by_key(Sorted, Grouped).

rule_key((Head --> _), Name) :-
    functor(Head, Name, _).

filter_productions(all, Grouped, Grouped).
filter_productions(Names, Grouped, Selected) :-
    is_list(Names),
    include(key_in(Names), Grouped, Selected).

key_in(Names, Key-_) :- member(Key, Names).

generate_markdown(In, Productions, MD) :-
    maplist(production_to_mermaid, Productions, Blocks),
    format(atom(Header), "# Railroad Diagrams for ~w\n\nGenerated from DCG rules.\n\n", [In]),
    atomic_list_concat([Header | Blocks], MD).

production_to_mermaid(Name-Rules, Block) :-
    reset_counter,
    fresh_id(StartId),
    fresh_id(EndId),
    maplist(single_rule_to_mermaid(StartId, EndId), Rules, NodeLists, EdgeLists),
    flatten(NodeLists, Nodes0),
    flatten(EdgeLists, Edges0),
    format_node(StartId, start, circle, StartNode),
    format_node(EndId, finish, circle, EndNode),
    append(Nodes0, [StartNode, EndNode], AllNodes),
    sort(AllNodes, UniqueNodes),
    sort(Edges0, UniqueEdges),
    atomic_list_concat(UniqueNodes, NodeBlock),
    atomic_list_concat(UniqueEdges, EdgeBlock),
    format(atom(Block),
           '## ~w\n\n```mermaid\nflowchart LR\n~w~w```\n\n',
           [Name, NodeBlock, EdgeBlock]).

single_rule_to_mermaid(StartId, EndId, (_Head --> Body), Nodes, Edges) :-
    body_to_mermaid(Body, StartId, EndId, Nodes, Edges), !.
single_rule_to_mermaid(StartId, EndId, _, [], [Edge]) :-
    format(atom(Edge), '    ~w --> ~w\n', [StartId, EndId]).

% Sequence (A, B)
body_to_mermaid((A, B), InId, OutId, Nodes, Edges) :-
    !,
    fresh_id(MidId),
    body_to_mermaid(A, InId, MidId, N1, E1),
    body_to_mermaid(B, MidId, OutId, N2, E2),
    append(N1, N2, Nodes),
    append(E1, E2, Edges).

% Alternative (A ; B)
body_to_mermaid((A ; B), InId, OutId, Nodes, Edges) :-
    !,
    body_to_mermaid(A, InId, OutId, NA, EA),
    body_to_mermaid(B, InId, OutId, NB, EB),
    append(NA, NB, Nodes),
    append(EA, EB, Edges).

% If-then (A -> B)
body_to_mermaid((A -> B), InId, OutId, Nodes, Edges) :-
    !,
    body_to_mermaid((A, B), InId, OutId, Nodes, Edges).

body_to_mermaid(!, InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).

body_to_mermaid({_}, InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).

body_to_mermaid(\+(_), InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).

body_to_mermaid(kw(Codes), InId, OutId, [Node], [Edge]) :-
    is_code_list(Codes), !,
    atom_codes(KW, Codes),
    fresh_id(NId),
    format_node(NId, KW, keyword, Node),
    format(atom(Edge), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]).

body_to_mermaid(Terminal, InId, OutId, [Node], [Edge]) :-
    is_code_list(Terminal), !,
    atom_codes(Text, Terminal),
    fresh_id(NId),
    escape_label(Text, Safe),
    format_node(NId, Safe, terminal, Node),
    format(atom(Edge), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]).

body_to_mermaid([C], InId, OutId, [Node], [Edge]) :-
    integer(C), !,
    fresh_id(NId),
    char_code(Ch, C),
    escape_label(Ch, Safe),
    format_node(NId, Safe, terminal, Node),
    format(atom(Edge), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]).

body_to_mermaid(star(Goal, _), InId, OutId, Nodes, Edges) :-
    callable(Goal), !,
    functor(Goal, GoalName, _),
    fresh_id(NId),
    format_node(NId, GoalName, nonterminal, Node),
    format(atom(E1), '    ~w --> ~w\n', [InId, OutId]),
    format(atom(E2), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]),
    format(atom(E3), '    ~w -.-> ~w\n', [NId, InId]),
    Nodes = [Node],
    Edges = [E1, E2, E3].

body_to_mermaid(comma_list(Goal, _), InId, OutId, Nodes, Edges) :-
    callable(Goal), !,
    functor(Goal, GoalName, _),
    fresh_id(NId), fresh_id(CommaId),
    format_node(NId, GoalName, nonterminal, GNode),
    format_node(CommaId, ',', terminal, CNode),
    format(atom(E1), '    ~w --> ~w\n', [InId, OutId]),
    format(atom(E2), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]),
    format(atom(E3), '    ~w -.-> ~w -.-> ~w\n', [NId, CommaId, InId]),
    Nodes = [GNode, CNode],
    Edges = [E1, E2, E3].

body_to_mermaid(ws, InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).
body_to_mermaid(ws_nonnl, InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).
body_to_mermaid(ws_no_nl, InId, OutId, [], [Edge]) :- !,
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).

body_to_mermaid(NT, InId, OutId, [Node], [Edge]) :-
    callable(NT), \+ is_list(NT), !,
    functor(NT, Name, _),
    fresh_id(NId),
    format_node(NId, Name, nonterminal, Node),
    format(atom(Edge), '    ~w --> ~w --> ~w\n', [InId, NId, OutId]).

body_to_mermaid(_, InId, OutId, [], [Edge]) :-
    ( InId \= OutId -> format(atom(Edge), '    ~w --> ~w\n', [InId, OutId]) ; Edge = '' ).

is_code_list(Term) :- is_list(Term), Term \= [], maplist(integer, Term).

format_node(Id, Label, keyword, Node) :- !, format(atom(Node), '    ~w[/"~w"/]~n', [Id, Label]).
format_node(Id, Label, terminal, Node) :- !, format(atom(Node), '    ~w(["~w"])~n', [Id, Label]).
format_node(Id, Label, nonterminal, Node) :- !, format(atom(Node), '    ~w["~w"]~n', [Id, Label]).
format_node(Id, _Label, circle, Node) :- format(atom(Node), '    ~w(((" ")))~n', [Id]).

escape_label(Text, Safe) :-
    atom_chars(Text, Chars),
    maplist(esc_char, Chars, EscParts),
    flatten(EscParts, FlatChars),
    atom_chars(Safe, FlatChars).

esc_char('"', ['&','#','3','4',';']) :- !.
esc_char('<', ['&','l','t',';']) :- !.
esc_char('>', ['&','g','t',';']) :- !.
esc_char(C, [C]).

:- dynamic counter/1.
counter(0).
reset_counter :- retractall(counter(_)), assert(counter(0)).
fresh_id(Id) :- retract(counter(N)), N1 is N + 1, assert(counter(N1)), format(atom(Id), 'n~w', [N]).
