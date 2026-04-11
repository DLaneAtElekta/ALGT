%% =============================================================================
%% form_doubler.pl — Form B: Counter Doubler
%% =============================================================================
%%
%% A minimal synthetic form that reads a shared counter and doubles it.
%% Events: start → double* → stop
%% =============================================================================

:- module(form_doubler, [
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
    FS1 = FS0.put(_{win: running, locals: locals{value: Val}}).

%% double: write counter*2 to tape
form_step(double, FS0, FS1, DB0, DB1) :-
    FS0.win == running,
    NewVal is FS0.locals.value * 2,
    exec_list(FS0.spid,
        [sql_update(counter, row{value: NewVal}, where(id, =, 1))],
        DB0, DB1),
    FS1 = FS0.put(_{locals: locals{value: NewVal},
                     last_tx: DB1.next_tx - 1}).

%% refresh: re-read counter from tape
form_step(refresh, FS0, FS1, DB0, DB0) :-
    FS0.win == running,
    materialize(DB0, counter, Rows),
    (   Rows = [Row|_] -> get_dict(value, Row, Val) ; Val = 0 ),
    FS1 = FS0.put(locals, locals{value: Val}).

%% stop: transition to closed
form_step(stop, FS0, FS1, DB, DB) :-
    FS0.win == running,
    FS1 = FS0.put(win, closed).

%% available_events(+FS, -Events)
available_events(FS, [start])                  :- FS.win == idle, !.
available_events(FS, [double, refresh, stop])  :- FS.win == running, !.
available_events(_, []).
