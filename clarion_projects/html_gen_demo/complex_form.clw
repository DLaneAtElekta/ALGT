  PROGRAM
  MAP
  END

ComplexWin WINDOW('Patient Data Entry'),AT(,,300,220),CENTER,GRAY,SYSTEM,FONT('MS Sans Serif',8)
           PROMPT('Patient ID:'),AT(10,10)
           ENTRY(@n10),AT(80,10,60,12),USE(PatientID)
           PROMPT('Full Name:'),AT(10,25)
           ENTRY(@s40),AT(80,25,150,12),USE(FullName)
           PROMPT('Gender:'),AT(10,40)
           LIST,AT(80,40,60,12),USE(Gender),DROP(5),FROM('Male|Female|Other')
           CHECK('Active Case'),AT(10,55),USE(IsActive)
           GROUP('Notes'),AT(10,75,280,100)
             ENTRY(@s255),AT(15,85,270,85),USE(Notes)
           END
           BUTTON('&Save'),AT(170,185,50,16),USE(?SaveBtn)
           BUTTON('&Close'),AT(230,185,50,16),USE(?CloseBtn)
         END

PatientID LONG
FullName  STRING(40)
Gender    STRING(10)
IsActive  BYTE
Notes     STRING(1000)

  CODE
  OPEN(ComplexWin)
  ACCEPT
  END
  CLOSE(ComplexWin)
