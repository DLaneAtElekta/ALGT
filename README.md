# ALGT — Algorithm Logic Verification Tool, Clarion Simulator, and MUZAQ Modernization Demo

A research and engineering platform for **formal analysis of legacy medical device software**, oriented around three threads that share a common foundation in SWI-Prolog and Logtalk:

1. **ALGT** — formal verification of geometric algorithms used in radiation therapy treatment planning, descended from the 2003 Siemens COHERENCE *CRUTPr* procedure.
2. **Clarion Simulator** — a DCG parser and modular execution engine for the Clarion 4GL language used in MOSAIQ, with execution-trace comparison against compiled DLLs.
3. **MUZAQ Modernization Demo** — an end-to-end demonstration of *modernizing* a legacy treatment management system by translating a FreePascal/Lazarus app first to a Prolog **labeled transition system** and then to an Elixir **actor-based** production system, with each Lazarus form becoming an actor and every GUI event and DB command surfacing on an interleavable event stream.

Together these threads support a single regulatory narrative: the [FDA MDDT qualification proposal](docs/FDA_MDDT_Proposal.md) for **ALGT-FMEA**, an automated software FMEA toolset for legacy medical device code.

---

## The MDDT Approach

The repository is organized around an **FDA Medical Device Development Tool** qualification submission for legacy-software FMEA. The full proposal lives in [docs/FDA_MDDT_Proposal.md](docs/FDA_MDDT_Proposal.md); the short version:

- **Problem.** Legacy radiation oncology systems (MOSAIQ in Clarion 4GL, Monaco in C++, and analogous systems in FreePascal/Delphi) carry hundreds of thousands of lines of validated, regulated code that no commercial static analyzer understands. Manual review and black-box testing cannot systematically enumerate failure modes.
- **Method.** Build an *executable semantic model* of the legacy source — a parser plus interpreter — and use it to (a) verify safety-critical algorithms against formal predicates, (b) compare execution traces against the compiled binary at procedure, debugger-breakpoint, and variable level, and (c) drive concurrent-interleaving and probabilistic analyses that no source-level static tool can.
- **Provenance.** The technique is not theoretical. It descends from a production verification of the COHERENCE Dosimetrist Workspace 2.0 in 2003, documented in the [ALGT_CRUTPr](docs/ALGT_CRUTPr.md) procedure. The same Prolog-based pattern — DCGs over clinical data formats, predicate-logic verification conditions, hazard-traceability matrices — is now extended with trace comparison, probabilistic inference, and ML-based anomaly detection.
- **Compositional release.** [docs/compositional-semantics.md](docs/compositional-semantics.md) establishes *bisimilarity* as the formal release criterion: a modernized component is safe to substitute when no external observer — including the database — can distinguish it behaviorally from the original. This is the mathematical backbone of the MUZAQ demo.

---

## The MUZAQ Modernization Demo

**MUZAQ** is a simulated treatment management system used as an open, non-proprietary stand-in for MOSAIQ throughout this repository. It is written in **FreePascal / Lazarus (Delphi-compatible)** with **C/C++ interop** for the numerically intensive parts — mirroring the language mix of the real legacy systems this work targets.

The demo modernizes MUZAQ in two staged translations, each preserving observable behavior in the bisimilarity sense:

```
  ┌──────────────────────────┐    ┌────────────────────────┐    ┌──────────────────────┐
  │ MUZAQ (Lazarus + C/C++)  │ →  │ Prolog LTS            │ →  │ Elixir actor system  │
  │ Forms, TDataSet, events  │    │ States, labels,        │    │ GenServers per form, │
  │ DB calls via SQLdb       │    │ transitions, traces    │    │ event-stream bus     │
  └──────────────────────────┘    └────────────────────────┘    └──────────────────────┘
```

### Stage 1 — Lazarus to Prolog Labeled Transition System

Each Lazarus `TForm` is parsed and projected onto an LTS:

- **States** — the form's persistent fields plus its GUI state (focused control, modal/non-modal, dirty flags).
- **Labels** — observable actions in two families:
  - **GUI events** — `OnClick`, `OnChange`, `OnExit`, inter-form messages, C/C++ FFI calls.
  - **SQL transaction-log entries** — every database command (`Insert`, `Update`, `Delete`, `Post`, `ApplyUpdates`, `Commit`, `Rollback`) is treated as an entry in the *logical transaction log* of the underlying database. The transaction log, not any individual `TDataSet`, is the canonical event stream.
- **Transitions** — derived from the form's event handlers and `TDataSet` lifecycle, with each commit producing a sequence of log entries that any concurrent observer (another form, an MPP report, an integration) can witness.

