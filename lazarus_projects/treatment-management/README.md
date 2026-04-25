# Treatment Management System

Fat-client / 2-tier client-server treatment management system, written in
FreePascal/Lazarus against PostgreSQL. Architected as if it were designed
in the late 1990s: shared `TDataModule`, data-aware controls, business
logic in form event handlers, no middle tier.

This is the first stage of a three-step modeling exercise:

1. **Lazarus + Postgres** (this project) — the period-correct fat client.
2. **Idiomatic Prolog LTS model** — a DCG over the Postgres WAL event
   stream (the "LDF events" of Postgres, surfaced via logical decoding).
   The grammar *is* the labelled transition system: non-terminals are
   states, productions are transitions, and recognition of a
   `*.wal.jsonl` trace verifies the model accepts the same lifecycle the
   fat client produced. No Logtalk objects — plain Prolog + DCG, in the
   same style as `simulators/clarion/unified/clarion_parser.pl`.
3. **Elixir port** — Commanded + `:eventstore` (Postgres-backed event
   store), reusing the same WAL trace as the seed event log.

## Repository Layout

```
lazarus_projects/treatment-management/
  TreatmentMgmt.lpi              # Lazarus project file
  TreatmentMgmt.lpr              # program entry point
  src/
    uAppConfig.pas               # TIniFile-backed settings
    uDataModule.pas + .lfm       # shared TPQConnection / TSQLTransaction
    forms/
      uMainForm.pas + .lfm       # main menu form
      uPatientForm.pas + .lfm    # patient browse/edit
      uPlanForm.pas + .lfm       # treatment plan browse/edit + Approve
      uAppointmentForm.pas + .lfm# appointment browse/edit + lifecycle
      uSessionForm.pas + .lfm    # session browse/edit + offset magnitude
  config/
    treatment_mgmt.ini.sample    # connection settings template
  db/
    migrations/
      001_initial_schema.sql     # 3NF schema, RowVersion triggers
      002_logical_replication.sql# tm_pub_all publication + REPLICA IDENTITY FULL
    scripts/
      setup_postgres.sh          # one-shot DB + role + migration runner
      capture_wal.py             # streams live WAL events as JSONL
    scenarios/
      01_clinical_workflow.sql   # end-to-end clinical scenario
    traces/
      01_clinical_workflow.wal.jsonl   # pre-recorded WAL fixture (wal2json v2)
```

## Local Postgres Setup

```bash
cd db/scripts
./setup_postgres.sh
```

The script:
1. Sets `wal_level = logical`, `max_wal_senders`, `max_replication_slots`
   in `postgresql.conf` and restarts the service (requires sudo).
2. Creates a `tm_app` role with `LOGIN REPLICATION` and a
   `treatment_mgmt` database.
3. Runs migrations in `db/migrations/` in order.

## Lazarus Build

Open `TreatmentMgmt.lpi` in Lazarus 2.2+ and build (F9). The required
package is `SQLDBLaz`, which ships with Lazarus.

Before first run, copy the INI sample:

```bash
cp config/treatment_mgmt.ini.sample treatment_mgmt.ini
# edit credentials if not using the defaults from setup_postgres.sh
```

The app searches for `treatment_mgmt.ini` in:
1. EXE directory
2. `%APPDATA%\TreatmentMgmt\` (Windows) or `~/.treatment_mgmt.ini` (Unix)

## Schema

Four entities, all under the `tm` schema:

| Table              | Purpose                                          |
|--------------------|--------------------------------------------------|
| Patients           | Patient demographics, MRN, contact info          |
| TreatmentPlans     | Prescription, dose, fractions, approval state    |
| Appointments       | Scheduled visits (consult / sim / treatment)     |
| TreatmentSessions  | Per-fraction delivery, offsets, magnitude        |

Every table has:
- Surrogate `<Table>ID` PK
- `RowVersion` integer bumped by trigger on UPDATE (optimistic concurrency)
- `CreatedAt/By`, `UpdatedAt/By` audit columns
- `CHECK` constraints on enum-valued status fields

See `db/migrations/001_initial_schema.sql` for the full schema.

## WAL Event Capture (for the Prolog port)

PostgreSQL's logical replication is the equivalent of SQL Server's LDF
transaction-log events. With `wal_level=logical` and the `tm_pub_all`
publication, every committed change flows out as a structured event.

### Format

`wal2json` format-version 2: one JSON object per line, with `action`
field B (begin), I (insert), U (update), D (delete), C (commit).

Example INSERT:

```json
{"action":"I","schema":"tm","table":"Patients",
 "columns":[{"name":"PatientID","type":"integer","value":1},
            {"name":"MRN","type":"character varying(20)","value":"MRN0001"},
            ...]}
```

UPDATE events also carry an `identity` array with the old key + changed
columns (because we set `REPLICA IDENTITY FULL` in migration 002).

### Live capture

```bash
# Terminal 1: subscribe
python3 db/scripts/capture_wal.py > my_run.wal.jsonl

# Terminal 2: drive the DB
psql -h localhost -U tm_app -d treatment_mgmt -f db/scenarios/01_clinical_workflow.sql

# Ctrl-C terminal 1; my_run.wal.jsonl now holds the full trace.
```

### Offline fixture

`db/traces/01_clinical_workflow.wal.jsonl` is a pre-recorded reference
trace of the full clinical workflow scenario. The Prolog port consumes
this file directly — no live Postgres needed for model verification.

The scenario covers all four entities and all relevant lifecycle
transitions:

| Txn  | Action                                  | Events |
|------|-----------------------------------------|--------|
| 1001 | Register two patients                   | 2 × I  |
| 1002 | Create treatment plan                   | 1 × I  |
| 1003 | Approve plan                            | 1 × U  |
| 1004 | Schedule 4 appointments                 | 4 × I  |
| 1005 | Check in patient                        | 1 × U  |
| 1006 | Record session 1 (offsets + magnitude)  | 1 × I  |
| 1007 | Complete appointment                    | 1 × U  |
| 1008 | Cancel future appointment               | 1 × U  |
| 1009 | Update demographics                     | 1 × U  |

Total: 31 lines (9 transactions, 8 inserts, 5 updates).

## Lifecycle Transitions (DCG-relevant)

The forms surface explicit lifecycle buttons that the future Prolog DCG
will mirror as productions over WAL events:

| Entity              | Transitions                                                   |
|---------------------|---------------------------------------------------------------|
| TreatmentPlan       | Draft → UnderReview → Approved → Active → Completed           |
|                     | * → Cancelled                                                  |
| Appointment         | Scheduled → CheckedIn → InProgress → Completed                |
|                     | Scheduled → Cancelled / NoShow                                 |
| TreatmentSession    | Pending → InProgress → Completed                              |
|                     | * → Aborted                                                    |

Form code rejects illegal transitions client-side; the Postgres `CHECK`
constraints enforce the value space. Together they constrain the WAL
event stream the DCG will accept.

## Modeling Roadmap

| Stage | Status | Trace Boundary             |
|-------|--------|----------------------------|
| Lazarus fat client (M1: scaffold) | done | n/a (the source of truth) |
| Lazarus fat client (M2: all four forms + lifecycle) | done | n/a |
| Prolog DCG / LTS model | planned | consume `*.wal.jsonl` |
| Elixir port (Commanded + :eventstore) | planned | replay WAL → derive aggregates |

The same WAL trace fixture verifies all three implementations agree on
state evolution — analogous to the CDB-vs-Prolog comparison used for the
Clarion DLLs in this repo.
