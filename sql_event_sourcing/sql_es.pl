/*
    SQL Event Sourcing Engine

    Demonstrates how a SQL database is fundamentally an event sourcing system.
    Every SQL operation (INSERT, UPDATE, DELETE) is an event that modifies state.
    The current state is the projection of all events applied in sequence.

    Term Format (CQL-style):
    - SELECT: table :: [col-Var, ...]
    - INSERT: insert(table, [col-val, ...])
    - UPDATE: update(table, [col-val, ...]), @ :: [where_conditions]
    - DELETE: delete(table, [pk-val])

    Author: Claude Code
    Based on event sourcing patterns in ALGT codebase
*/

:- module(sql_es, [
    % Event management
    emit_event/1,
    get_events/1,
    clear_events/0,
    replay_events/1,

    % DDL operations (emit events)
    create_table/2,
    drop_table/1,

    % DML operations (emit events)
    sql_insert/2,
    sql_update/3,
    sql_delete/2,

    % Query operations (project current state)
    sql_select/2,
    sql_select/3,

    % Transaction support
    begin_transaction/0,
    commit_transaction/0,
    rollback_transaction/0,

    % State inspection
    current_state/1,
    table_rows/2,
    table_schema/2,

    % Utilities
    print_events/0,
    print_state/0
]).

:- use_module(library(lists)).
:- use_module(library(apply)).

%% ---------------------------------------------------------------------------
%% Event Store
%%
%% Events are stored as dynamic facts. Each event has a sequence number
%% and timestamp for ordering and auditing.
%% ---------------------------------------------------------------------------

:- dynamic event/3.          % event(SeqNum, Timestamp, EventTerm)
:- dynamic seq_counter/1.    % Sequence number counter
:- dynamic transaction/1.    % transaction(pending_events)
:- dynamic in_transaction/0. % Flag for active transaction

seq_counter(0).

%% next_seq(-SeqNum) is det.
%  Get next sequence number
next_seq(SeqNum) :-
    retract(seq_counter(Current)),
    SeqNum is Current + 1,
    assertz(seq_counter(SeqNum)).

%% emit_event(+EventTerm) is det.
%  Record an event to the event store (or pending transaction)
emit_event(EventTerm) :-
    get_time(Timestamp),
    next_seq(SeqNum),
    Event = event(SeqNum, Timestamp, EventTerm),
    (   in_transaction
    ->  % Add to pending transaction events
        retract(transaction(Pending)),
        assertz(transaction([Event|Pending]))
    ;   % Commit directly
        assertz(Event)
    ).

%% get_events(-Events) is det.
%  Retrieve all events in sequence order
get_events(Events) :-
    findall(event(Seq, TS, Term), event(Seq, TS, Term), Unsorted),
    sort(1, @<, Unsorted, Events).

%% clear_events is det.
%  Clear all events (reset database)
clear_events :-
    retractall(event(_, _, _)),
    retractall(seq_counter(_)),
    retractall(transaction(_)),
    retractall(in_transaction),
    assertz(seq_counter(0)).

%% replay_events(+Events) is det.
%  Replay a list of events (for restoring state)
replay_events([]).
replay_events([event(_, _, Term)|Rest]) :-
    assertz_event_direct(Term),
    replay_events(Rest).

assertz_event_direct(Term) :-
    get_time(Timestamp),
    next_seq(SeqNum),
    assertz(event(SeqNum, Timestamp, Term)).

%% ---------------------------------------------------------------------------
%% Event Types
%%
%% DDL Events:
%%   - table_created(TableName, Schema)
%%   - table_dropped(TableName)
%%
%% DML Events:
%%   - row_inserted(TableName, RowId, ColumnValues)
%%   - row_updated(TableName, RowId, OldValues, NewValues)
%%   - row_deleted(TableName, RowId, OldValues)
%%
%% Transaction Events:
%%   - transaction_started(TxId)
%%   - transaction_committed(TxId)
%%   - transaction_rolled_back(TxId)
%% ---------------------------------------------------------------------------

%% ---------------------------------------------------------------------------
%% DDL Operations
%% ---------------------------------------------------------------------------

%% create_table(+TableName, +Schema) is det.
%  Schema is a list of column definitions: [col(name, type), ...]
%  Example: create_table(users, [col(id, integer), col(name, varchar), col(email, varchar)])
create_table(TableName, Schema) :-
    emit_event(table_created(TableName, Schema)).

%% drop_table(+TableName) is det.
drop_table(TableName) :-
    emit_event(table_dropped(TableName)).

%% ---------------------------------------------------------------------------
%% DML Operations (CQL-style syntax)
%% ---------------------------------------------------------------------------

%% sql_insert(+TableName, +ColumnValues) is det.
%  Insert a row. ColumnValues is [col-val, ...] (CQL style)
%  Example: sql_insert(users, [id-1, name-'Alice', email-'alice@example.com'])
sql_insert(TableName, ColumnValues) :-
    generate_row_id(RowId),
    emit_event(row_inserted(TableName, RowId, ColumnValues)).

