% pascal.pl — Public API for the Pascal/Lazarus simulator.
%
% Usage:
%   :- use_module(pascal).
%   load_unit(PasFile, LfmFiles, State).
%   fire_event(click('MainForm', 'Button1'), State, State2).
%   sql_log(State2, Entries).

:- module(pascal, [
    parse_pascal/2,
    parse_lfm/2,
    load_unit/3,
    load_sources/3,
    fire_event/3,
    invoke_method/5,
    sql_log/2,
    output_lines/2
]).

:- use_module(pascal_parser, [parse_pascal/2]).
:- use_module(lfm_parser,    [parse_lfm/2]).
:- use_module(ast_bridge,    [bridge_unit/3]).
:- use_module(simulator,     [load_module/2, fire_event/3, invoke_method/5]).
:- use_module(simulator_state).

%% load_unit(+PasFile, +LfmFiles, -State)
load_unit(PasFile, LfmFiles, State) :-
    read_file_to_string(PasFile, PasSrc, []),
    maplist(read_file_to_string_, LfmFiles, LfmSrcs),
    load_sources(PasSrc, LfmSrcs, State).

read_file_to_string_(File, Str) :-
    read_file_to_string(File, Str, []).

%% load_sources(+PascalSource, +LfmSources, -State)
load_sources(PasSrc, LfmSrcs, State) :-
    parse_pascal(PasSrc, UnitAST),
    maplist(parse_lfm, LfmSrcs, FormASTs),
    bridge_unit(UnitAST, FormASTs, Module),
    load_module(Module, State).

%% sql_log(+State, -Entries)  — chronological transaction log
sql_log(State, Entries) :-
    simulator_state:log_entries(State, Entries).

%% output_lines(+State, -Lines)  — chronological captured output
output_lines(State, Lines) :-
    simulator_state:get_out(State, Lines).
