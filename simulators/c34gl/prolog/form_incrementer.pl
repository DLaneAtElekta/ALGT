%% =============================================================================
%% form_incrementer.pl — Form A: Counter Incrementer
%% =============================================================================
%%
%% A minimal synthetic form that reads a shared counter and increments it.
%% Events: start → increment* → stop
%% =============================================================================

:- module(form_incrementer, [
    form_step/5,
    available_events/2
]).

:- use_module('../../../../__mosaiq_src/33_cpp_clw/_translations/prolog_purs/common/sql_srv_sim/sql_srv_sim').

%% form_step(+Event, +FS0, -FS1, +DB0, -DB1)

%% start: read counter from tape, transition to running
form_step(start, FS0, FS1, DB0, DB0) :-
    FS0.win == idle,
    materialize(DB0, counter, Rows),
    (   Rows = [Row|_] -> get_dict(value, Row, Val) ; Val = 0 ),
    FS1 = FS0.put(_{win: running, locals: locals{count: Val}}).

%% increment: write counter+1 to tape
form_step(increment, FS0, FS1, DB0, DB1) :-
    FS0.win == running,
    NewVal is FS0.locals.count + 1,
    exec_list(FS0.spid,
        [sql_update(counter, row{value: NewVal}, where(id, =, 1))],
        DB0, DB1),
    FS1 = FS0.put(_{locals: locals{count: NewVal},
                     last_tx: DB1.next_tx - 1}).

%% refresh: re-read counter from tape (see what others wrote)
form_step(refresh, FS0, FS1, DB0, DB0) :-
    FS0.win == running,
    materialize(DB0, counter, Rows),
    (   Rows = [Row|_] -> get_dict(value, Row, Val) ; Val = 0 ),
    FS1 = FS0.put(locals, locals{count: Val}).

%% stop: transition to closed
form_step(stop, FS0, FS1, DB, DB) :-
    FS0.win == running,
    FS1 = FS0.put(win, closed).

%% available_events(+FS, -Events)
available_events(FS, [start])                    :- FS.win == idle, !.
available_events(FS, [increment, refresh, stop]) :- FS.win == running, !.
available_events(_, []).
