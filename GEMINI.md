# GEMINI.md

This file provides context for Gemini Code when working on this project.

## Project Overview

This project uses Prolog to parse, analyze, and execute Clarion programs. Clarion is a 4GL (fourth-generation language) used primarily for database application development. It also includes formal verification of medical imaging algorithms (ALGT).

## Development Environment Check

This project uses a DSC v3 configuration (`algt-devenv.dsc.yaml`) to define the required development environment. **On every session start**, run the check script to verify the environment is correct:

```bash
bash check_devenv.sh
```

Review the output for any resources not in desired state and inform the user of missing or misconfigured tools before proceeding with other work.

## Technology Stack

- **Prolog**: Primary implementation language (targeting SWI-Prolog)
- **Logtalk**: Object-oriented Prolog extension (domain models)
- **Clarion 11.1**: The language being analyzed (compiles to 32-bit Windows DLLs/EXEs)
- **Python 3.11 (32-bit)**: ctypes interop with Clarion DLLs

## Key Concepts

### Clarion Language Basics

Clarion programs consist of:
- **Program files** (.clw) - Main source files
- **Include files** (.inc) - Header/interface files
- **Dictionary files** (.dct) - Database schema definitions

Clarion uses a structured syntax with:
- `PROGRAM`, `MAP`, `CODE` sections
- `PROCEDURE` definitions
- Data declarations with types like `STRING`, `LONG`, `SHORT`, `DECIMAL`
- Control structures: `IF`, `LOOP`, `CASE`
- Embedded SQL for database access

### Prolog Analysis Approach

The unified simulator represents Clarion code as Prolog facts and rules:
- Source code is parsed via DCG into an AST represented as Prolog terms
- An execution engine interprets the AST with pluggable storage and UI backends
- Execution traces can be compared against compiled Clarion DLL behavior

## Repository Structure

```
├── clarion_projects/              # Compiled Clarion projects
│   ├── hello-world/               # Simple PROGRAM exe
│   ├── python-dll/                # DLL with exported functions (Python ctypes)
│   ├── diagnosis-store/           # DOS flat-file CRUD DLL
│   ├── sensor-data/               # Sensor readings DLL, trace comparison
│   ├── stats-calc/                # Statistical calculations DLL
│   ├── odbc-store/                # ODBC DLL with SQL Server LocalDB
│   ├── clarion_examples/          # Reference .clw files
│   ├── form-demo/                 # GUI form + FormLib DLL for CDB tracing
│   ├── form-cli/                  # CLI form with EventReader, .evt format
│   └── treatment-offset/          # Treatment offset entry with sign-flip
├── simulators/clarion/            # Prolog Clarion simulator
│   └── unified/                   # DCG parser + execution engine (104 tests)
│       ├── clarion.pl             # Public API
│       ├── clarion_parser.pl      # DCG parser
│       ├── ast_bridge.pl          # AST transformation
│       ├── simulator.pl           # Core execution engine
│       ├── simulator_builtins.pl  # Built-in functions
│       ├── simulator_eval.pl      # Expression evaluation
│       ├── simulator_control.pl   # Control flow
│       ├── simulator_state.pl     # State management
│       ├── simulator_classes.pl   # Class support
│       ├── execution_tracer.pl    # ML exports (PGM, PyMC, Stan, GNN-VAE)
│       ├── scenario_dsl.pl        # Scenario DSL
│       ├── scenario_ahk.pl        # AutoHotkey generation
│       ├── storage_backend.pl     # Pluggable storage dispatch
│       ├── storage_memory.pl      # In-memory storage
│       ├── storage_csv.pl         # CSV file storage
│       ├── storage_odbc.pl        # ODBC storage
│       ├── ui_backend.pl          # UI backend abstraction
│       ├── ui_simulation.pl       # UI simulation
│       ├── web_server.pl          # Web server interface
│       └── test_unified.pl        # Test suite
├── algt_tests/                    # Algorithm verification test suite
├── domain_models/                 # Logtalk domain models & workflows
│   ├── imaging_services/          # Image import manager, contracts
│   ├── subject_image_domain_model/
│   ├── treatment_image_domain_model/
│   └── appointment_domain_model/
├── model_checker/                 # Concurrent operation verification
├── mcp_servers/                   # MCP server implementations
│   ├── prolog/                    # MCP server (Prolog)
│   ├── erlang/                    # MCP server (Erlang)
│   └── elixir/                    # MCP server (Elixir)
└── docs/
```

## Architecture

### Unified Clarion Simulator (`simulators/clarion/unified/`)

A single modular simulator (21 Prolog files, 104 tests) that combines parsing and execution:

#### Parser (`clarion_parser.pl`)
Parses Clarion source files into an AST using DCG (Definite Clause Grammars).

#### AST Bridge (`ast_bridge.pl`)
Transforms parsed structures into a normalized AST for the execution engine.

#### Execution Engine (`simulator.pl` + modules)
Executes Clarion programs from their AST representation.

**Supported features:**
- Variables (local, global, prefixed file fields like `Cust:CustomerID`)
- Expressions (arithmetic, comparison, logical, string concatenation)
- Control flow: `IF/ELSIF/ELSE`, `LOOP` (infinite, TO, WHILE, UNTIL), `CASE/OF`, `BREAK`, `CYCLE`
- Procedures with parameters and local variables
- Routines (`DO`/`ROUTINE` with `EXIT`)
- Class support
- File I/O with pluggable storage backends:
  - In-memory (`storage_memory.pl`)
  - CSV files (`storage_csv.pl`)
  - ODBC/SQL (`storage_odbc.pl`)
- Built-in functions: `MESSAGE`, `CLIP`, `LEN`, `CHR`, `VAL`, `TODAY`, `CLOCK`
- UI simulation with pluggable backends
- Scenario-based testing with AutoHotkey generation
- Execution tracer with ML model exports (PGM, PyMC, Stan, GNN-VAE)

## Running Programs

```bash
cd simulators/clarion/unified
swipl
?- use_module(clarion).
?- init_session(Source, Session), call_procedure(Session, 'MyProc', Result).
```

## Running Tests

```bash
# Unified simulator tests (104 tests)
cd simulators/clarion/unified
swipl -g "main,halt" -t "halt(1)" test_unified.pl

# ALGT verification tests
swipl -s algt_tests/ALGT_BEAM_VOLUME.pl
```

## Development Guidelines

- Use descriptive predicate names following Prolog conventions (lowercase, underscores)
- Document predicates with comments explaining their purpose
- Keep facts and rules modular for easy testing
- Use DCG (Definite Clause Grammars) for parsing when appropriate

## File Naming Conventions

- `.pl` - Prolog source files
- `.clw` - Clarion source files (input for analysis)
- `.inc` - Clarion include files
- `.lgt` - Logtalk source files

## Common Tasks

### Adding a new analysis rule

1. Define the pattern to match as a Prolog predicate
2. Add test cases in the test suite
3. Document the rule's purpose and usage

### Parsing new Clarion constructs

1. Extend the DCG grammar in `clarion_parser.pl`
2. Add AST bridge transformations in `ast_bridge.pl`
3. Add execution support in the appropriate simulator module
4. Add tests in `test_unified.pl`
