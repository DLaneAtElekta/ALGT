  MEMBER()

! ============================================================
! StructLib: Demonstrates GROUP and QUEUE passing via pointers
! ============================================================

! --- GROUP definition: a single patient vitals record ---
VitalsGrp   GROUP,PRE(VG)
PatientID     LONG
HeartRate     LONG          ! bpm
SysBP         LONG          ! systolic blood pressure mmHg
DiaBP         LONG          ! diastolic blood pressure mmHg
Temperature   LONG          ! tenths of degrees F (e.g. 986 = 98.6)
SpO2          LONG          ! percent oxygen saturation
            END

! --- QUEUE definition: same layout, used as an array buffer ---
VitalsQ     QUEUE,PRE(VQ)
PatientID     LONG
HeartRate     LONG
SysBP         LONG
DiaBP         LONG
Temperature   LONG
SpO2          LONG
            END

ResultGrp   GROUP,PRE(RG)
MeanHR        LONG          ! mean heart rate
MeanSysBP     LONG
MeanDiaBP     LONG
MeanTemp      LONG
MeanSpO2      LONG
Count         LONG
Alerts        LONG          ! bitfield: 1=tachy, 2=hypertensive, 4=hypoxic
            END

  MAP
    MODULE('kernel32')
      MemCopy(LONG dest, LONG src, LONG len),RAW,PASCAL,NAME('RtlMoveMemory')
    END
    SLClassifyVitals(LONG grpPtr, LONG resultPtr),LONG,C,NAME('SLClassifyVitals'),EXPORT
    SLSummarizeQueue(LONG qPtr, LONG count, LONG resultPtr),LONG,C,NAME('SLSummarizeQueue'),EXPORT
    SLGetVitalsSize(),LONG,C,NAME('SLGetVitalsSize'),EXPORT
    SLGetResultSize(),LONG,C,NAME('SLGetResultSize'),EXPORT
  END

! ------------------------------------------------------------
! SLGetVitalsSize: returns SIZE(VitalsGrp) so Python can verify
! ------------------------------------------------------------
SLGetVitalsSize PROCEDURE()
  CODE
  RETURN SIZE(VitalsGrp)

! ------------------------------------------------------------
! SLGetResultSize: returns SIZE(ResultGrp) so Python can verify
! ------------------------------------------------------------
SLGetResultSize PROCEDURE()
  CODE
  RETURN SIZE(ResultGrp)

! ------------------------------------------------------------
! SLClassifyVitals: read a single VitalsGrp, classify, write result
!   Input:  grpPtr    -> pointer to a VitalsGrp
!   Output: resultPtr -> pointer to a ResultGrp (filled in)
!   Returns 0 on success
! ------------------------------------------------------------
SLClassifyVitals PROCEDURE(LONG grpPtr, LONG resultPtr)
Alerts  LONG(0)
  CODE
  ! Deserialize: copy from caller's buffer into our GROUP
  MemCopy(ADDRESS(VitalsGrp), grpPtr, SIZE(VitalsGrp))

  ! Classify
  IF VG:HeartRate > 100
    Alerts = BOR(Alerts, 1)       ! tachycardic
  END
  IF VG:SysBP > 140
    Alerts = BOR(Alerts, 2)       ! hypertensive
  END
  IF VG:SpO2 < 90
    Alerts = BOR(Alerts, 4)       ! hypoxic
  END

  ! Build result
  CLEAR(ResultGrp)
  RG:MeanHR    = VG:HeartRate
  RG:MeanSysBP = VG:SysBP
  RG:MeanDiaBP = VG:DiaBP
  RG:MeanTemp  = VG:Temperature
  RG:MeanSpO2  = VG:SpO2
  RG:Count     = 1
  RG:Alerts    = Alerts

  ! Serialize: copy our result GROUP back to caller's buffer
  MemCopy(resultPtr, ADDRESS(ResultGrp), SIZE(ResultGrp))
  RETURN 0

! ------------------------------------------------------------
! SLSummarizeQueue: read an array of VitalsGrp, compute averages
!   Input:  qPtr      -> pointer to array of VitalsGrp structs
!           count     -> number of entries
!   Output: resultPtr -> pointer to a ResultGrp (filled in)
!   Returns 0 on success, -1 if count <= 0
! ------------------------------------------------------------
SLSummarizeQueue PROCEDURE(LONG qPtr, LONG count, LONG resultPtr)
I       LONG
Offset  LONG
SumHR   LONG(0)
SumSys  LONG(0)
SumDia  LONG(0)
SumTmp  LONG(0)
SumO2   LONG(0)
Alerts  LONG(0)
  CODE
  IF count <= 0 THEN RETURN -1.

  ! Read each struct from the array
  LOOP I = 0 TO count - 1
    Offset = I * SIZE(VitalsGrp)
    MemCopy(ADDRESS(VitalsGrp), qPtr + Offset, SIZE(VitalsGrp))

    SumHR  += VG:HeartRate
    SumSys += VG:SysBP
    SumDia += VG:DiaBP
    SumTmp += VG:Temperature
    SumO2  += VG:SpO2

    ! Accumulate alerts from any reading
    IF VG:HeartRate > 100
      Alerts = BOR(Alerts, 1)
    END
    IF VG:SysBP > 140
      Alerts = BOR(Alerts, 2)
    END
    IF VG:SpO2 < 90
      Alerts = BOR(Alerts, 4)
    END
  END

  ! Compute averages (integer division)
  CLEAR(ResultGrp)
  RG:MeanHR    = SumHR  / count
  RG:MeanSysBP = SumSys / count
  RG:MeanDiaBP = SumDia / count
  RG:MeanTemp  = SumTmp / count
  RG:MeanSpO2  = SumO2  / count
  RG:Count     = count
  RG:Alerts    = Alerts

  MemCopy(resultPtr, ADDRESS(ResultGrp), SIZE(ResultGrp))
  RETURN 0
