"""compare_cdb_prolog.py — Compare CDB debugger trace with Prolog interpreter trace
for FractalLib (Mandelbrot, Julia, Logistic map).

Runs both:
1. CDB attached to Python loading FractalLib.dll (compiled Clarion)
2. SWI-Prolog interpreter executing FractalLib.clw source

Note: Fixed-point arithmetic (10000x scaling) may produce rounding
differences between Prolog native arithmetic and Clarion's IEEE 754.

Usage: python compare_cdb_prolog.py
"""
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CDB = r"C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\cdb.exe"
PYTHON32 = os.path.expanduser(r"~\.pyenv\pyenv-win\versions\3.11.9-win32\python.exe")
PROLOG_DIR = os.path.join(SCRIPT_DIR, "..", "..", "simulators", "clarion", "unified")


def run_cdb_trace():
    """Run CDB and extract procedure-level trace."""
    target = os.path.join(SCRIPT_DIR, "cdb_trace_target.py")
    bp_script = os.path.join(SCRIPT_DIR, "cdb_breakpoints.txt")

    result = subprocess.run(
        [CDB, "-G", "-o", "-cf", bp_script, PYTHON32, target],
        capture_output=True, text=True, timeout=60
    )
    output = result.stdout

    lines = output.split("\n")
    trace = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("TRACE_ENTER "):
            proc = line[len("TRACE_ENTER "):]
            args = []
            i += 1
            while i < len(lines):
                l = lines[i].strip()
                if l.startswith("arg"):
                    i += 1
                    if i < len(lines):
                        val_match = re.search(r'([0-9a-f]{8})$', lines[i].strip())
                        if val_match:
                            val = int(val_match.group(1), 16)
                            if val >= 0x80000000:
                                val -= 0x100000000
                            args.append(val)
                elif "TRACE_EXIT" in l:
                    while i < len(lines):
                        eax_match = re.match(r'eax=([0-9a-f]+)', lines[i].strip())
                        if eax_match:
                            ret = int(eax_match.group(1), 16)
                            if ret >= 0x80000000:
                                ret -= 0x100000000
                            arg_str = ", ".join(str(a) for a in args)
                            trace.append(f"CALL {proc}({arg_str}) -> {ret}")
                            break
                        i += 1
                    break
                i += 1
        i += 1
    return trace


def run_prolog_trace():
    """Run Prolog interpreter and extract procedure-level trace."""
    result = subprocess.run(
        ["swipl", "-g", "main,halt", "-t", "halt(1)", "traces/trace_fractal.pl"],
        capture_output=True, text=True, timeout=30,
        cwd=PROLOG_DIR
    )
    trace = []
    for line in result.stdout.split("\n"):
        line = line.strip()
        if line.startswith("CALL ") and " -> " in line:
            trace.append(line)
    if result.returncode != 0 and not trace:
        print(f"Prolog stderr: {result.stderr}", file=sys.stderr)
    return trace


def main():
    print("=" * 60)
    print("FractalLib: CDB vs Prolog Trace Comparison")
    print("=" * 60)

    print("\n--- Running CDB trace (compiled DLL) ---")
    cdb_trace = run_cdb_trace()
    for line in cdb_trace:
        print(f"  {line}")

    print("\n--- Running Prolog trace (interpreter) ---")
    prolog_trace = run_prolog_trace()
    for line in prolog_trace:
        print(f"  {line}")

    print("\n--- Comparison ---")
    max_len = max(len(cdb_trace), len(prolog_trace))
    all_match = True
    for i in range(max_len):
        cdb_line = cdb_trace[i] if i < len(cdb_trace) else "<missing>"
        prolog_line = prolog_trace[i] if i < len(prolog_trace) else "<missing>"
        if cdb_line == prolog_line:
            print(f"  OK: {cdb_line}")
        else:
            print(f"  MISMATCH:")
            print(f"    CDB:    {cdb_line}")
            print(f"    Prolog: {prolog_line}")
            all_match = False

    print()
    if all_match and len(cdb_trace) == len(prolog_trace) and len(cdb_trace) > 0:
        print(f"RESULT: All {len(cdb_trace)} trace entries match!")
        return 0
    else:
        print(f"RESULT: Traces differ (CDB: {len(cdb_trace)}, Prolog: {len(prolog_trace)})")
        return 1


if __name__ == "__main__":
    sys.exit(main())
