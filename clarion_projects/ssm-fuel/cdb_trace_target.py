"""Target script for CDB debugging of FuelLib.dll.

CDB will attach to this process and set breakpoints on DLL exports.
Omits FLGetTransaction and FLDeleteTransaction (require MemCopy/REMOVE).
"""
import ctypes
import os
import sys


def main():
    dll_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bin", "FuelLib.dll")
    if not os.path.exists(dll_path):
        print(f"Error: {dll_path} not found.", file=sys.stderr)
        return 1

    # Clean up previous data files
    for f in ["FuelPrice.dat", "FuelTrans.dat"]:
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), f)
        if os.path.exists(p):
            os.remove(p)

    lib = ctypes.CDLL(dll_path)
    print("DLL_LOADED", flush=True)

    # Open files
    r = lib.FLOpen()
    print(f"FLOpen -> {r}", flush=True)

    # Set prices for 4 fuel types
    for ft, price in [(1, 359), (2, 389), (3, 419), (4, 399)]:
        r = lib.FLSetPrice(ft, price)
        print(f"FLSetPrice({ft},{price}) -> {r}", flush=True)

    # Invalid fuel type
    r = lib.FLSetPrice(5, 100)
    print(f"FLSetPrice(5,100) -> {r}", flush=True)

    # Get prices back
    r = lib.FLGetPrice(1)
    print(f"FLGetPrice(1) -> {r}", flush=True)
    r = lib.FLGetPrice(3)
    print(f"FLGetPrice(3) -> {r}", flush=True)
    r = lib.FLGetPrice(5)
    print(f"FLGetPrice(5) -> {r}", flush=True)

    # Add transactions (descPtr=0, descLen=0)
    r = lib.FLAddTransaction(3, 1, 2026, 8, 0, 0, 0, 50000)
    print(f"FLAddTransaction(3,1,2026,8,0,0,0,50000) -> {r}", flush=True)
    r = lib.FLAddTransaction(3, 1, 2026, 10, 30, 0, 0, -1500)
    print(f"FLAddTransaction(3,1,2026,10,30,0,0,-1500) -> {r}", flush=True)
    r = lib.FLAddTransaction(3, 2, 2026, 14, 15, 0, 0, -2500)
    print(f"FLAddTransaction(3,2,2026,14,15,0,0,-2500) -> {r}", flush=True)

    # Check count and balance
    r = lib.FLGetTransactionCount()
    print(f"FLGetTransactionCount -> {r}", flush=True)
    r = lib.FLGetBalance()
    print(f"FLGetBalance -> {r}", flush=True)

    # Recalc balances
    r = lib.FLRecalcBalances()
    print(f"FLRecalcBalances -> {r}", flush=True)

    # Close
    r = lib.FLClose()
    print(f"FLClose -> {r}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
