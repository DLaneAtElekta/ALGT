"""Python wrapper for StructLib Clarion DLL.

Demonstrates ctypes serialization/deserialization of Clarion GROUPs and QUEUEs.

Key concepts:
  - Clarion GROUPs are contiguous, byte-packed structs (no padding)
  - Use ctypes.Structure with _pack_ = 1 to match Clarion's layout
  - Pass structs as LONG pointers via ctypes.addressof()
  - Clarion's MemCopy (RtlMoveMemory) copies between pointer and GROUP
  - QUEUEs with the same field layout as a GROUP can be passed as a
    contiguous array of structs (Array type in ctypes)
"""

import ctypes
import os
from dataclasses import dataclass
from typing import List


# =============================================================
# Step 1: Define ctypes Structures matching the Clarion GROUPs
# =============================================================
#
# CRITICAL: _pack_ = 1
#   Clarion GROUPs have NO padding between fields. The default
#   ctypes alignment on Windows would insert padding (e.g. after
#   a BYTE field), causing offset mismatches. _pack_ = 1 forces
#   byte-aligned packing to match Clarion exactly.
#
# Field mapping:
#   Clarion LONG  ->  ctypes.c_long  (4 bytes, signed 32-bit)
#   Clarion SHORT ->  ctypes.c_short (2 bytes)
#   Clarion BYTE  ->  ctypes.c_byte  (1 byte)
#   Clarion REAL  ->  ctypes.c_double (8 bytes, IEEE 754)
#   Clarion CSTRING(n) -> ctypes.c_char * n (null-terminated)
#   Clarion STRING(n)  -> ctypes.c_char * n (space-padded, no null)

class VitalsStruct(ctypes.Structure):
    """Matches Clarion VitalsGrp GROUP layout.

    Clarion source:
        VitalsGrp   GROUP,PRE(VG)
        PatientID     LONG
        HeartRate     LONG
        SysBP         LONG
        DiaBP         LONG
        Temperature   LONG    ! tenths of degrees F
        SpO2          LONG    ! percent
                    END
    """
    _pack_ = 1  # Must match Clarion's byte-packed layout
    _fields_ = [
        ('patient_id',  ctypes.c_long),
        ('heart_rate',  ctypes.c_long),
        ('sys_bp',      ctypes.c_long),
        ('dia_bp',      ctypes.c_long),
        ('temperature', ctypes.c_long),  # tenths of F (986 = 98.6F)
        ('spo2',        ctypes.c_long),
    ]


class ResultStruct(ctypes.Structure):
    """Matches Clarion ResultGrp GROUP layout.

    Clarion source:
        ResultGrp   GROUP,PRE(RG)
        MeanHR        LONG
        MeanSysBP     LONG
        MeanDiaBP     LONG
        MeanTemp      LONG
        MeanSpO2      LONG
        Count         LONG
        Alerts        LONG    ! bitfield: 1=tachy, 2=hypertensive, 4=hypoxic
                    END
    """
    _pack_ = 1
    _fields_ = [
        ('mean_hr',     ctypes.c_long),
        ('mean_sys_bp', ctypes.c_long),
        ('mean_dia_bp', ctypes.c_long),
        ('mean_temp',   ctypes.c_long),
        ('mean_spo2',   ctypes.c_long),
        ('count',       ctypes.c_long),
        ('alerts',      ctypes.c_long),
    ]


# Alert bitfield constants
ALERT_TACHYCARDIC  = 1
ALERT_HYPERTENSIVE = 2
ALERT_HYPOXIC      = 4


# =============================================================
# Step 2: Pythonic dataclass for the result
# =============================================================

@dataclass
class VitalsResult:
    mean_hr: int
    mean_sys_bp: int
    mean_dia_bp: int
    mean_temp: int
    mean_spo2: int
    count: int
    alerts: int

    @property
    def is_tachycardic(self) -> bool:
        return bool(self.alerts & ALERT_TACHYCARDIC)

    @property
    def is_hypertensive(self) -> bool:
        return bool(self.alerts & ALERT_HYPERTENSIVE)

    @property
    def is_hypoxic(self) -> bool:
        return bool(self.alerts & ALERT_HYPOXIC)

    @classmethod
    def _from_struct(cls, s: ResultStruct) -> 'VitalsResult':
        return cls(
            mean_hr=s.mean_hr,
            mean_sys_bp=s.mean_sys_bp,
            mean_dia_bp=s.mean_dia_bp,
            mean_temp=s.mean_temp,
            mean_spo2=s.mean_spo2,
            count=s.count,
            alerts=s.alerts,
        )


