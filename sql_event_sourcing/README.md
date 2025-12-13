# SQL Event Sourcing Engine

This module demonstrates how a SQL database is fundamentally an event sourcing system.

## Core Insight

Every SQL operation is an event:
- `INSERT` → `row_inserted(Table, RowId, Values)`
- `UPDATE` → `row_updated(Table, RowId, OldValues, NewValues)`
- `DELETE` → `row_deleted(Table, RowId, OldValues)`
- `CREATE TABLE` → `table_created(Name, Schema)`

The current state is always derived by replaying all events. Traditional databases optimize this with snapshots and indexes, but the fundamental model is event sourcing.

## Usage

```prolog
?- use_module(sql_event_sourcing/sql_es).

% Create a table (emits table_created event)
?- create_table(users, [col(id, integer), col(name, varchar)]).

% Insert rows (emits row_inserted events)
?- sql_insert(users, [id-1, name-'Alice']).
?- sql_insert(users, [id-2, name-'Bob']).

% Query using CQL-style syntax
?- users :: [id-Id, name-Name].
Id = 1, Name = 'Alice' ;
Id = 2, Name = 'Bob'.

% Update (emits row_updated event with old/new values)
?- sql_update(users, [name-'Robert'], [id-2]).

% Delete (emits row_deleted event preserving old values)
?- sql_delete(users, [id-1]).

% View complete event log
?- print_events.

% View current state (derived from events)
?- print_state.
```

## CQL-Style Term Format

Following [SWI-Prolog's CQL](https://www.swi-prolog.org/pldoc/man?section=cql):

| Operation | Syntax |
|-----------|--------|
| SELECT | `table :: [col-Var, ...]` |
| SELECT with WHERE | `sql_select(table, [col-Var], [where_col-val])` |
| INSERT | `sql_insert(table, [col-val, ...])` |
| UPDATE | `sql_update(table, [col-newval], [where_col-val])` |
| DELETE | `sql_delete(table, [pk_col-val])` |

## Transaction Support

```prolog
?- begin_transaction.
?- sql_insert(orders, [id-1, total-100]).
?- sql_update(inventory, [qty-99], [id-5]).
?- commit_transaction.   % or rollback_transaction
```

## Event Sourcing Benefits

1. **Complete Audit Trail**: Every change is recorded with timestamps
2. **Time Travel**: Reconstruct state at any point by replaying events up to that time
3. **Debugging**: See exactly what happened and when
4. **Undo/Redo**: Events contain enough info to reverse operations

## Running the Demo

```bash
swipl -s sql_event_sourcing/sql_es_demo.pl -g run_demo
```

## Running Tests

```bash
swipl -s sql_event_sourcing/sql_es_demo.pl -g run_tests_sql -g halt
```

## Files

- `sql_es.pl` - Core event sourcing SQL engine
- `sql_es_demo.pl` - Demonstrations and unit tests
