!============================================================
! prescription_form.clw - Radiation Prescription Entry Form
! Demonstrates: LIST control with QUEUE, master-detail form,
!               data validation, and treatment planning fields
! Uses internal ROUTINEs for helper functions
!============================================================

  PROGRAM

  MAP
    PrescriptionForm  PROCEDURE
  END

! Queue for storing prescriptions
PrescriptionQ   QUEUE,PRE(Rx)
RxID              LONG           ! Unique prescription ID
SiteName          STRING(50)     ! Treatment site (e.g., 'Left Breast')
TotalDose         DECIMAL(8,2)   ! Total dose in cGy
NumFractions      LONG           ! Number of fractions
FractionDose      DECIMAL(8,2)   ! Dose per fraction in cGy
Technique         STRING(30)     ! Treatment technique
Modality          STRING(20)     ! Treatment modality
                END

! Treatment Technique options
TechniqueQ      QUEUE,PRE(Tech)
TechName          STRING(30)
                END

! Treatment Modality options
ModalityQ       QUEUE,PRE(Mod)
ModName           STRING(20)
                END

! Treatment Course fields (top-level)
CourseNumber    LONG(1)
DiagnosisCode   STRING(20)
AssigningMD     STRING(50)

! Physician options
PhysicianQ      QUEUE,PRE(Phys)
PhysName          STRING(50)
                END

! Global variables for form state
NextRxID        LONG(1)
SelectedRow     LONG(0)
IsNewRecord     BYTE(FALSE)
FormModified    BYTE(FALSE)
CourseModified  BYTE(FALSE)

! Form field variables (bound to controls)
FormRxID        LONG
FormSiteName    STRING(50)
FormTotalDose   DECIMAL(8,2)
FormNumFractions LONG
FormFractionDose DECIMAL(8,2)
FormTechnique   STRING(30)
FormModality    STRING(20)

  CODE
    PrescriptionForm()

!------------------------------------------------------------
! Main Prescription Form Window
!------------------------------------------------------------
PrescriptionForm PROCEDURE
! Local variables
TechChoice      LONG,AUTO
ModChoice       LONG,AUTO
PhysChoice      LONG,AUTO
i               LONG,AUTO
TechIdx         LONG,AUTO
ModIdx          LONG,AUTO
PhysIdx         LONG,AUTO
IsValid         BYTE,AUTO

