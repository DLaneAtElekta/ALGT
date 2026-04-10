%% =============================================================================
%% test_c34gl.pl — Headless Tests for c34gl Engine
%% =============================================================================

:- use_module(library(plunit)).
:- use_module(c34gl_engine).
:- use_module(form_registry).

:- begin_tests(c34gl_init).

test(initial_state_has_two_forms) :-
    initial_state(S),
    get_form(incrementer, S, Inc),
    get_form(doubler, S, Dbl),
    Inc.win == idle,
    Dbl.win == idle.

test(initial_counter_is_zero) :-
    initial_state(S),
    materialize_table(S, counter, [Row]),
    get_dict(value, Row, 0).

test(initial_tape_has_seed) :-
    initial_state(S),
    tape_entries(S, Entries),
    length(Entries, 1),
    Entries = [E],
    E.op == insert,
    E.spid == seed.

test(initial_available_events) :-
    initial_state(S),
    available_events(S, incrementer, [start]),
    available_events(S, doubler, [start]).

:- end_tests(c34gl_init).


:- begin_tests(c34gl_incrementer).

test(start_incrementer) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    get_form(incrementer, S1, Inc),
    Inc.win == running,
    Inc.locals.count == 0.

test(increment_once) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(incrementer, increment, S1, S2),
    materialize_table(S2, counter, [Row]),
    get_dict(value, Row, 1),
    get_form(incrementer, S2, Inc),
    Inc.locals.count == 1.

test(increment_three_times) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(incrementer, increment, S1, S2),
    step_form(incrementer, increment, S2, S3),
    step_form(incrementer, increment, S3, S4),
    materialize_table(S4, counter, [Row]),
    get_dict(value, Row, 3),
    S4.step_count == 4.

test(stop_incrementer) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(incrementer, stop, S1, S2),
    get_form(incrementer, S2, Inc),
    Inc.win == closed,
    available_events(S2, incrementer, []).

test(increment_tape_entries) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(incrementer, increment, S1, S2),
    tape_entries(S2, Entries),
    length(Entries, 2),    %% seed + 1 update
    Entries = [Seed, Upd],
    Seed.spid == seed,
    Upd.spid == spid_a,
    Upd.op == update.

:- end_tests(c34gl_incrementer).


:- begin_tests(c34gl_doubler).

test(start_doubler) :-
    initial_state(S0),
    step_form(doubler, start, S0, S1),
    get_form(doubler, S1, Dbl),
    Dbl.win == running,
    Dbl.locals.value == 0.

test(double_from_zero) :-
    initial_state(S0),
    step_form(doubler, start, S0, S1),
    step_form(doubler, double, S1, S2),
    materialize_table(S2, counter, [Row]),
    get_dict(value, Row, 0).   %% 0 * 2 = 0

:- end_tests(c34gl_doubler).


:- begin_tests(c34gl_interleaved).

test(increment_then_double) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(incrementer, increment, S1, S2),   %% counter = 1
    step_form(doubler, start, S2, S3),
    step_form(doubler, double, S3, S4),           %% counter = 1*2 = 2? No: doubler reads tape
    %% Doubler reads current tape value (1) on start, then doubles its LOCAL value
    %% But doubler.start reads materialize → value=1, so locals.value=1
    %% Then double: 1*2=2, writes 2 to tape
    materialize_table(S4, counter, [Row]),
    get_dict(value, Row, 2).

test(double_then_increment) :-
    initial_state(S0),
    step_form(doubler, start, S0, S1),
    step_form(doubler, double, S1, S2),           %% 0*2=0
    step_form(incrementer, start, S2, S3),
    step_form(incrementer, increment, S3, S4),    %% 0+1=1
    materialize_table(S4, counter, [Row]),
    get_dict(value, Row, 1).

test(increment_double_interleaved) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(doubler, start, S1, S2),
    %% Both started, both read counter=0
    step_form(incrementer, increment, S2, S3),    %% writes 1
    %% Doubler's local value is still 0 (read at start)
    step_form(doubler, double, S3, S4),           %% writes 0*2=0 (stale read!)
    materialize_table(S4, counter, [Row]),
    get_dict(value, Row, 0).  %% Lost update: increment's 1 was overwritten

test(refresh_avoids_stale_read) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(doubler, start, S1, S2),
    step_form(incrementer, increment, S2, S3),    %% counter = 1
    step_form(doubler, refresh, S3, S4),          %% doubler re-reads → value=1
    step_form(doubler, double, S4, S5),           %% 1*2=2
    materialize_table(S5, counter, [Row]),
    get_dict(value, Row, 2).

test(tape_attribution) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(doubler, start, S1, S2),
    step_form(incrementer, increment, S2, S3),
    step_form(doubler, double, S3, S4),
    tape_entries(S4, Entries),
    length(Entries, 3),   %% seed + inc_update + dbl_update
    Entries = [Seed, IncUpd, DblUpd],
    Seed.spid == seed,
    IncUpd.spid == spid_a,
    DblUpd.spid == spid_b.

test(step_count_tracks) :-
    initial_state(S0),
    step_form(incrementer, start, S0, S1),
    step_form(doubler, start, S1, S2),
    step_form(incrementer, increment, S2, S3),
    S3.step_count == 3.

:- end_tests(c34gl_interleaved).
