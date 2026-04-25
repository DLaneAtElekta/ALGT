# Legacy Pascal & Modula-2 Corpus

A curated cross-section of the author's historical Turbo Pascal / Logitech
Modula-2 work, recovered from DOSBox archives and committed here as
**reference material and future targets** for the Pascal simulator.

The simulator's parser currently targets the Object Pascal / Lazarus
dialect (see [../../simulators/pascal/unified/README.md](../../simulators/pascal/unified/README.md)). These older sources are
**not** parseable by the current grammar — they use Turbo Pascal 3/5 or
Logitech Modula-2 dialects. They are included for three reasons:

1. **Reference** — show the "before" of the modernization arc that ends in
   MUZAQ. Many MUZAQ idioms (modular GUI screens, table-driven forms,
   serial RT planning data) trace back to these programs.
2. **Future parser targets** — extending the grammar to the older dialects
   is mechanical; these files give a realistic test corpus.
3. **Provenance for the MDDT proposal** — the FDA proposal in
   [/docs/FDA_MDDT_Proposal.md](../../docs/FDA_MDDT_Proposal.md)
   argues that the underlying Prolog-based methodology has 20+ years of
   medical device track record. These sources, alongside the 2003 CRUTPr
   provenance, anchor that claim.

## Timeline

| Directory | Year/Mo | Lang | Files | What it is |
|---|---|---|---:|---|
| [1985-gdem-pascal/](1985-gdem-pascal/)                       | 1985            | Turbo Pascal | 1  | `EME.PAS` — earliest map editor (GDEM) |
| [1987-04-radiotx-pascal/](1987-04-radiotx-pascal/)           | 1987-04         | Turbo Pascal | 10 | `RADIOTX.PAS` / `RADIORX.PAS` — RT plan transmitter / receiver, with `RADAR.PAS`, `CUSTOM.PAS` |
| [1987-05-tennterm-pascal/](1987-05-tennterm-pascal/)         | 1987-05         | Turbo Pascal | 4  | Tennessee terminal port of the same RadioTx code |
| [1987-11-pas2mod2-modula2/](1987-11-pas2mod2-modula2/)       | 1987-11         | TP + M2     | 48 | **Pivotal** — Pascal-to-Modula-2 transition; both `RADAR.PAS` and `RADAR.MOD` side by side, plus `MENU`, `PICTURE`, `MAP`, `SCREEN`, `KEYDISPATCH`, `SELECTOR`, `MODEM` modules |
| [1987-11-egalib-modula2/](1987-11-egalib-modula2/)           | 1987-11         | Modula-2    | 16 | `EGALIB.MOD` — EGA graphics library; `AREA`, `FIGURES`, `FONTS`, `PICSTORE`, `WINDOWS`, `SELECTOR` |
| [1988-02-sn8801-pascal/](1988-02-sn8801-pascal/)             | 1988-02         | Turbo Pascal | 22 | RADAR SN8801 release; `RADAR.PAS`, `RADART.PAS`, `MODEM.PAS`, `RADTEST.PAS` |
| [1988-05-radar1-pascal/](1988-05-radar1-pascal/)             | 1988-05         | Turbo Pascal | 17 | RADAR 1.x snapshot |
| [1988-05-ssm-modula2/](1988-05-ssm-modula2/)                 | 1988-05         | Modula-2    | 25 | SSM Modula-2 attempt; `SHEET.MOD`, `NODE.MOD`, `DEMO1/2.MOD`, `SERVICES.MOD`, `TIMEUTIL.MOD` |
| [1988-08-tenn-db-pascal/](1988-08-tenn-db-pascal/)           | 1988-08         | Turbo Pascal | 11 | E300DB — `RADAR.PAS`, `RADIO.PAS`, `RADIORX.PAS`, `RADIOTX.PAS`, `CUSTOM.PAS` |
| [1988-08-e300-modula2/](1988-08-e300-modula2/)               | 1988-08         | Modula-2    | 57 | E300 platform — `WINDOWS.MOD`, `ANALYSIS.MOD`, `SELECTOR.MOD`, `LOWLEVEL.MOD`, `CRC.MOD`, `FIO.MOD` |
| [1989-01-radar2_1-pascal/](1989-01-radar2_1-pascal/)         | 1989-01         | Turbo Pascal | 24 | RADAR 2.1 — `RADAR.PAS`, `RADAR2.PAS`, `RADAR10.PAS`, `TABLE.PAS`, `R8701.PAS`–`R8802.PAS` (monthly snapshots) |
| [1991-02-ssm-pascal/](1991-02-ssm-pascal/)                   | 1991-02         | Turbo Pascal | 37 | SSM accounting — `AR.PAS`, `FIM.PAS`, `UTILITY.PAS`, `UTILITY2.PAS` |
| [1992-12-e300db-modula2/](1992-12-e300db-modula2/)           | 1992-12         | Modula-2    | 68 | E300DB final — full `MOD/`, `DEF/`, `OBJ/` tree |
| [1995-05-ssm-pascal/](1995-05-ssm-pascal/)                   | 1995-05         | Turbo Pascal | 47 | Latest SSM Pascal |
| [automata-modula2/](automata-modula2/)                       | mid-late 80s    | Modula-2    | 8  | Cellular automata — `AUTOMATA.MOD`, `2DAUTO.MOD`, `TWODAUTO.MOD`, `GRAPHICS.MOD`, `ASCII.MOD` |
| [bqtourn-pascal/](bqtourn-pascal/)                           | mid-late 80s    | Turbo Pascal | 2  | Bridge tournament tracker |
| [e250term-modula2/](e250term-modula2/)                       | mid-late 80s    | Modula-2    | 7  | E250 terminal — `E250TERM.MOD`, `E250DRAW.MOD`, `E250EDIT.MOD`, `E250SCRN.MOD`, `SCRNSEND.MOD` |

Total: ~404 source files across ten years and two languages.

## Origin

Recovered from `C:\DOSBOX_C\` archives:

- `E300DB/Source/Attic/` — earliest RadioTx + E300 database
- `E300PC/Source/Attic/` — RADAR + EGAlib + Pas-to-Mod2 transition
- `SSM/SOURCE/` — Stadium Software Management accounting + Modula-2 fork
- `E250Term/Source/` — E250 terminal Modula-2 port
- `AUTOMATA/`, `BQTourn/` — standalone projects

Cleanup applied: removed `.COM`, `.EXE`, `.OBJ`, `.LNK`, `.REF`, `.SYM`,
`.LOD`, `.BAK`, `.MAP`, `.TPU`, `.DBD`, `.DAT`, `.TAB` and other build
artefacts. What remains is source plus a few `.TXT` / `.RDR` data files
that the originals depended on.

Third-party libraries are intentionally **not** included:

- Turbo Pascal 3.0 tutor / standard library (Borland)
- Repertoire for Modula-2 (third-party DBMS library)

These are still under `C:\DOSBOX_C\` if a future test ever needs them.

## Modern endpoint

[../modern-lazarus/HelloMUZAQ.pas](../modern-lazarus/HelloMUZAQ.pas) and
its `.lfm` companion are the **modern endpoint** of this arc — what the
same author writes today, ported through 40 years of language evolution
and now expressed in Object Pascal with a Lazarus form, ready for the
MUZAQ modernization demo (Pascal → Prolog LTS → Elixir actors).