# =============================================================
# Step 3: DLL wrapper class
# =============================================================

class StructLib:
    def __init__(self, dll_path: str = None):
        if dll_path is None:
            dll_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bin')
            dll_path = os.path.join(dll_dir, 'StructLib.dll')
        self._lib = ctypes.CDLL(dll_path)
        self._setup()

    def _setup(self):
        lib = self._lib

        lib.SLGetVitalsSize.argtypes = []
        lib.SLGetVitalsSize.restype = ctypes.c_long

        lib.SLGetResultSize.argtypes = []
        lib.SLGetResultSize.restype = ctypes.c_long

        # Both GROUP-passing functions take LONG pointers
        lib.SLClassifyVitals.argtypes = [ctypes.c_long, ctypes.c_long]
        lib.SLClassifyVitals.restype = ctypes.c_long

        lib.SLSummarizeQueue.argtypes = [ctypes.c_long, ctypes.c_long, ctypes.c_long]
        lib.SLSummarizeQueue.restype = ctypes.c_long

    def verify_sizes(self):
        """Verify Python struct sizes match Clarion GROUP sizes."""
        clr_vitals = self._lib.SLGetVitalsSize()
        clr_result = self._lib.SLGetResultSize()
        py_vitals = ctypes.sizeof(VitalsStruct)
        py_result = ctypes.sizeof(ResultStruct)
        assert clr_vitals == py_vitals, \
            f"VitalsStruct size mismatch: Clarion={clr_vitals}, Python={py_vitals}"
        assert clr_result == py_result, \
            f"ResultStruct size mismatch: Clarion={clr_result}, Python={py_result}"

    # ---------------------------------------------------------
    # Passing a single GROUP (struct) to the DLL
    # ---------------------------------------------------------
    def classify_vitals(
        self, patient_id: int, heart_rate: int,
        sys_bp: int, dia_bp: int, temperature: int, spo2: int,
    ) -> VitalsResult:
        """Classify a single vitals reading.

        Serialization steps:
          1. Create a VitalsStruct instance and populate fields
          2. Pass ctypes.addressof(struct) as a LONG to the DLL
          3. DLL uses MemCopy to read the struct into its GROUP
          4. DLL writes result into a ResultStruct via MemCopy
          5. Read the ResultStruct fields back in Python
        """
        # Serialize: Python values -> ctypes struct -> memory
        vitals = VitalsStruct(
            patient_id=patient_id,
            heart_rate=heart_rate,
            sys_bp=sys_bp,
            dia_bp=dia_bp,
            temperature=temperature,
            spo2=spo2,
        )
        result = ResultStruct()

        rc = self._lib.SLClassifyVitals(
            ctypes.addressof(vitals),
            ctypes.addressof(result),
        )
        assert rc == 0, f"SLClassifyVitals returned {rc}"

        # Deserialize: ctypes struct -> Python dataclass
        return VitalsResult._from_struct(result)

    # ---------------------------------------------------------
    # Passing a QUEUE (array of structs) to the DLL
    # ---------------------------------------------------------
    def summarize_queue(self, readings: List[dict]) -> VitalsResult:
        """Summarize multiple vitals readings.

        Serialization steps:
          1. Create a ctypes Array of VitalsStruct (contiguous memory)
          2. Populate each element
          3. Pass ctypes.addressof(array) + count as LONGs
          4. DLL iterates the array using pointer arithmetic:
               offset = i * SIZE(VitalsGrp)
               MemCopy(ADDRESS(VitalsGrp), qPtr + offset, SIZE(VitalsGrp))
          5. DLL writes aggregated result via MemCopy
        """
        count = len(readings)

        # Create a contiguous array: (VitalsStruct * N)()
        # This allocates N consecutive VitalsStruct in memory,
        # which is exactly how Clarion sees a QUEUE buffer.
        ArrayType = VitalsStruct * count
        arr = ArrayType()

        for i, r in enumerate(readings):
            arr[i].patient_id  = r['patient_id']
            arr[i].heart_rate  = r['heart_rate']
            arr[i].sys_bp      = r['sys_bp']
            arr[i].dia_bp      = r['dia_bp']
            arr[i].temperature = r['temperature']
            arr[i].spo2        = r['spo2']

        result = ResultStruct()

        rc = self._lib.SLSummarizeQueue(
            ctypes.addressof(arr),
            count,
            ctypes.addressof(result),
        )
        assert rc == 0, f"SLSummarizeQueue returned {rc}"

        return VitalsResult._from_struct(result)
