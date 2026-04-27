  PROGRAM
! ============================================================================
! ThirdPartyOffset.clw — Simplified ThirdPartyOffset form
!
! Core clinical logic for third-party offset calculation:
!   - Checkbox-driven enable/disable of offset entry fields
!   - Vector magnitude calculation: ISqrt(x^2 + y^2 + z^2)
!   - Angular range validation (reject > +/-899 scaled units = 89.9 deg)
!   - EnableSave: OK button gated on any known component
!   - CASE FIELD() / CASE EVENT() two-level dispatch
! ============================================================================

  MAP
    ISqrt(LONG),LONG
  END

! Translation offsets (LONG, scaled x10 for 1 decimal place)
LinearX        LONG(0)
LinearY        LONG(0)
LinearZ        LONG(0)

! Rotation offsets (LONG, scaled x10)
AngularX       LONG(0)
AngularY       LONG(0)
AngularZ       LONG(0)

! Known-component checkboxes (0 or 1)
IsXcmKnown     BYTE(0)
IsYcmKnown     BYTE(0)
IsZcmKnown     BYTE(0)
IsXdegKnown    BYTE(0)
IsYdegKnown    BYTE(0)
IsZdegKnown    BYTE(0)

! Computed magnitude (scaled x10)
VectorLength   LONG(0)

! Angular range limit (scaled x10: 899 = 89.9 degrees)
AngRangeLimit  LONG(899)

! Prior angular value for reject-and-restore
AngPrior       LONG(0)

! Offset metadata
IsHistoric     SHORT(0)
SourceIdx      LONG(1)

Window WINDOW('Third Party Offset'),AT(0,0,286,207),CENTER
       CHECK('X cm'),AT(35,82,23,10),USE(IsXcmKnown)
       ENTRY(@n-5),AT(61,82,25,10),USE(LinearX)
       CHECK('Y cm'),AT(35,96,23,10),USE(IsYcmKnown)
       ENTRY(@n-5),AT(61,96,25,10),USE(LinearY)
       CHECK('Z cm'),AT(35,110,23,10),USE(IsZcmKnown)
       ENTRY(@n-5),AT(61,110,25,10),USE(LinearZ)
       ENTRY(@n-6),AT(61,130,25,10),USE(VectorLength)
       CHECK('X deg'),AT(148,82,23,10),USE(IsXdegKnown)
       ENTRY(@n-5),AT(175,82,25,10),USE(AngularX)
       CHECK('Y deg'),AT(148,96,23,10),USE(IsYdegKnown)
       ENTRY(@n-5),AT(175,96,25,10),USE(AngularY)
       CHECK('Z deg'),AT(148,110,28,10),USE(IsZdegKnown)
       ENTRY(@n-5),AT(175,110,25,10),USE(AngularZ)
       BUTTON('OK'),AT(237,6,45,13),USE(?OkButton)
       BUTTON('Cancel'),AT(237,23,45,13),USE(?CancelButton)
     END

  CODE
  OPEN(Window)
  DISABLE(?OkButton)
  DISPLAY

  ACCEPT
    CASE FIELD()
    OF ?IsXcmKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
        DO ChangeMagnitude
      END
    OF ?LinearX
      CASE EVENT()
      OF EVENT:Accepted
        DO ChangeMagnitude
      END
    OF ?IsYcmKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
        DO ChangeMagnitude
      END
    OF ?LinearY
      CASE EVENT()
      OF EVENT:Accepted
        DO ChangeMagnitude
      END
    OF ?IsZcmKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
        DO ChangeMagnitude
      END
    OF ?LinearZ
      CASE EVENT()
      OF EVENT:Accepted
        DO ChangeMagnitude
      END
    OF ?IsXdegKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
      END
    OF ?AngularX
      CASE EVENT()
      OF EVENT:Accepted
        IF ABS(AngularX) > AngRangeLimit
          AngularX = AngPrior
          SELECT(?AngularX)
          CYCLE
        END
        DO ChangeMagnitude
      OF EVENT:Selected
        AngPrior = AngularX
      END
    OF ?IsYdegKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
      END
    OF ?AngularY
      CASE EVENT()
      OF EVENT:Accepted
        IF ABS(AngularY) > AngRangeLimit
          AngularY = AngPrior
          SELECT(?AngularY)
          CYCLE
        END
        DO ChangeMagnitude
      OF EVENT:Selected
        AngPrior = AngularY
      END
    OF ?IsZdegKnown
      CASE EVENT()
      OF EVENT:Accepted
        DO ProcessKnownComponent
      END
    OF ?AngularZ
      CASE EVENT()
      OF EVENT:Accepted
        IF ABS(AngularZ) > AngRangeLimit
          AngularZ = AngPrior
          SELECT(?AngularZ)
          CYCLE
        END
        DO ChangeMagnitude
      OF EVENT:Selected
        AngPrior = AngularZ
      END
    OF ?OkButton
      CASE EVENT()
      OF EVENT:Accepted
        BREAK
      END
    OF ?CancelButton
      CASE EVENT()
      OF EVENT:Accepted
        BREAK
      END
    END
  END
  CLOSE(Window)
  RETURN

ChangeMagnitude ROUTINE
  IF ~IsXcmKnown AND ~IsYcmKnown AND ~IsZcmKnown
    VectorLength = 0
    EXIT
  END
  VectorLength = ISqrt(LinearX * LinearX + LinearY * LinearY + LinearZ * LinearZ)
  DO EnableSave

ProcessKnownComponent ROUTINE
  IF IsXcmKnown
    ENABLE(?LinearX)
  ELSE
    DISABLE(?LinearX)
    LinearX = 0
  END
  IF IsYcmKnown
    ENABLE(?LinearY)
  ELSE
    DISABLE(?LinearY)
    LinearY = 0
  END
  IF IsZcmKnown
    ENABLE(?LinearZ)
  ELSE
    DISABLE(?LinearZ)
    LinearZ = 0
  END
  IF IsXdegKnown
    ENABLE(?AngularX)
  ELSE
    DISABLE(?AngularX)
    AngularX = 0
  END
  IF IsYdegKnown
    ENABLE(?AngularY)
  ELSE
    DISABLE(?AngularY)
    AngularY = 0
  END
  IF IsZdegKnown
    ENABLE(?AngularZ)
  ELSE
    DISABLE(?AngularZ)
    AngularZ = 0
  END
  DO EnableSave

EnableSave ROUTINE
  IF IsXcmKnown OR IsYcmKnown OR IsZcmKnown OR |
     IsXdegKnown OR IsYdegKnown OR IsZdegKnown
    ENABLE(?OkButton)
  ELSE
    DISABLE(?OkButton)
  END

ISqrt PROCEDURE(LONG n)
x  LONG
x1 LONG
  CODE
  IF n <= 0 THEN RETURN 0.
  x = n
  x1 = (x + 1) / 2
  LOOP WHILE x1 < x
    x = x1
    x1 = (x + n / x) / 2
  END
  RETURN x
