"""Target script for CDB debugging of FractalLib.dll.

CDB will attach to this process and set breakpoints on DLL exports.
Omits Row procedures (require MemCopy buffer writes).
All coordinates use 10000x fixed-point scaling.
"""
import ctypes
import os
import sys


def main():
    dll_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bin", "FractalLib.dll")
    if not os.path.exists(dll_path):
        print(f"Error: {dll_path} not found.", file=sys.stderr)
        return 1

    lib = ctypes.CDLL(dll_path)
    print("DLL_LOADED", flush=True)

    # --- Mandelbrot single-point tests ---
    # (0, 0) -> in set, should return maxIter=100
    r = lib.FLMandelbrot(0, 0, 100)
    print(f"FLMandelbrot(0,0,100) -> {r}", flush=True)

    # (2.0, 0) -> escapes at iteration 2
    r = lib.FLMandelbrot(20000, 0, 100)
    print(f"FLMandelbrot(20000,0,100) -> {r}", flush=True)

    # (1.0, 0) -> escapes at iteration 3
    r = lib.FLMandelbrot(10000, 0, 100)
    print(f"FLMandelbrot(10000,0,100) -> {r}", flush=True)

    # (-1.0, 0) -> in set
    r = lib.FLMandelbrot(-10000, 0, 100)
    print(f"FLMandelbrot(-10000,0,100) -> {r}", flush=True)

    # (10.0, 0) -> escapes at iteration 1
    r = lib.FLMandelbrot(100000, 0, 100)
    print(f"FLMandelbrot(100000,0,100) -> {r}", flush=True)

    # --- Julia single-point tests ---
    # z=(0,0), c=(-0.7, 0.27015)
    r = lib.FLJulia(0, 0, -7000, 2702, 100)
    print(f"FLJulia(0,0,-7000,2702,100) -> {r}", flush=True)

    # z=(2.0,0), c=(-0.7, 0.27015) -> escapes quickly
    r = lib.FLJulia(20000, 0, -7000, 2702, 100)
    print(f"FLJulia(20000,0,-7000,2702,100) -> {r}", flush=True)

    # --- Logistic map tests ---
    # p=0.5, k=1.0 -> 0.75 -> 7500
    r = lib.FLLogistic(5000, 10000)
    print(f"FLLogistic(5000,10000) -> {r}", flush=True)

    # p=0.1, k=2.0 -> ~0.28 -> 2800 (may differ due to rounding)
    r = lib.FLLogistic(1000, 20000)
    print(f"FLLogistic(1000,20000) -> {r}", flush=True)

    # p=0.0, k=2.5 -> 0 (fixed point)
    r = lib.FLLogistic(0, 25000)
    print(f"FLLogistic(0,25000) -> {r}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