Window WINDOW('Radiation Prescription Entry - Treatment Course'),AT(,,450,400),CENTER,SYSTEM,GRAY,RESIZE
       ! === Top Section: Treatment Course Information ===
       GROUP('Treatment Course'),AT(5,5,440,55),BOXED
         PROMPT('Course #:'),AT(15,20)
         SPIN(@n3),AT(70,17,40,14),USE(CourseNumber),RANGE(1,99)

         PROMPT('Diagnosis Code:'),AT(125,20)
         ENTRY(@s20),AT(210,17,80,14),USE(DiagnosisCode)

         PROMPT('MD:'),AT(305,20)
         LIST,AT(330,17,110,14),USE(?PhysicianList),DROP(10),FROM(PhysicianQ)

         STRING(''),AT(15,38,280,12),USE(?CourseStatus)
       END

       ! === Middle Section: Prescription List ===
       GROUP('Prescriptions'),AT(5,65,440,115),BOXED
         LIST,AT(10,78,430,97),USE(?PrescriptionList),FROM(PrescriptionQ), |
              FORMAT('20L(2)|M~ID~@n5@40L(2)|M~Site Name~@s50@' & |
                     '50R(2)|M~Total Dose~@n_6.2@35R(2)|M~Fractions~@n3@' & |
                     '50R(2)|M~Fx Dose~@n_6.2@60L(2)|M~Technique~@s30@50L(2)|M~Modality~@s20@')
       END

       ! === Lower Section: Prescription Detail Form ===
       GROUP('Prescription Details'),AT(5,185,440,150),BOXED,USE(?DetailGroup)
         PROMPT('Site Name:'),AT(15,203)
         ENTRY(@s50),AT(110,200,200,14),USE(FormSiteName)

         PROMPT('Total Dose (cGy):'),AT(15,223)
         ENTRY(@n_8.2),AT(110,220,80,14),USE(FormTotalDose)

         PROMPT('Fractions:'),AT(200,223)
         SPIN(@n3),AT(260,220,50,14),USE(FormNumFractions),RANGE(1,50)

         PROMPT('Fx Dose (cGy):'),AT(320,223)
         STRING(@n_8.2),AT(390,223,50,12),USE(?FxDoseDisplay)

         PROMPT('Technique:'),AT(15,243)
         LIST,AT(110,240,150,14),USE(?TechniqueList),DROP(8),FROM(TechniqueQ)

         PROMPT('Modality:'),AT(275,243)
         LIST,AT(330,240,100,14),USE(?ModalityList),DROP(6),FROM(ModalityQ)

         ! Common dose presets
         PROMPT('Quick Presets:'),AT(15,270)
         BUTTON('50Gy/25'),AT(110,267,55,18),USE(?Preset5025)
         BUTTON('60Gy/30'),AT(170,267,55,18),USE(?Preset6030)
         BUTTON('40Gy/15'),AT(230,267,55,18),USE(?Preset4015)
         BUTTON('30Gy/10'),AT(290,267,55,18),USE(?Preset3010)

         ! Detail form buttons
         BUTTON('&OK'),AT(110,300,70,22),USE(?OKButton),DEFAULT
         BUTTON('&Cancel'),AT(190,300,70,22),USE(?CancelButton)
         BUTTON('Calc Fx Dose'),AT(270,300,80,22),USE(?CalcButton)
       END

       ! === Bottom: List Action Buttons ===
       BUTTON('&Add New'),AT(5,340,70,22),USE(?AddButton)
       BUTTON('&Delete'),AT(80,340,70,22),USE(?DeleteButton)
       BUTTON('&Close'),AT(375,340,70,22),USE(?CloseButton)

       STRING(''),AT(5,370,350,12),USE(?StatusText)
       STRING(''),AT(360,370,85,12),USE(?RecordCount),RIGHT
     END

  CODE
    ! Initialize physician options
    FREE(PhysicianQ)
    Phys:PhysName = 'Dr. Smith, John'      ; ADD(PhysicianQ)
    Phys:PhysName = 'Dr. Johnson, Mary'    ; ADD(PhysicianQ)
    Phys:PhysName = 'Dr. Williams, Robert' ; ADD(PhysicianQ)
    Phys:PhysName = 'Dr. Brown, Sarah'     ; ADD(PhysicianQ)
    Phys:PhysName = 'Dr. Davis, Michael'   ; ADD(PhysicianQ)
    Phys:PhysName = 'Dr. Miller, Jennifer' ; ADD(PhysicianQ)

    ! Initialize technique options
    FREE(TechniqueQ)
    Tech:TechName = '3D Conformal'         ; ADD(TechniqueQ)
    Tech:TechName = 'IMRT'                 ; ADD(TechniqueQ)
    Tech:TechName = 'VMAT'                 ; ADD(TechniqueQ)
    Tech:TechName = 'SRS/SBRT'             ; ADD(TechniqueQ)
    Tech:TechName = 'Electron'             ; ADD(TechniqueQ)
    Tech:TechName = 'Brachytherapy'        ; ADD(TechniqueQ)
    Tech:TechName = 'Proton'               ; ADD(TechniqueQ)
    Tech:TechName = 'TSET'                 ; ADD(TechniqueQ)

    ! Initialize modality options
    FREE(ModalityQ)
    Mod:ModName = 'Photon 6MV'             ; ADD(ModalityQ)
    Mod:ModName = 'Photon 10MV'            ; ADD(ModalityQ)
    Mod:ModName = 'Photon 15MV'            ; ADD(ModalityQ)
    Mod:ModName = 'Photon FFF 6MV'         ; ADD(ModalityQ)
    Mod:ModName = 'Photon FFF 10MV'        ; ADD(ModalityQ)
    Mod:ModName = 'Electron 6MeV'          ; ADD(ModalityQ)
    Mod:ModName = 'Electron 9MeV'          ; ADD(ModalityQ)
    Mod:ModName = 'Electron 12MeV'         ; ADD(ModalityQ)
    Mod:ModName = 'Proton'                 ; ADD(ModalityQ)

    ! Initialize treatment course defaults
    CourseNumber = 1
    DiagnosisCode = 'C50.9'                ! Example: Breast cancer, unspecified
    AssigningMD = 'Dr. Smith, John'

    ! Add sample prescription data
    DO AddSampleData

    OPEN(Window)

    ! Initialize form state
    ?DetailGroup{PROP:Disable} = TRUE
    ?DeleteButton{PROP:Disable} = TRUE
    ?RecordCount{PROP:Text} = RECORDS(PrescriptionQ) & ' prescription(s)'
    ?StatusText{PROP:Text} = 'Select a prescription or click Add New'

    ! Select default physician in dropdown
    LOOP i = 1 TO RECORDS(PhysicianQ)
      GET(PhysicianQ, i)
      IF Phys:PhysName = AssigningMD
        SELECT(?PhysicianList, i)
        BREAK
      END
    END
    DO UpdateCourseStatus

    ACCEPT
      CASE EVENT()

      OF EVENT:OpenWindow
        IF RECORDS(PrescriptionQ) > 0
          SELECT(?PrescriptionList, 1)
          SelectedRow = 1
          DO LoadPrescriptionToForm
          ?DetailGroup{PROP:Disable} = FALSE
          ?DeleteButton{PROP:Disable} = FALSE
        END

      OF EVENT:NewSelection
        IF FIELD() = ?PrescriptionList
          SelectedRow = CHOICE(?PrescriptionList)
          IF SelectedRow > 0
            IF FormModified
              IF MESSAGE('Save changes to current prescription?', |
                         'Confirm', ICON:Question, BUTTON:Yes+BUTTON:No) = BUTTON:Yes
                DO SaveFormToPrescription
              END
            END
            DO LoadPrescriptionToForm
            IsNewRecord = FALSE
            FormModified = FALSE
            ?StatusText{PROP:Text} = 'Editing prescription: ' & CLIP(FormSiteName)
          END
        END

      OF EVENT:Accepted
        CASE ACCEPTED()

        ! --- List Selection ---
        OF ?PrescriptionList
          SelectedRow = CHOICE(?PrescriptionList)
          IF SelectedRow > 0
            DO LoadPrescriptionToForm
            ?DetailGroup{PROP:Disable} = FALSE
            ?DeleteButton{PROP:Disable} = FALSE
          END

        ! --- Add New Prescription ---
        OF ?AddButton
          IF FormModified
            IF MESSAGE('Save changes first?','Confirm',ICON:Question,BUTTON:Yes+BUTTON:No) = BUTTON:Yes
              DO SaveFormToPrescription
            END
          END
          IsNewRecord = TRUE
          FormRxID = NextRxID
          FormSiteName = ''
          FormTotalDose = 0
          FormNumFractions = 1
          FormFractionDose = 0
          FormTechnique = ''
          FormModality = ''
          DISPLAY
          ?FxDoseDisplay{PROP:Text} = '0.00'
          ?DetailGroup{PROP:Disable} = FALSE
          SELECT(?FormSiteName)
          ?StatusText{PROP:Text} = 'Enter new prescription details'
          FormModified = FALSE

        ! --- Delete Prescription ---
        OF ?DeleteButton
          IF SelectedRow > 0
            GET(PrescriptionQ, SelectedRow)
            IF MESSAGE('Delete prescription for "' & CLIP(Rx:SiteName) & '"?', |
                       'Confirm Delete', ICON:Question, BUTTON:Yes+BUTTON:No) = BUTTON:Yes
              DELETE(PrescriptionQ)
              ?RecordCount{PROP:Text} = RECORDS(PrescriptionQ) & ' prescription(s)'
              IF RECORDS(PrescriptionQ) > 0
                SelectedRow = 1
                SELECT(?PrescriptionList, 1)
                DO LoadPrescriptionToForm
              ELSE
                SelectedRow = 0
                ?DetailGroup{PROP:Disable} = TRUE
                ?DeleteButton{PROP:Disable} = TRUE
              END
              ?StatusText{PROP:Text} = 'Prescription deleted'
              FormModified = FALSE
            END
          END

        ! --- OK (Save) Button ---
        OF ?OKButton
          DO ValidatePrescription
          IF IsValid
            DO SaveFormToPrescription
            IF IsNewRecord
              NextRxID += 1
              IsNewRecord = FALSE
            END
            ?RecordCount{PROP:Text} = RECORDS(PrescriptionQ) & ' prescription(s)'
            ?StatusText{PROP:Text} = 'Prescription saved: ' & CLIP(FormSiteName)
            FormModified = FALSE
            SELECT(?PrescriptionList, SelectedRow)
          END

        ! --- Cancel Button ---
        OF ?CancelButton
          IF FormModified
            IF MESSAGE('Discard changes?','Confirm',ICON:Question,BUTTON:Yes+BUTTON:No) = BUTTON:No
              CYCLE
            END
          END
          IF IsNewRecord
            IsNewRecord = FALSE
            IF RECORDS(PrescriptionQ) > 0
              SelectedRow = 1
              SELECT(?PrescriptionList, 1)
              DO LoadPrescriptionToForm
            ELSE
              ?DetailGroup{PROP:Disable} = TRUE
            END
          ELSE
            IF SelectedRow > 0
              DO LoadPrescriptionToForm
            END
          END
          FormModified = FALSE
          ?StatusText{PROP:Text} = 'Changes discarded'

        ! --- Calculate Fraction Dose ---
        OF ?CalcButton
          IF FormTotalDose > 0 AND FormNumFractions > 0
            DO CalcFractionDose
            ?FxDoseDisplay{PROP:Text} = FormFractionDose
            FormModified = TRUE
          ELSE
            MESSAGE('Enter Total Dose and Fractions first', 'Calculate')
          END

        ! --- Dose Presets ---
        OF ?Preset5025
          FormTotalDose = 5000
          FormNumFractions = 25
          FormFractionDose = 200
          ?FxDoseDisplay{PROP:Text} = '200.00'
          DISPLAY
          FormModified = TRUE

        OF ?Preset6030
          FormTotalDose = 6000
          FormNumFractions = 30
          FormFractionDose = 200
          ?FxDoseDisplay{PROP:Text} = '200.00'
          DISPLAY
          FormModified = TRUE

        OF ?Preset4015
          FormTotalDose = 4000
          FormNumFractions = 15
          FormFractionDose = 266.67
          ?FxDoseDisplay{PROP:Text} = '266.67'
          DISPLAY
          FormModified = TRUE

        OF ?Preset3010
          FormTotalDose = 3000
          FormNumFractions = 10
          FormFractionDose = 300
          ?FxDoseDisplay{PROP:Text} = '300.00'
          DISPLAY
          FormModified = TRUE

        ! --- Close Button ---
        OF ?CloseButton
          IF FormModified
            IF MESSAGE('Save changes before closing?', |
                       'Confirm', ICON:Question, BUTTON:Yes+BUTTON:No+BUTTON:Cancel) = BUTTON:Yes
              DO ValidatePrescription
              IF IsValid
                DO SaveFormToPrescription
                BREAK
              END
            ELSIF MESSAGE('Save changes before closing?', |
                          'Confirm', ICON:Question, BUTTON:Yes+BUTTON:No+BUTTON:Cancel) = BUTTON:Cancel
              CYCLE
            END
          END
          BREAK

        END ! CASE ACCEPTED()

      OF EVENT:Selected
        ! Track when form fields are modified
        IF FIELD() = ?FormSiteName OR FIELD() = ?FormTotalDose OR |
           FIELD() = ?FormNumFractions OR FIELD() = ?TechniqueList OR |
           FIELD() = ?ModalityList
          FormModified = TRUE
        END
        ! Track when course fields are modified
        IF FIELD() = ?CourseNumber OR FIELD() = ?DiagnosisCode OR |
           FIELD() = ?PhysicianList
          CourseModified = TRUE
          ! Update physician from dropdown
          PhysIdx = CHOICE(?PhysicianList)
          IF PhysIdx > 0
            GET(PhysicianQ, PhysIdx)
            AssigningMD = Phys:PhysName
          END
          DO UpdateCourseStatus
        END

      OF EVENT:CloseWindow
        IF FormModified
          IF MESSAGE('Save changes before closing?','Confirm', |
                     ICON:Question,BUTTON:Yes+BUTTON:No) = BUTTON:Yes
            DO ValidatePrescription
            IF IsValid
              DO SaveFormToPrescription
            END
          END
        END
        BREAK

      END ! CASE EVENT()
    END ! ACCEPT

    CLOSE(Window)
    FREE(PrescriptionQ)
    FREE(TechniqueQ)
    FREE(ModalityQ)
    FREE(PhysicianQ)
    RETURN