Multiple forms compose by **interleaving these two label streams** — GUI events from each form, and SQL log entries from the shared database. Because the log is exactly the channel through which forms can observe each other's effects (per the [compositional-semantics](docs/compositional-semantics.md) argument), interleaving log entries is precisely how user interaction across forms is simulated. The existing [model_checker/](model_checker/) explores those interleavings and flags race conditions, mirroring the analyses already used for imaging-pipeline ordering bugs.

### Stage 2 — Prolog LTS to Elixir Actors

The LTS is then realized as a production system:

- Each Lazarus form becomes a **GenServer / `:gen_statem`** whose state machine is the corresponding LTS.
- The SQL transaction log is materialized as a **PubSub / Broadway pipeline** — every committed log entry is a first-class message that any actor can subscribe to. GUI events flow on a parallel topic; the two streams interleave deterministically once both are reified as messages.
- The C/C++ interop layer is preserved through Erlang **NIFs** or **Ports**, keeping the numerical core untouched while the orchestration moves to the BEAM.
- Bisimilarity between the Lazarus original, the Prolog LTS, and the Elixir system is checked by replaying recorded transaction-log + GUI-event traces through all three and diffing the observable label sequences — the same trace-comparison technique already proven against compiled Clarion DLLs (Levels 1, 1b, 1c in [CLAUDE.md](CLAUDE.md)).

The Elixir host already exists in skeleton form under [mcp_servers/elixir/](mcp_servers/elixir/); the FreePascal/Lazarus MUZAQ source and the LTS extractor are the next pieces to land.

---

## Repository Map

```
ALGT/
├── docs/                              # Regulatory narrative + design docs
│   ├── index.md                       # Docs landing page (start here)
│   ├── FDA_MDDT_Proposal.md           # Full MDDT qualification proposal
│   ├── ALGT_CRUTPr.md                 # 2003 COHERENCE CRUTPr (provenance)
│   ├── compositional-semantics.md     # Bisimilarity & independent release
│   └── ontology/                      # Clinical & DICOM OWL/TTL ontologies
│
├── algt_tests/                        # CRUTPr-descended algorithm verification
│   ├── ALGT_BEAM_VOLUME.pl / _PLANAR  # Radiation beam volume
│   ├── ALGT_BEAM_CAX_ISOCENTER.pl     # Central-axis / isocenter
│   ├── ALGT_MESH_GEN.pl               # 3D mesh from contours
│   ├── ALGT_MESH_PLANE_INTERSECTION   # Mesh ∩ plane
│   ├── ALGT_MARGIN2D / _MARGIN3D      # Structure margin expansion
│   ├── ALGT_ISODENSITY.pl             # Isodose extraction
│   ├── ALGT_STRUCT_PROJ.pl            # Beam's-eye-view projection
│   └── ALGT_SSD.pl                    # Source-to-surface distance
│
├── domain_models/                     # Logtalk domain models
│   ├── imaging_services/              # Image import manager + protocols
│   ├── subject_image_domain_model/
│   ├── treatment_image_domain_model/
│   └── appointment_domain_model/
│
├── model_checker/                     # Concurrent-interleaving verifier
│
├── simulators/
│   ├── clarion/unified/               # Clarion 4GL parser + execution engine
│   ├── pascal/unified/                # Object Pascal / Lazarus parser + interpreter (MUZAQ)
│   ├── c34gl/                         #   - C3/4GL variant (prolog + web)
│   ├── llvm/unified/                  # LLVM IR simulator (Pascal/RADAR target)
│   ├── fsharp/unified/                # F# simulator
│   └── common/                        # Shared simulator utilities
│
├── pascal_samples/                    # Pascal/Lazarus sample corpus
│   ├── modern-lazarus/                #   - HelloMUZAQ.{pas,lfm} round-trip target
│   └── legacy/                        #   - ~404 TP / Modula-2 files (1985–1995)
│
├── clarion_projects/                  # Real Clarion DLL/EXE test cases
│   ├── hello-world, python-dll        #   - Smoke tests + Python ctypes interop
│   ├── diagnosis-store, sensor-data   #   - Flat-file CRUD + trace comparison
│   ├── stats-calc, odbc-store         #   - Computation + SQL Server LocalDB
│   ├── form-demo, form-cli            #   - GUI + EventReader CLI variant
│   ├── treatment-offset               #   - Direction sign-flip + ISqrt magnitude
│   ├── struct-demo, html_gen_demo     #   - Struct marshalling + HTML rendering
│   ├── qualified-names, mandelbrot    #   - Language features + numeric demo
│   ├── automata                       #   - State-machine examples
│   ├── brimstone-{dose,kernel,optim}  #   - Dose-calc port targets
│   ├── dh-{graph,mtl,rtmodel,volume}  #   - dH RT-planning library port targets
│   ├── penbeam-{edit,edit-simple,indens}  # Pen-beam editor ports
│   ├── quickdraw-{3d,grafutil,types}  #   - QuickDraw graphics ports
│   ├── radar-{modem,picdb,term}       #   - RADAR Pascal ports
│   ├── ssm-fuel                       #   - SSM Pascal port
│   └── clarion_examples/              #   - Reference .clw syntax samples
│
├── fsharp_projects/                   # F# verification & domain demos
│   ├── fsharp_domain_demo
│   ├── fsharp_features
│   ├── fsharp_fuel_inventory
│   ├── fsharp_hello_world
│   └── fsharp_logic_lib
│
├── mcp_servers/                       # Model Context Protocol servers
│   ├── prolog/                        #   - SWI-Prolog MCP server
│   ├── erlang/                        #   - Erlang MCP server
│   ├── elixir/                        #   - Elixir MCP server (MUZAQ host)
│   └── python_dll/                    #   - Python wrapper for Clarion DLLs
│
├── algt-devenv.dsc.yaml               # DSC v3 dev-environment spec
├── check_devenv.sh                    # Manual env check
├── CLAUDE.md / GEMINI.md              # AI assistant guidance
└── LICENSE                            # BSD 2-Clause
```

