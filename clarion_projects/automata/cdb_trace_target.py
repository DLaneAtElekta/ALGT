"""Target script for CDB debugging of AutomataLib.dll.

CDB will attach to this process and set breakpoints on DLL exports.
"""
import ctypes
import os
import sys


def main():
    dll_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bin", "AutomataLib.dll")
    if not os.path.exists(dll_path):
        print(f"Error: {dll_path} not found.", file=sys.stderr)
        return 1

    lib = ctypes.CDLL(dll_path)
    print("DLL_LOADED", flush=True)

    # Initialize
    r = lib.CAInit()
    print(f"CAInit -> {r}", flush=True)

    # Set rules: identity mapping rule[i] = min(i, 15)
    for i, v in [(0, 0), (1, 1), (2, 2), (3, 3)]:
        r = lib.CASetRule(i, v)
        print(f"CASetRule({i},{v}) -> {r}", flush=True)

    # Verify rules
    r = lib.CAGetRule(1)
    print(f"CAGetRule(1) -> {r}", flush=True)
    r = lib.CAGetRule(3)
    print(f"CAGetRule(3) -> {r}", flush=True)

    # Out-of-range rule access
    r = lib.CAGetRule(50)
    print(f"CAGetRule(50) -> {r}", flush=True)

    # Set a seed cell
    r = lib.CASetCell(320, 1)
    print(f"CASetCell(320,1) -> {r}", flush=True)

    # Read back the cell
    r = lib.CAGetCell(320)
    print(f"CAGetCell(320) -> {r}", flush=True)

    # Out-of-range cell access
    r = lib.CAGetCell(-1)
    print(f"CAGetCell(-1) -> {r}", flush=True)

    # Step the automaton
    r = lib.CAStep()
    print(f"CAStep -> {r}", flush=True)

    # Check cells after step
    r = lib.CAGetCell(319)
    print(f"CAGetCell(319) -> {r}", flush=True)
    r = lib.CAGetCell(320)
    print(f"CAGetCell(320) -> {r}", flush=True)
    r = lib.CAGetCell(321)
    print(f"CAGetCell(321) -> {r}", flush=True)

    # Spatial entropy
    r = lib.CASpatialEntropy()
    print(f"CASpatialEntropy -> {r}", flush=True)

    # Cell count
    r = lib.CAGetCellCount(0)
    print(f"CAGetCellCount(0) -> {r}", flush=True)
    r = lib.CAGetCellCount(1)
    print(f"CAGetCellCount(1) -> {r}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
