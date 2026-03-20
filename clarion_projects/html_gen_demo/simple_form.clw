  PROGRAM
  MAP
  END

Window WINDOW('Simple Form'),AT(,,200,100),CENTER,GRAY
       PROMPT('Name:'),AT(10,10)
       ENTRY(@s20),AT(40,10,100,12),USE(NameVar)
       BUTTON('OK'),AT(50,50,40,14),USE(?OkBtn)
       BUTTON('Cancel'),AT(100,50,40,14),USE(?CancelBtn)
     END

NameVar STRING(20)

  CODE
  OPEN(Window)
  ACCEPT
    CASE ACCEPTED()
    OF ?OkBtn
      BREAK
    OF ?CancelBtn
      BREAK
    END
  END
  CLOSE(Window)
