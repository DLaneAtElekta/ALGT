%% =============================================================================
%% c34gl_engine.pl — See-Through 4GL Engine
%% =============================================================================
%%
%% Manages the composite state: tape (sql_srv_sim DB) + form heads.
%% Each form is a read/write head on the shared tape (transaction log).
%%
%% The tape is the sql_srv_sim append-only log.
%% Each head has local state (win, locals) and a SPID for DB operations.
%% =============================================================================

:- module(c34gl_engine, [
    initial_state/1,
    step_form/4,
    materialize_table/3,
    tape_entries/2,
    get_form/3,
    get_all_forms/2,
    available_events/3,
    reset_state/2
]).

:- use_module('../../../../__mosaiq_src/33_cpp_clw/_translations/prolog_purs/common/sql_srv_sim/sql_srv_sim').
:- use_module(form_registry).


%% =============================================================================
%% State Structure
%% =============================================================================
%%
%% c34gl_state{
%%   db:         db{...}                — sql_srv_sim DB (the tape)
%%   forms:      forms{id → form_state} — form head states
%%   step_count: int                    — global step counter
%%   spid_map:   [TxId-Spid, ...]      — who wrote each log entry
%% }
%%
%% form_state{
%%   form_id:  atom,        — incrementer | doubler
%%   spid:     atom,        — spid_a | spid_b
%%   win:      atom,        — idle | running | closed
%%   locals:   dict,        — form-local variables
%%   last_tx:  int | none,  — TxId of last write
%%   history:  list         — events consumed (newest first)
%% }


%% =============================================================================
%% Initialization
%% =============================================================================

initial_state(State) :-
    %% Create empty DB and seed the counter table
    empty_db(DB0),
    exec_list([sql_insert(counter, row{id: 1, value: 0})], DB0, DB1),

    %% Create form heads
    FS_Inc = form_state{
        form_id: incrementer, spid: spid_a, win: idle,
        locals: locals{count: 0}, last_tx: none, history: []
    },
    FS_Dbl = form_state{
        form_id: doubler, spid: spid_b, win: idle,
        locals: locals{value: 0}, last_tx: none, history: []
    },

    State = c34gl_state{
        db:         DB1,
        forms:      forms{incrementer: FS_Inc, doubler: FS_Dbl},
        step_count: 0,
        spid_map:   [1-seed]    %% TxId 1 = seed insert
    }.


%% =============================================================================
%% Step a Form
%% =============================================================================

%% step_form(+FormId, +Event, +S0, -S1)
step_form(FormId, Event, S0, S1) :-
    %% Look up form state
    get_form(FormId, S0, FS0),
    %% Delegate to form module
    form_step(FormId, Event, FS0, FS1, S0.db, DB1),
    %% Record SPID attribution for new log entries
    record_attribution(S0.db, DB1, FS0.spid, S0.spid_map, NewMap),
    %% Update last_tx
    (   DB1.next_tx > S0.db.next_tx
    ->  LastTx is DB1.next_tx - 1
    ;   LastTx = FS0.last_tx
    ),
    FS2 = FS1.put(_{last_tx: LastTx, history: [Event | FS0.history]}),
    %% Assemble new state
    NewForms = S0.forms.put(FormId, FS2),
    NewStep is S0.step_count + 1,
    S1 = S0.put(_{db: DB1, forms: NewForms, step_count: NewStep, spid_map: NewMap}).


%% =============================================================================
%% Query Helpers
%% =============================================================================

get_form(FormId, State, FS) :-
    get_dict(FormId, State.forms, FS).

get_all_forms(State, FormsList) :-
    dict_pairs(State.forms, _, Pairs),
    maplist([_K-V, V]>>true, Pairs, FormsList).

materialize_table(State, Table, Rows) :-
    materialize(State.db, Table, Rows).

available_events(State, FormId, Events) :-
    get_form(FormId, State, FS),
    form_available_events(FormId, FS, Events).

reset_state(_OldState, NewState) :-
    initial_state(NewState).


%% =============================================================================
%% Tape Entries (Chronological with SPID Attribution)
%% =============================================================================

%% tape_entries(+State, -Entries)
%%   Returns the log in chronological order, each entry annotated with SPID.
tape_entries(State, Entries) :-
    reverse(State.db.log, ChronLog),
    annotate_entries(ChronLog, State.spid_map, Entries).

annotate_entries([], _, []).
annotate_entries([log_entry(TxId, Op) | Rest], Map, [Entry | RestOut]) :-
    (   member(TxId-Spid, Map)
    ->  true
    ;   Spid = unknown
    ),
    op_summary(Op, Table, OpType, Summary),
    Entry = tape_entry{
        tx_id: TxId, spid: Spid, op: OpType,
        table: Table, summary: Summary
    },
    annotate_entries(Rest, Map, RestOut).


%% =============================================================================
%% Operation Summaries (for tape cell display)
%% =============================================================================

op_summary(insert(Table, Row), Table, insert, Summary) :-
    format(atom(Summary), '~w', [Row]).
op_summary(update(Table, _Pk, NewVals, _OldVals), Table, update, Summary) :-
    format(atom(Summary), '~w', [NewVals]).
op_summary(delete(Table, Pk, _OldRow), Table, delete, Summary) :-
    format(atom(Summary), 'pk=~w', [Pk]).
op_summary(compensation(InnerOp), Table, compensation, Summary) :-
    op_summary(InnerOp, Table, _, InnerSummary),
    format(atom(Summary), 'UNDO ~w', [InnerSummary]).
op_summary(begin_tran(Name), '', begin_tran, Name).
op_summary(commit_tran(Name), '', commit, Name).
op_summary(save_tran(Name), '', savepoint, Name).
op_summary(abort_tran, '', abort, abort).
%% Fallback
op_summary(_, '', unknown, '?').


%% =============================================================================
%% SPID Attribution
%% =============================================================================

%% record_attribution(+OldDB, +NewDB, +Spid, +OldMap, -NewMap)
%%   Record SPID for any new log entries (TxIds between old.next_tx and new.next_tx - 1).
record_attribution(OldDB, NewDB, Spid, OldMap, NewMap) :-
    OldTx = OldDB.next_tx,
    NewTx = NewDB.next_tx,
    (   NewTx > OldTx
    ->  numlist(OldTx, NewTx - 1, NewTxIds),
        maplist(pair_with(Spid), NewTxIds, NewPairs),
        append(OldMap, NewPairs, NewMap)
    ;   NewMap = OldMap
    ).

pair_with(Spid, TxId, TxId-Spid).

%% numlist with expression evaluation
numlist(Low, HighExpr, List) :-
    High is HighExpr,
    (   High >= Low
    ->  numlist_(Low, High, List)
    ;   List = []
    ).

numlist_(Low, High, [Low | Rest]) :-
    Low =< High, !,
    Next is Low + 1,
    numlist_(Next, High, Rest).
numlist_(_, _, []).
