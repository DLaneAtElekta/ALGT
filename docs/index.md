# ALGT Documentation

This folder collects the design documents, regulatory narrative, and conceptual background for the ALGT platform. The repository code lives one level up — see the root [README.md](../README.md) for the full repository map and quick-start commands.

The three documents below build a single argument: that legacy medical device software can be modernized safely if the modernization preserves observable behavior in a formal, checkable sense, and that this approach is mature enough to be qualified as an FDA Medical Device Development Tool.

---

## What this repository is

ALGT braids three threads:

1. **Algorithm verification** — formal proofs that geometric routines used in radiation therapy treatment planning meet hazard-traceable specifications. The test suites in [../algt_tests/](../algt_tests/) descend directly from the 2003 Siemens COHERENCE *CRUTPr* procedure documented here in [ALGT_CRUTPr.md](ALGT_CRUTPr.md).
2. **Legacy-language simulation** — DCG parsers and modular execution engines for Clarion 4GL ([../simulators/clarion/unified/](../simulators/clarion/unified/)), an LLVM IR target for Pascal ([../simulators/llvm/](../simulators/llvm/)), and an F# variant ([../simulators/fsharp/](../simulators/fsharp/)). Each simulator can be checked against the compiled binary by execution-trace comparison.
3. **Modernization demonstration** — the **MUZAQ** treatment management system, written in FreePascal/Lazarus with C/C++ interop, modernized to a Prolog **labeled transition system** and then to an **Elixir actor system**. This thread is what gives the regulatory argument empirical teeth.

---

## Documents in this folder

### [FDA_MDDT_Proposal.md](FDA_MDDT_Proposal.md) — *the regulatory narrative*

The qualification proposal for **ALGT-FMEA** as a Medical Device Development Tool supporting software FMEA on legacy medical device code. Defines the proposed Context of Use, the eight-layer architecture (formal verification → trace comparison → domain models → scenario validation → concurrent safety → probabilistic inference → anomaly detection → semantic fault injection), validation strategy, and the hazard-to-test traceability matrices. **Read this first** if you want to know why the rest of the repository is shaped the way it is.

### [ALGT_CRUTPr.md](ALGT_CRUTPr.md) — *the historical provenance*

The 2003 *Code Review / Unit Test Procedure* (TH 75.000020 Rev A1) for the Siemens COHERENCE Dosimetrist Workspace 2.0. Twelve safety-critical algorithms were verified using SWI-Prolog with DCG parsers over Nuages/VRML/DICOM data and predicate-logic verification conditions. This document is the existence proof that the methodology underlying ALGT-FMEA has 20+ years of production medical device track record — directly relevant to the MDDT qualification's "scientific validity" argument.

### [compositional-semantics.md](compositional-semantics.md) — *the formal backbone of MUZAQ modernization*

Establishes **bisimilarity** as the formal criterion for safe substitution between a legacy component and its modernized replacement. The central observation — that a shared SQL database is an *uncontrolled communication channel*, and that components communicating through it cannot be reasoned about independently unless their database interactions are themselves observable — is exactly what makes the MUZAQ event-stream approach work. If the SQL transaction log is the only communication channel and every entry is a labeled action, bisimilarity over those labels means observers cannot tell the original system from the modernized one.

### [ontology/](ontology/) — *clinical & DICOM terminology*

OWL/Turtle ontologies used to ground simulator types and verification predicates in standardized clinical terminology:

- `basic-clinical-ontology.ttl` — patient, plan, prescription, dose, beam basics
- `dicom-ontology.ttl` — DICOM-RT object model
- `catalog-v001.xml` — OWL import catalog

These are loaded by domain models in [../domain_models/](../domain_models/) and referenced by the verification test suites.

---

## The MUZAQ modernization story (and how the docs support it)

The MUZAQ demo is the connective tissue between every doc in this folder. It shows what the methodology looks like end-to-end on an open, non-proprietary stand-in for MOSAIQ:

