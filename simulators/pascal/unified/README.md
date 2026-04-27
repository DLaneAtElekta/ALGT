# Pascal / Lazarus Simulator (unified)

A SWI-Prolog simulator for the Object Pascal subset used by Lazarus / FreePascal
form modules. Built as the source-level analogue of
[`simulators/clarion/unified/`](../../clarion/unified/) for the **MUZAQ
modernization demo** (see [`/docs/index.md`](../../../docs/index.md)).

The point of this simulator is *not* to replace FPC. It is to project a
Lazarus form module onto a labeled transition system whose labels are
**GUI events** and **SQL transaction-log entries**, so that the same program
can be (a) executed in Prolog as an LTS, (b) re-targeted to Elixir actors,
and (c) checked for bisimilarity against the compiled Lazarus binary by
trace comparison.

## Module layout

| File | Purpose |
|---|---|
| `pascal_parser.pl`  | DCG parser for the Object Pascal subset (units, classes, methods, statements, expressions). Strips `//`, `{ }`, and `(* *)` comments; preserves string literals. |
| `lfm_parser.pl`     | DCG parser for Lazarus `.lfm` form resource files. Produces `form(Name, Class, Properties, Children)` trees. |
| `ast_bridge.pl`     | Joins a parsed unit and its forms into a `module(...)` AST: classes get their methods attached, forms become first-class objects, datasets become children. |
| `simulator_state.pl`| Threaded state dict — vars, globals, classes, forms, objects, SQL log, UI event queue, control flag, captured output. |
| `simulator_eval.pl` | Expression evaluator. Returns symbolic terms when operands are not concrete numbers, useful for partial evaluation. |
| `storage_backend.pl`| Emits SQL transaction-log entries on every recognised `TDataSet`/`TSQLQuery` operation. |
| `ui_backend.pl`     | Stub UI backend — records GUI events on the captured-output stream. |
| `simulator.pl`      | Core interpreter. Loads the module AST, registers forms/objects, fires events, dispatches statements, routes recognised DB ops through `storage_backend`. |
| `pascal.pl`         | Public API: `load_unit/3`, `fire_event/3`, `invoke_method/5`, `sql_log/2`, `output_lines/2`. |
| `../../../pascal_samples/` | Sample corpus at repo root: `modern-lazarus/HelloMUZAQ.{pas,lfm}` is the round-trip target; `legacy/` holds ~404 Turbo Pascal / Modula-2 source files (1985–1995) as reference material. |
| `test_unified.pl`   | Smoke test. Verifies parse → load → fire OnClick → expected SQL log. |

## Scope

In scope (FPC `{$mode objfpc}` subset, sufficient for one or several
form modules):

- Units: `unit / interface / implementation / initialization / uses`.
- Classes: `class(Parent) ... end`, fields, methods, properties, visibility.
- Methods bound by `procedure TForm.Foo(...)` plus standalone `procedure / function`.
- Statements: `begin/end`, `if/then/else`, `while/do`, `for/to/downto/do`,
  `repeat/until`, `case/of`, `with/do`, `try/except/finally`,
  `break / continue / exit`.
- Expressions: integer/float/string literals, `nil`, `true`/`false`,
  `+ - * / div mod`, `= <> < > <= >=`, `and or not xor`,
  member access (`.`), method calls, indexing.
- L-values that include calls in the chain (`Foo.FieldByName('x').AsString := ...`).
- TDataSet / TSQLQuery operations recognised as SQL-log labels:
  `Open, Close, Insert, Edit, FieldByName(...).AsX :=, Post, Delete,
  ApplyUpdates, StartTransaction, Commit, CommitRetaining, Rollback, ExecSQL`.
- Lazarus `.lfm` form files including nested controls, `OnClick` and similar
  event-handler bindings, qualified property names (e.g. `SQL.Strings`),
  `(...)` tuples, and `('a' 'b')` string lists.

Out of scope (intentional — extend as needed):

- Generics (`generic / specialize`).
- Anonymous methods, advanced RTTI.
- Inline assembler.
- Operator overloading.
- Variant records beyond simple cases.

## Quick test

```bash
cd simulators/pascal/unified
swipl test_unified.pl
```

Expected output:

```
ok  parse_pascal
ok  parse_lfm
ok  load_module
ok  fire_click
ALL TESTS PASSED
```

The `fire_click` test loads `../../../pascal_samples/modern-lazarus/HelloMUZAQ.{pas,lfm}`, fires
`click('MainForm', 'Button1')`, and asserts that the SQL transaction log
contains `[insert, set_field, set_field, post, apply_updates]` — exactly
the labels that any concurrent observer of the database would see.

## Programmatic use

```prolog
:- use_module(pascal).

?- pascal:load_unit('../../../pascal_samples/modern-lazarus/HelloMUZAQ.pas',
                    ['../../../pascal_samples/modern-lazarus/HelloMUZAQ.lfm'], S0).

?- pascal:fire_event(open('MainForm'),               S0, S1),
   pascal:fire_event(click('MainForm', 'Button1'),   S1, S2),
   pascal:sql_log(S2, Entries).
Entries = [
  log(1, 'MainForm', open,          'MyDataSet', [sql='']),
  log(2, 'MainForm', insert,        'MyDataSet', []),
  log(3, 'MainForm', set_field,     'MyDataSet', [field='PatientID', value=str('P001')]),
  log(4, 'MainForm', set_field,     'MyDataSet', [field='Name',      value=str('Smith')]),
  log(5, 'MainForm', post,          'MyDataSet', []),
  log(6, 'MainForm', apply_updates, 'MyDataSet', [])
].
```

The `Form` field of each entry is the form whose handler emitted the
operation — the canonical attribution needed for interleaving across
multiple forms.

## Next steps

- Stage 2 of the MUZAQ demo: code-gen each form's transitions to an
  Elixir `:gen_statem`. The SQL log entries become messages on a Broadway
  pipeline; GUI events become messages on a parallel topic.
- Trace comparison against the FPC-compiled Lazarus binary (CDB on Windows
  or `gdb`/`lldb` on Linux/macOS), mirroring the Level 1b technique used
  for compiled Clarion DLLs.
- Extend the parser as real MUZAQ forms require it; everything in the
  "out of scope" list is mechanical to add.