!------------------------------------------------------------
! ROUTINE: Calculate fraction dose from total dose and fractions
! Sets: FormFractionDose
!------------------------------------------------------------
CalcFractionDose ROUTINE
    IF FormNumFractions > 0
      FormFractionDose = ROUND(FormTotalDose / FormNumFractions, 0.01)
    ELSE
      FormFractionDose = 0
    END
    EXIT

!------------------------------------------------------------
! ROUTINE: Validate prescription data before saving
! Sets: IsValid (TRUE if valid, FALSE otherwise)
!------------------------------------------------------------
ValidatePrescription ROUTINE
    IsValid = FALSE

    IF CLIP(FormSiteName) = ''
      MESSAGE('Site Name is required', 'Validation Error')
      SELECT(?FormSiteName)
      EXIT
    END

    IF FormTotalDose <= 0
      MESSAGE('Total Dose must be greater than zero', 'Validation Error')
      SELECT(?FormTotalDose)
      EXIT
    END

    IF FormNumFractions <= 0
      MESSAGE('Number of Fractions must be at least 1', 'Validation Error')
      SELECT(?FormNumFractions)
      EXIT
    END

    IF CLIP(FormTechnique) = ''
      MESSAGE('Please select a Treatment Technique', 'Validation Error')
      SELECT(?TechniqueList)
      EXIT
    END

    IF CLIP(FormModality) = ''
      MESSAGE('Please select a Treatment Modality', 'Validation Error')
      SELECT(?ModalityList)
      EXIT
    END

    ! Warning for high fraction doses (hypofractionation)
    IF FormFractionDose > 800
      IF MESSAGE('Fraction dose of ' & FormFractionDose & ' cGy is unusually high.' & |
                 '<13,10>Are you sure this is correct?', 'Warning', |
                 ICON:Exclamation, BUTTON:Yes+BUTTON:No) = BUTTON:No
        SELECT(?FormTotalDose)
        EXIT
      END
    END

    IsValid = TRUE
    EXIT