%% sql_update(+TableName, +NewValues, +WhereClause) is det.
%  Update rows matching WhereClause
%  Example: sql_update(users, [name-'Bob'], [id-1])
sql_update(TableName, NewValues, WhereClause) :-
    % Find all matching rows
    current_table_rows(TableName, AllRows),
    include(row_matches(WhereClause), AllRows, MatchingRows),
    % Emit update events for each matching row
    forall(
        member(row(RowId, OldValues), MatchingRows),
        (   merge_values(OldValues, NewValues, MergedValues),
            emit_event(row_updated(TableName, RowId, OldValues, MergedValues))
        )
    ).

%% sql_delete(+TableName, +WhereClause) is det.
%  Delete rows matching WhereClause
%  Example: sql_delete(users, [id-1])
sql_delete(TableName, WhereClause) :-
    current_table_rows(TableName, AllRows),
    include(row_matches(WhereClause), AllRows, MatchingRows),
    forall(
        member(row(RowId, OldValues), MatchingRows),
        emit_event(row_deleted(TableName, RowId, OldValues))
    ).

%% ---------------------------------------------------------------------------
%% Query Operations (CQL-style syntax)
%% ---------------------------------------------------------------------------

%% sql_select(+TableName, ?ColumnBindings) is nondet.
%  Select rows from table. ColumnBindings is [col-Var, ...]
%  Unifies variables with values from matching rows
%  Example: sql_select(users, [id-Id, name-Name])
sql_select(TableName, ColumnBindings) :-
    sql_select(TableName, ColumnBindings, []).

%% sql_select(+TableName, ?ColumnBindings, +WhereClause) is nondet.
%  Select with WHERE clause
%  Example: sql_select(users, [name-Name], [id-1])
sql_select(TableName, ColumnBindings, WhereClause) :-
    current_table_rows(TableName, AllRows),
    member(row(_RowId, Values), AllRows),
    row_matches(WhereClause, row(_RowId, Values)),
    bind_columns(ColumnBindings, Values).

%% Operator syntax for SELECT (CQL-style)
%  users :: [id-Id, name-Name]  equivalent to sql_select(users, [id-Id, name-Name])
:- op(700, xfx, ::).

TableName :: ColumnBindings :-
    sql_select(TableName, ColumnBindings).

%% ---------------------------------------------------------------------------
%% Transaction Support
%% ---------------------------------------------------------------------------

%% begin_transaction is det.
begin_transaction :-
    (   in_transaction
    ->  throw(error(nested_transaction, 'Nested transactions not supported'))
    ;   assertz(in_transaction),
        assertz(transaction([]))
    ).

%% commit_transaction is det.
commit_transaction :-
    (   in_transaction
    ->  retract(transaction(PendingReversed)),
        reverse(PendingReversed, Pending),
        retract(in_transaction),
        forall(member(E, Pending), assertz(E))
    ;   throw(error(no_transaction, 'No active transaction'))
    ).

%% rollback_transaction is det.
rollback_transaction :-
    (   in_transaction
    ->  retract(transaction(_)),
        retract(in_transaction)
    ;   throw(error(no_transaction, 'No active transaction'))
    ).

%% ---------------------------------------------------------------------------
%% State Projection
%%
%% The "current state" is computed by replaying all events.
%% This is the essence of event sourcing: state is derived, not stored.
%% ---------------------------------------------------------------------------

%% current_state(-State) is det.
%  Compute current database state from events
%  State = state(Tables, Rows) where:
%    Tables = [table(name, schema), ...]
%    Rows = [table_rows(name, [row(id, values), ...]), ...]
current_state(state(Tables, RowsByTable)) :-
    get_events(Events),
    foldl(apply_event, Events, state([], []), state(Tables, RowsByTable)).

%% apply_event(+Event, +StateIn, -StateOut) is det.
%  Apply a single event to state
apply_event(event(_, _, EventTerm), StateIn, StateOut) :-
    apply_event_term(EventTerm, StateIn, StateOut).

% DDL events
apply_event_term(table_created(Name, Schema), state(Tables, Rows), state(NewTables, NewRows)) :-
    NewTables = [table(Name, Schema)|Tables],
    NewRows = [table_rows(Name, [])|Rows].

apply_event_term(table_dropped(Name), state(Tables, Rows), state(NewTables, NewRows)) :-
    exclude(is_table(Name), Tables, NewTables),
    exclude(is_table_rows(Name), Rows, NewRows).

% DML events
apply_event_term(row_inserted(Table, RowId, Values), state(Tables, Rows), state(Tables, NewRows)) :-
    update_table_rows(Table, Rows,
        add_row(row(RowId, Values)),
        NewRows).

