/*
    SQL Event Sourcing Demonstration

    This file demonstrates how a SQL database is fundamentally an event
    sourcing system. Each operation produces an event, and the current
    state is always derivable by replaying all events.

    Run with: swipl -s sql_es_demo.pl -g run_demo
*/

:- use_module(sql_es).

%% ---------------------------------------------------------------------------
%% Demo 1: Basic CRUD Operations as Events
%% ---------------------------------------------------------------------------

demo_basic_crud :-
    format('~n=== Demo 1: Basic CRUD Operations as Events ===~n', []),

    % Clear any previous state
    clear_events,

    % CREATE TABLE - This emits a table_created event
    format('~n1. Creating users table...~n', []),
    create_table(users, [col(id, integer), col(name, varchar), col(email, varchar)]),

    % INSERT - Each insert emits a row_inserted event
    format('2. Inserting rows...~n', []),
    sql_insert(users, [id-1, name-'Alice', email-'alice@example.com']),
    sql_insert(users, [id-2, name-'Bob', email-'bob@example.com']),
    sql_insert(users, [id-3, name-'Charlie', email-'charlie@example.com']),

    % Show the event log
    format('~nEvent log after inserts:~n', []),
    print_events,

    % Show derived state
    format('~nDerived state (by replaying events):~n', []),
    print_state,

    % UPDATE - Emits row_updated event with old and new values
    format('~n3. Updating Bob\\'s email...~n', []),
    sql_update(users, [email-'robert@example.com'], [id-2]),

    % DELETE - Emits row_deleted event with old values (for undo)
    format('4. Deleting Charlie...~n', []),
    sql_delete(users, [id-3]),

    % Final event log
    format('~nFinal event log:~n', []),
    print_events,

    % Final state
    format('~nFinal state:~n', []),
    print_state.

%% ---------------------------------------------------------------------------
%% Demo 2: CQL-Style Query Syntax
%% ---------------------------------------------------------------------------

demo_query_syntax :-
    format('~n=== Demo 2: CQL-Style Query Syntax ===~n', []),

    clear_events,

    % Setup data
    create_table(products, [col(id, integer), col(name, varchar), col(price, decimal)]),
    sql_insert(products, [id-1, name-'Widget', price-9.99]),
    sql_insert(products, [id-2, name-'Gadget', price-19.99]),
    sql_insert(products, [id-3, name-'Gizmo', price-29.99]),

    % SELECT using :: operator (CQL style)
    format('~nQuerying with CQL-style syntax:~n', []),
    format('  products :: [id-Id, name-Name, price-Price]~n', []),
    format('~nResults:~n', []),
    forall(
        products :: [id-Id, name-Name, price-Price],
        format('  id=~w, name=~w, price=~w~n', [Id, Name, Price])
    ),

    % SELECT with WHERE clause
    format('~nQuerying with WHERE clause:~n', []),
    format('  sql_select(products, [name-Name], [id-2])~n', []),
    (   sql_select(products, [name-Name], [id-2])
    ->  format('  Result: name=~w~n', [Name])
    ;   format('  No results~n', [])
    ).

%% ---------------------------------------------------------------------------
%% Demo 3: Event Sourcing Benefits - Time Travel
%% ---------------------------------------------------------------------------

demo_time_travel :-
    format('~n=== Demo 3: Event Sourcing Benefits - Time Travel ===~n', []),

    clear_events,

    create_table(accounts, [col(id, integer), col(owner, varchar), col(balance, decimal)]),
    sql_insert(accounts, [id-1, owner-'Alice', balance-1000]),

    format('~nInitial balance: $1000~n', []),

    % Simulate transactions
    sql_update(accounts, [balance-800], [id-1]),
    format('After withdrawal: $800~n', []),

    sql_update(accounts, [balance-1050], [id-1]),
    format('After deposit: $1050~n', []),

    sql_update(accounts, [balance-950], [id-1]),
    format('After purchase: $950~n', []),

    % Show complete history
    format('~n--- Complete Event History ---~n', []),
    get_events(Events),
    forall(member(event(Seq, _, Term), Events), (
        format('[~w] ', [Seq]),
        describe_event(Term)
    )),

    % Show we can reconstruct state at any point
    format('~n--- State Reconstruction ---~n', []),
    format('The current state ($950) can always be derived by replaying~n', []),
    format('all events from the beginning. We never lose history!~n', []),
    print_state.

describe_event(table_created(Name, _)) :-
    format('Table ~w created~n', [Name]).
describe_event(row_inserted(Table, Id, Values)) :-
    member(balance-Bal, Values),
    format('~w[~w]: Initial balance = $~w~n', [Table, Id, Bal]).
describe_event(row_updated(Table, Id, Old, New)) :-
    member(balance-OldBal, Old),
    member(balance-NewBal, New),
    Diff is NewBal - OldBal,
    (   Diff >= 0
    ->  format('~w[~w]: Balance +$~w ($~w -> $~w)~n', [Table, Id, Diff, OldBal, NewBal])
    ;   AbsDiff is abs(Diff),
        format('~w[~w]: Balance -$~w ($~w -> $~w)~n', [Table, Id, AbsDiff, OldBal, NewBal])
    ).
describe_event(Term) :-
    format('Event: ~w~n', [Term]).

%% ---------------------------------------------------------------------------
%% Demo 4: Transaction Support with Rollback
%% ---------------------------------------------------------------------------

demo_transactions :-
    format('~n=== Demo 4: Transaction Support with Rollback ===~n', []),

    clear_events,

    create_table(orders, [col(id, integer), col(item, varchar), col(qty, integer)]),
    sql_insert(orders, [id-1, item-'Book', qty-2]),

    format('~nInitial state:~n', []),
    print_state,

    % Start transaction
    format('~nStarting transaction...~n', []),
    begin_transaction,

    % Make changes within transaction
    sql_insert(orders, [id-2, item-'Pen', qty-10]),
    sql_update(orders, [qty-5], [id-1]),

    format('~nState during transaction (not yet committed):~n', []),
    format('(Changes are pending - not visible in main event store)~n', []),

    % Rollback!
    format('~nRolling back transaction...~n', []),
    rollback_transaction,

    format('~nState after rollback (unchanged):~n', []),
    print_state,

    % Now do a successful transaction
    format('~nStarting new transaction...~n', []),
    begin_transaction,
    sql_insert(orders, [id-3, item-'Notebook', qty-3]),
    format('Committing transaction...~n', []),
    commit_transaction,

    format('~nState after commit:~n', []),
    print_state.

%% ---------------------------------------------------------------------------
%% Demo 5: Multiple Tables with Relationships
%% ---------------------------------------------------------------------------

demo_relationships :-
    format('~n=== Demo 5: Multiple Tables (Simulated Join) ===~n', []),

    clear_events,

    % Create tables
    create_table(customers, [col(id, integer), col(name, varchar)]),
    create_table(orders, [col(id, integer), col(customer_id, integer), col(product, varchar)]),

    % Insert data
    sql_insert(customers, [id-1, name-'Alice']),
    sql_insert(customers, [id-2, name-'Bob']),

    sql_insert(orders, [id-101, customer_id-1, product-'Widget']),
    sql_insert(orders, [id-102, customer_id-1, product-'Gadget']),
    sql_insert(orders, [id-103, customer_id-2, product-'Gizmo']),

    format('~nSimulated JOIN: Find customer names with their orders~n', []),
    format('~nQuery: customers JOIN orders ON customers.id = orders.customer_id~n', []),
    format('~nResults:~n', []),

    forall((
        customers :: [id-CustId, name-CustName],
        orders :: [customer_id-CustId, product-Product]
    ), format('  ~w ordered: ~w~n', [CustName, Product])).

%% ---------------------------------------------------------------------------
%% Demo 6: Event Replay for Audit
%% ---------------------------------------------------------------------------

demo_audit :-
    format('~n=== Demo 6: Event Replay for Audit Trail ===~n', []),

    clear_events,

    create_table(sensitive_data, [col(id, integer), col(ssn, varchar), col(accessed_by, varchar)]),

    % Simulate access log through events
    sql_insert(sensitive_data, [id-1, ssn-'XXX-XX-1234', accessed_by-'system']),
    sql_update(sensitive_data, [accessed_by-'alice'], [id-1]),
    sql_update(sensitive_data, [accessed_by-'bob'], [id-1]),
    sql_update(sensitive_data, [accessed_by-'alice'], [id-1]),

    format('~nFull audit trail from events:~n', []),
    get_events(Events),
    forall(member(event(_, Timestamp, Term), Events), (
        (   Term = row_updated(_, _, Old, New)
        ->  member(accessed_by-OldBy, Old),
            member(accessed_by-NewBy, New),
            format_time(string(TimeStr), '%Y-%m-%d %H:%M:%S', Timestamp),
            format('  [~w] Access changed: ~w -> ~w~n', [TimeStr, OldBy, NewBy])
        ;   true
        )
    )),

    format('~nThis complete audit trail is impossible to achieve with~n', []),
    format('mutable state - but trivial with event sourcing!~n', []).

%% ---------------------------------------------------------------------------
%% Run All Demos
%% ---------------------------------------------------------------------------

run_demo :-
    format('~n****************************************~n', []),
    format('* SQL as Event Sourcing Demonstration  *~n', []),
    format('****************************************~n', []),
    format('~nThis demonstration shows how every SQL database is~n', []),
    format('fundamentally an event sourcing system. The current~n', []),
    format('state is merely a projection of all past events.~n', []),

    demo_basic_crud,
    demo_query_syntax,
    demo_time_travel,
    demo_transactions,
    demo_relationships,
    demo_audit,

    format('~n****************************************~n', []),
    format('* End of Demonstration                 *~n', []),
    format('****************************************~n~n', []).

%% ---------------------------------------------------------------------------
%% Unit Tests
%% ---------------------------------------------------------------------------

:- use_module(library(plunit)).

:- begin_tests(sql_es).

test(create_table) :-
    clear_events,
    create_table(test_table, [col(id, integer)]),
    table_schema(test_table, Schema),
    Schema = [col(id, integer)].

test(insert_and_select) :-
    clear_events,
    create_table(t, [col(x, integer)]),
    sql_insert(t, [x-42]),
    sql_select(t, [x-X]),
    X = 42.

test(update) :-
    clear_events,
    create_table(t, [col(id, integer), col(val, varchar)]),
    sql_insert(t, [id-1, val-'old']),
    sql_update(t, [val-'new'], [id-1]),
    sql_select(t, [val-V], [id-1]),
    V = 'new'.

test(delete) :-
    clear_events,
    create_table(t, [col(id, integer)]),
    sql_insert(t, [id-1]),
    sql_insert(t, [id-2]),
    sql_delete(t, [id-1]),
    findall(X, sql_select(t, [id-X]), Xs),
    Xs = [2].

test(transaction_commit) :-
    clear_events,
    create_table(t, [col(x, integer)]),
    begin_transaction,
    sql_insert(t, [x-100]),
    commit_transaction,
    sql_select(t, [x-X]),
    X = 100.

test(transaction_rollback) :-
    clear_events,
    create_table(t, [col(x, integer)]),
    sql_insert(t, [x-1]),
    begin_transaction,
    sql_insert(t, [x-2]),
    rollback_transaction,
    findall(X, sql_select(t, [x-X]), Xs),
    Xs = [1].

test(cql_syntax) :-
    clear_events,
    create_table(items, [col(name, varchar)]),
    sql_insert(items, [name-'test']),
    items :: [name-N],
    N = 'test'.

test(event_count) :-
    clear_events,
    create_table(t, [col(x, integer)]),
    sql_insert(t, [x-1]),
    sql_insert(t, [x-2]),
    sql_update(t, [x-10], [x-1]),
    get_events(Events),
    length(Events, 4).  % 1 create + 2 inserts + 1 update

:- end_tests(sql_es).

%% Run tests
run_tests_sql :-
    run_tests(sql_es).