!------------------------------------------------------------
! ROUTINE: Load selected prescription into form fields
!------------------------------------------------------------
LoadPrescriptionToForm ROUTINE
    IF SelectedRow > 0 AND SelectedRow <= RECORDS(PrescriptionQ)
      GET(PrescriptionQ, SelectedRow)
      FormRxID = Rx:RxID
      FormSiteName = Rx:SiteName
      FormTotalDose = Rx:TotalDose
      FormNumFractions = Rx:NumFractions
      FormFractionDose = Rx:FractionDose
      FormTechnique = Rx:Technique
      FormModality = Rx:Modality
      DISPLAY

      ! Update calculated display
      ?FxDoseDisplay{PROP:Text} = FormFractionDose

      ! Select technique in dropdown
      LOOP i = 1 TO RECORDS(TechniqueQ)
        GET(TechniqueQ, i)
        IF Tech:TechName = Rx:Technique
          SELECT(?TechniqueList, i)
          BREAK
        END
      END

      ! Select modality in dropdown
      LOOP i = 1 TO RECORDS(ModalityQ)
        GET(ModalityQ, i)
        IF Mod:ModName = Rx:Modality
          SELECT(?ModalityList, i)
          BREAK
        END
      END
    END
    EXIT

!------------------------------------------------------------
! ROUTINE: Save form fields to prescription queue
!------------------------------------------------------------
SaveFormToPrescription ROUTINE
    ! Get technique selection
    TechIdx = CHOICE(?TechniqueList)
    IF TechIdx > 0
      GET(TechniqueQ, TechIdx)
      FormTechnique = Tech:TechName
    END

    ! Get modality selection
    ModIdx = CHOICE(?ModalityList)
    IF ModIdx > 0
      GET(ModalityQ, ModIdx)
      FormModality = Mod:ModName
    END

    ! Calculate fraction dose
    DO CalcFractionDose

    ! Populate queue record
    Rx:RxID = FormRxID
    Rx:SiteName = FormSiteName
    Rx:TotalDose = FormTotalDose
    Rx:NumFractions = FormNumFractions
    Rx:FractionDose = FormFractionDose
    Rx:Technique = FormTechnique
    Rx:Modality = FormModality

    IF IsNewRecord
      ADD(PrescriptionQ)
      SelectedRow = RECORDS(PrescriptionQ)
    ELSE
      PUT(PrescriptionQ, SelectedRow)
    END

    ! Refresh the list display
    SELECT(?PrescriptionList, SelectedRow)
    EXIT

