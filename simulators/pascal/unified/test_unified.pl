% test_unified.pl — Smoke test for the Pascal/Lazarus simulator.
%
% Verifies:
%   1. The HelloMUZAQ.pas + HelloMUZAQ.lfm sample parses cleanly.
%   2. Loading the module registers the form, button, and dataset.
%   3. Firing Button1.OnClick produces a SQL transaction log with the
%      expected sequence (insert → set_field × 2 → post → apply_updates).

:- use_module(pascal).

:- initialization(main, main).

main :-
    catch(run_tests, E,
          ( format(user_error, "ERROR: ~q~n", [E]), halt(1) )),
    halt(0).

run_tests :-
    Results = [],
    test_parse_pascal(Results, R1),
    test_parse_lfm(R1, R2),
    test_load_module(R2, R3),
    test_fire_click(R3, R4),
    report(R4).

%% Test 1: parse the sample Pascal file.
test_parse_pascal(R, [parse_pascal:Status | R]) :-
    sample_pas(File),
    read_file_to_string(File, Src, []),
    ( catch(pascal:parse_pascal(Src, _AST), _, fail)
    -> Status = ok
    ; Status = fail
    ).

%% Test 2: parse the sample LFM file.
test_parse_lfm(R, [parse_lfm:Status | R]) :-
    sample_lfm(File),
    read_file_to_string(File, Src, []),
    ( catch(pascal:parse_lfm(Src, _Form), _, fail)
    -> Status = ok
    ; Status = fail
    ).

%% Test 3: load module, verify the form and its children are registered.
test_load_module(R, [load_module:Status | R]) :-
    sample_pas(P), sample_lfm(L),
    ( catch(pascal:load_unit(P, [L], State), _, fail),
      simulator_state:lookup_form('MainForm', State, _),
      simulator_state:lookup_object('Button1', State, object('TButton', _)),
      simulator_state:lookup_object('MyDataSet', State, object('TSQLQuery', _))
    -> Status = ok
    ; Status = fail
    ).

%% Test 4: fire OnClick → expect insert, set_field × 2, post, apply_updates.
test_fire_click(R, [fire_click:Status | R]) :-
    sample_pas(P), sample_lfm(L),
    pascal:load_unit(P, [L], S0),
    pascal:fire_event(click('MainForm', 'Button1'), S0, S1),
    pascal:sql_log(S1, Entries),
    extract_actions(Entries, Actions),
    ( Actions == [insert, set_field, set_field, post, apply_updates]
    -> Status = ok
    ; Status = fail(Actions)
    ).

extract_actions([], []).
extract_actions([log(_, _, A, _, _) | Rest], [A | As]) :-
    extract_actions(Rest, As).

sample_pas('../../../pascal_samples/modern-lazarus/HelloMUZAQ.pas').
sample_lfm('../../../pascal_samples/modern-lazarus/HelloMUZAQ.lfm').

report(Results) :-
    reverse(Results, Ordered),
    forall(member(Test:Status, Ordered),
           format("~w  ~w~n", [Status, Test])),
    ( member(_:Status, Ordered), Status \== ok
    -> format("SOME TESTS FAILED~n"), fail
    ; format("ALL TESTS PASSED~n")
    ).