---

## Requirements

- **SWI-Prolog** 8.0+ ([swi-prolog.org](https://www.swi-prolog.org/))
- **Logtalk** ([logtalk.org](https://logtalk.org/)) — for the object-oriented domain models and storage/UI dispatchers
- **DSC v3** — run `dsc config test --file algt-devenv.dsc.yaml` at session start to verify tooling

### Optional, by thread

| Thread | Tooling |
|---|---|
| Clarion DLL trace comparison | Clarion 11.1; 32-bit Python 3.11; CDB (x86) from Windows SDK Debugging Tools |
| F# components | .NET SDK 8+ |
| LLVM simulator (Pascal target) | LLVM toolchain |
| MUZAQ modernization demo | FreePascal/Lazarus 3.x; Erlang/OTP 26+; Elixir 1.16+ |

---

## Quick Start

### Verify the environment
```bash
dsc config test --file algt-devenv.dsc.yaml
```

### Clarion simulator
```bash
cd simulators/clarion/unified
swipl -g "main,halt" -t "halt(1)" test_unified.pl
```

### ALGT algorithm verification
```bash
swipl -s algt_tests/ALGT_BEAM_VOLUME.pl
```

### Model checker (interleaving analysis)
```prolog
swipl -s model_checker/model_checker.pl
?- valid(sequence([capture_image -> img1, update_contour -> img1])).
```

### Sensor-data trace comparison (Prolog vs compiled DLL)
```bash
cd clarion_projects/sensor-data
python compare_cdb_prolog.py
```

---

## Key Concepts

- **Execution-trace comparison** — Prolog interpreter output is diffed against (a) Python-wrapped DLL calls, (b) CDB hardware breakpoints on DLL exports, and (c) variable-level get/set traces from headless DLLs. Detailed in [CLAUDE.md](CLAUDE.md).
- **Pluggable storage and UI** — the Clarion simulator dispatches file I/O and UI events through Logtalk protocols (`storage_protocol.lgt`, `ui_protocol.lgt`), so the same program can run against in-memory, CSV, ODBC, or simulated-GUI backends.
- **Scenario DSL** — `scenario_dsl.pl` describes UI test flows; `scenario_ahk.pl` compiles them to AutoHotkey scripts that drive the real compiled application.
- **Bisimilarity as release criterion** — the modernization story (Clarion → Prolog, Lazarus → Prolog → Elixir) treats observable-trace equivalence as the proof of behavior-preserving substitution. See [docs/compositional-semantics.md](docs/compositional-semantics.md).

---

## Development

See [CLAUDE.md](CLAUDE.md) for build conventions (Clarion DLL exports, MSBuild invocation, 32-bit Python interop), trace-comparison pipelines, and assistant-specific guidance.

The parent directory's [d:/MUSIQ/CLAUDE.md](../CLAUDE.md) covers the surrounding MOSAIQ/Equator/Monaco context that motivates this work.

## License

Copyright (c) 2015, dg1an3. Licensed under the BSD 2-Clause License — see [LICENSE](LICENSE).

## Contributing

Contributions welcome. Given the medical-device focus, all changes should preserve test coverage and avoid weakening assertions without an explicit safety rationale.
