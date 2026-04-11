"""Tests for StructLib — GROUP and QUEUE passing via ctypes."""

import ctypes
from struct_lib import StructLib, VitalsStruct, ResultStruct

lib = StructLib()

# Verify struct sizes match between Python and Clarion
lib.verify_sizes()
print(f"VitalsStruct size: {ctypes.sizeof(VitalsStruct)} bytes")
print(f"ResultStruct size: {ctypes.sizeof(ResultStruct)} bytes")
print("Size verification passed!\n")

# --- Test 1: Single GROUP input (normal vitals) ---
r = lib.classify_vitals(
    patient_id=1001, heart_rate=72, sys_bp=120, dia_bp=80,
    temperature=986, spo2=98,
)
print(f"Test 1 - Normal vitals: HR={r.mean_hr}, BP={r.mean_sys_bp}/{r.mean_dia_bp}, "
      f"Temp={r.mean_temp/10:.1f}F, SpO2={r.mean_spo2}%, Alerts={r.alerts}")
assert r.mean_hr == 72
assert r.alerts == 0, f"Expected no alerts, got {r.alerts}"
assert not r.is_tachycardic
assert not r.is_hypertensive
assert not r.is_hypoxic
print("  PASS: no alerts\n")

# --- Test 2: Single GROUP input (abnormal vitals) ---
r = lib.classify_vitals(
    patient_id=1002, heart_rate=120, sys_bp=160, dia_bp=95,
    temperature=1012, spo2=85,
)
print(f"Test 2 - Abnormal vitals: HR={r.mean_hr}, BP={r.mean_sys_bp}/{r.mean_dia_bp}, "
      f"SpO2={r.mean_spo2}%, Alerts={r.alerts}")
assert r.is_tachycardic, "Expected tachycardic alert"
assert r.is_hypertensive, "Expected hypertensive alert"
assert r.is_hypoxic, "Expected hypoxic alert"
assert r.alerts == 7  # all three flags
print("  PASS: all 3 alerts flagged\n")

# --- Test 3: QUEUE input (array of structs) ---
readings = [
    {'patient_id': 2001, 'heart_rate': 70,  'sys_bp': 118, 'dia_bp': 76, 'temperature': 984, 'spo2': 99},
    {'patient_id': 2001, 'heart_rate': 80,  'sys_bp': 122, 'dia_bp': 82, 'temperature': 986, 'spo2': 97},
    {'patient_id': 2001, 'heart_rate': 75,  'sys_bp': 120, 'dia_bp': 78, 'temperature': 985, 'spo2': 98},
]
r = lib.summarize_queue(readings)
print(f"Test 3 - Queue summary (3 readings): HR={r.mean_hr}, BP={r.mean_sys_bp}/{r.mean_dia_bp}, "
      f"SpO2={r.mean_spo2}%, Count={r.count}")
assert r.count == 3
assert r.mean_hr == 75      # (70+80+75)/3 = 75
assert r.mean_sys_bp == 120  # (118+122+120)/3 = 120
assert r.alerts == 0
print("  PASS: averages correct, no alerts\n")

# --- Test 4: QUEUE with mixed alert conditions ---
readings = [
    {'patient_id': 3001, 'heart_rate': 110, 'sys_bp': 130, 'dia_bp': 85, 'temperature': 986, 'spo2': 95},
    {'patient_id': 3001, 'heart_rate': 85,  'sys_bp': 150, 'dia_bp': 90, 'temperature': 990, 'spo2': 88},
    {'patient_id': 3001, 'heart_rate': 90,  'sys_bp': 125, 'dia_bp': 80, 'temperature': 984, 'spo2': 96},
    {'patient_id': 3001, 'heart_rate': 78,  'sys_bp': 118, 'dia_bp': 75, 'temperature': 986, 'spo2': 97},
]
r = lib.summarize_queue(readings)
print(f"Test 4 - Queue with alerts (4 readings): HR={r.mean_hr}, BP={r.mean_sys_bp}/{r.mean_dia_bp}, "
      f"SpO2={r.mean_spo2}%, Alerts={r.alerts}")
assert r.count == 4
# Reading 0: HR>100 -> tachy. Reading 1: BP>140 -> hypertensive, SpO2<90 -> hypoxic
assert r.is_tachycardic, "Expected tachycardic (reading 0)"
assert r.is_hypertensive, "Expected hypertensive (reading 1)"
assert r.is_hypoxic, "Expected hypoxic (reading 1)"
assert r.alerts == 7
print("  PASS: alerts accumulated across readings\n")

print("All tests passed!")