!------------------------------------------------------------
! ROUTINE: Add sample prescription data for demonstration
!------------------------------------------------------------
AddSampleData ROUTINE
    FREE(PrescriptionQ)

    ! Sample 1: Breast cancer
    Rx:RxID = NextRxID ; NextRxID += 1
    Rx:SiteName = 'Left Breast'
    Rx:TotalDose = 5000
    Rx:NumFractions = 25
    Rx:FractionDose = 200
    Rx:Technique = 'IMRT'
    Rx:Modality = 'Photon 6MV'
    ADD(PrescriptionQ)

    ! Sample 2: Boost
    Rx:RxID = NextRxID ; NextRxID += 1
    Rx:SiteName = 'Left Breast Boost'
    Rx:TotalDose = 1000
    Rx:NumFractions = 5
    Rx:FractionDose = 200
    Rx:Technique = 'Electron'
    Rx:Modality = 'Electron 9MeV'
    ADD(PrescriptionQ)

    ! Sample 3: Prostate
    Rx:RxID = NextRxID ; NextRxID += 1
    Rx:SiteName = 'Prostate PTV'
    Rx:TotalDose = 7800
    Rx:NumFractions = 39
    Rx:FractionDose = 200
    Rx:Technique = 'VMAT'
    Rx:Modality = 'Photon 10MV'
    ADD(PrescriptionQ)

    ! Sample 4: Lung SBRT
    Rx:RxID = NextRxID ; NextRxID += 1
    Rx:SiteName = 'Right Lung - SBRT'
    Rx:TotalDose = 5000
    Rx:NumFractions = 5
    Rx:FractionDose = 1000
    Rx:Technique = 'SRS/SBRT'
    Rx:Modality = 'Photon FFF 6MV'
    ADD(PrescriptionQ)
    EXIT

!------------------------------------------------------------
! ROUTINE: Update treatment course status display
!------------------------------------------------------------
UpdateCourseStatus ROUTINE
    ?CourseStatus{PROP:Text} = 'Course ' & CourseNumber & |
                               ' | Dx: ' & CLIP(DiagnosisCode) & |
                               ' | MD: ' & CLIP(AssigningMD)
    EXIT