apply_event_term(row_updated(Table, RowId, _OldValues, NewValues), state(Tables, Rows), state(Tables, NewRows)) :-
    update_table_rows(Table, Rows,
        replace_row(RowId, NewValues),
        NewRows).

apply_event_term(row_deleted(Table, RowId, _OldValues), state(Tables, Rows), state(Tables, NewRows)) :-
    update_table_rows(Table, Rows,
        remove_row(RowId),
        NewRows).

% Transaction events (no-op for state projection - transactions are already applied or rolled back)
apply_event_term(transaction_started(_), State, State).
apply_event_term(transaction_committed(_), State, State).
apply_event_term(transaction_rolled_back(_), State, State).

%% Helper predicates for state projection
is_table(Name, table(Name, _)).
is_table_rows(Name, table_rows(Name, _)).

update_table_rows(Table, Rows, Operation, NewRows) :-
    select(table_rows(Table, TableRows), Rows, RestRows),
    call(Operation, TableRows, UpdatedTableRows),
    NewRows = [table_rows(Table, UpdatedTableRows)|RestRows].

add_row(Row, Rows, [Row|Rows]).

replace_row(RowId, NewValues, Rows, NewRows) :-
    select(row(RowId, _), Rows, RestRows),
    NewRows = [row(RowId, NewValues)|RestRows].

remove_row(RowId, Rows, NewRows) :-
    select(row(RowId, _), Rows, NewRows).

%% ---------------------------------------------------------------------------
%% Convenience Predicates for State Inspection
%% ---------------------------------------------------------------------------

%% table_rows(+TableName, -Rows) is det.
%  Get current rows for a table
table_rows(TableName, Rows) :-
    current_state(state(_, RowsByTable)),
    member(table_rows(TableName, Rows), RowsByTable).

%% current_table_rows(+TableName, -Rows) is det.
%  Internal: get rows for update/delete operations
current_table_rows(TableName, Rows) :-
    (   table_rows(TableName, Rows)
    ->  true
    ;   Rows = []
    ).

%% table_schema(+TableName, -Schema) is det.
%  Get schema for a table
table_schema(TableName, Schema) :-
    current_state(state(Tables, _)),
    member(table(TableName, Schema), Tables).

%% ---------------------------------------------------------------------------
%% Helper Predicates
%% ---------------------------------------------------------------------------

%% generate_row_id(-RowId) is det.
%  Generate a unique row identifier
:- dynamic row_id_counter/1.
row_id_counter(0).

generate_row_id(RowId) :-
    retract(row_id_counter(Current)),
    RowId is Current + 1,
    assertz(row_id_counter(RowId)).

%% row_matches(+Conditions, +Row) is semidet.
%  Check if a row matches WHERE conditions
row_matches([], _).
row_matches([Col-Val|Rest], row(_RowId, Values)) :-
    member(Col-Val, Values),
    row_matches(Rest, row(_RowId, Values)).

%% bind_columns(+ColumnBindings, +Values) is semidet.
%  Bind column variables to row values
bind_columns([], _).
bind_columns([Col-Var|Rest], Values) :-
    member(Col-Var, Values),
    bind_columns(Rest, Values).

%% merge_values(+OldValues, +NewValues, -MergedValues) is det.
%  Merge new values into old (for updates)
merge_values(OldValues, [], OldValues).
merge_values(OldValues, [Col-NewVal|RestNew], MergedValues) :-
    (   select(Col-_, OldValues, TempOld)
    ->  true
    ;   TempOld = OldValues
    ),
    merge_values([Col-NewVal|TempOld], RestNew, MergedValues).

%% ---------------------------------------------------------------------------
%% Debug/Display Utilities
%% ---------------------------------------------------------------------------

%% print_events is det.
%  Print all events in order
print_events :-
    format('~n=== Event Log ===~n', []),
    get_events(Events),
    (   Events = []
    ->  format('  (no events)~n', [])
    ;   forall(member(event(Seq, TS, Term), Events),
            format('  [~w] ~w: ~w~n', [Seq, TS, Term]))
    ),
    format('=================~n', []).

%% print_state is det.
%  Print current database state
print_state :-
    format('~n=== Current State ===~n', []),
    current_state(state(Tables, RowsByTable)),
    (   Tables = []
    ->  format('  (no tables)~n', [])
    ;   forall(member(table(Name, Schema), Tables), (
            format('~nTable: ~w~n', [Name]),
            format('  Schema: ~w~n', [Schema]),
            (   member(table_rows(Name, Rows), RowsByTable)
            ->  format('  Rows:~n', []),
                (   Rows = []
                ->  format('    (empty)~n', [])
                ;   forall(member(row(Id, Values), Rows),
                        format('    [~w] ~w~n', [Id, Values]))
                )
            ;   format('  Rows: (none)~n', [])
            )
        ))
    ),
    format('=====================~n', []).

%% ---------------------------------------------------------------------------
%% Module Initialization
%% ---------------------------------------------------------------------------

:- initialization(clear_events).