```
   Lazarus / FreePascal MUZAQ                Prolog LTS                Elixir actor system
   ╔════════════════════╗      Stage 1      ╔══════════════╗  Stage 2  ╔════════════════════╗
   ║ TForm event handlers ║ ───────────────▶ ║ State + label ║ ────────▶ ║ GenServer per form  ║
   ║ TDataSet operations  ║   parser + LTS   ║ transitions   ║  codegen  ║ NIF/Port C/C++ core ║
   ║ C/C++ FFI calls      ║   extraction     ║ trace exports ║           ║ PubSub on log topic ║
   ╚══════════╤═══════════╝                  ╚══════╤════════╝           ╚══════════╤═════════╝
              │                                      │                                │
              └──────────── shared SQL transaction log ─────────────────────────────┘
                            (canonical event stream)
```

### Forms become actors

Every Lazarus `TForm` — patient setup, schedule editor, treatment console, billing — becomes a single actor (a Prolog process at Stage 1, an Elixir `:gen_statem` at Stage 2). The form's persistent state plus GUI state is the actor's state. Its event handlers are the transition function.

### The SQL transaction log is the event stream

This is the key insight, and it falls out of the [compositional-semantics](compositional-semantics.md) argument:

- Every `TDataSet.Post`, `TSQLQuery.Execute`, every commit produces a sequence of entries in the database's **logical transaction log**.
- That log is the *only* channel through which one form can observe another's effects. Anything that doesn't go through the log is private to a single form's process.
- Therefore, the log entries are exactly the labels whose interleavings need to be considered to model concurrent multi-form interaction.
- GUI events (`OnClick`, `OnChange`, etc.) form a parallel label stream local to each form; they only become globally observable when they cause a log entry.

This gives a clean, finite, and *checkable* description of "what happens when several users work in several forms simultaneously" — precisely the scenario that traditional UI testing cannot enumerate.

### Why this matters for the MDDT proposal

Each thread in the proposal is exercised by the MUZAQ demo:

| MDDT layer | What MUZAQ exercises |
|---|---|
| Formal algorithm verification | C/C++ numerical kernels invoked from Lazarus forms (e.g., dose calc) get the same predicate-based verification as the [algt_tests/](../algt_tests/) suite. |
| Execution-trace comparison | Lazarus binary, Prolog LTS, and Elixir actor system are all replayed against the same recorded trace and diffed — extending the technique already proven against compiled Clarion DLLs. |
| Domain-model formalization | Clinical terms used by the forms are grounded in [ontology/](ontology/). |
| Scenario validation | Multi-form workflows are described in the scenario DSL and replayed across all three implementations. |
| Concurrent safety | Interleavings of the SQL transaction log entries across forms are explored by [../model_checker/](../model_checker/). |
| Probabilistic inference | Trace exports drive PyMC/Stan models that estimate failure-mode likelihoods. |
| Anomaly detection | GNN-VAE over execution traces flags out-of-distribution form behavior. |
| Semantic fault injection | LLM-driven mutation of form handlers tests robustness without manual fault enumeration. |

---

## Where to go next

- **Run something:** see the *Quick Start* in the root [README.md](../README.md).
- **Understand the regulatory frame:** read [FDA_MDDT_Proposal.md](FDA_MDDT_Proposal.md) §1–§3.
- **Understand the formal frame:** read [compositional-semantics.md](compositional-semantics.md) — the bisimilarity argument is short and the appendix has the formal definitions.
- **Understand the historical frame:** read [ALGT_CRUTPr.md](ALGT_CRUTPr.md) §1–§4 for the 2003 verification context.
- **AI-assistant guidance:** [../CLAUDE.md](../CLAUDE.md) (this repo) and [../../CLAUDE.md](../../CLAUDE.md) (surrounding MOSAIQ/Equator/Monaco context).
