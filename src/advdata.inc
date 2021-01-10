' Scott Adams Adventure Game Interpreter for Colour Maximite 2
' Original TRS-80 Level II BASIC code (c) Scott Adams 1978
' MMBasic port for CMM2 by Thomas Hugo Williams 2020
' Modified to suit some found .dat files. Bill McKinley
' Each item of data is on a separate line so each one needs its own INPUT statement

Dim il ' Highest numbered object 0..il
Dim cl ' Highest action number 0..cl
Dim nl ' Highest vocabulary number 0..nl
Dim rl ' Highest room number 0..rl
Dim mx ' Maximum number of objects carried
Dim ar ' Starting room
Dim tt ' Number of treasures
Dim ln ' Word length
Dim lt ' Time limit
Dim ml ' Highest message number
Dim tr ' Treasure room

Dim As String temp, temp1, temp2, temp3
Dim flag As Integer
Dim crlf$ = Chr$(10) + Chr$(13)

Sub adv.read(f$)
  Open f$ For Input As 1
  Input #1, il ' read the first bit of data and disregard it.
  Input #1, il
  Input #1, cl
  Input #1, nl
  Input #1, rl
  Input #1, mx
  Input #1, ar
  Input #1, tt
  Input #1, ln
  Input #1, lt
  Input #1, ml
  Input #1, tr

  Dim ca(cl, 7)      ' action table
  Dim nv_str$(nl, 1) ' vocabulary table - verbs at index 0, nouns at index 1
  Dim ia_str$(il)    ' object descriptions
  Dim ia(il)         ' object locations
  Dim i2(il)         ' backup copy of object locations
  Dim rs$(rl)        ' room descriptions
  Dim rm(rl, 5)      ' room exits: N, S, E, W, U, D
  Dim ms$(ml)        ' messages table

  Local i, j
  ' Read action table.
  For i = 0 To cl
    For j = 0 To 7
      Input #1, ca(i, j)
    Next j
  Next i

  ' Read vocabulary table -Bill
  ' Revised because not all files have the vocab list in multiples of 2
  For i = 0 To nl
    For j = 0 To 1
      Input #1, nv_str$(i, j)
    Next j
  Next i

  ' Read rooms.
  For i = 0 To rl
    Input #1, rm(i, 0)
    Input #1, rm(i, 1)
    Input #1, rm(i, 2)
    Input #1, rm(i, 3)
    Input #1, rm(i, 4)
    Input #1, rm(i, 5)
    ' Room descriptions sometimes span multiple lines
    ' Need to remove leading and trailing quotes
    Line Input #1, rs$(i)
    If Left$(rs$(i), 1) = Chr$(34) Then rs$(i) = Right$(rs$(i), Len(rs$(i)) - 1)
    If Right$(rs$(i), 1) = Chr$(34) Then
      rs$(i) = Left$(rs$(i), Len(rs$(i)) - 1)
    Else
      temp = rs$(i)
      Line Input #1, rs$(i)
      temp = temp + crlf$ + rs$(i)
      If Right$(temp, 1) = Chr$(34) Then
        temp = Left$(temp, Len(temp) - 1) ' strip off the leading quote
      Else
        Line Input #1, rs$(i)
        temp = temp + crlf$ + rs$(i) ' concatenate the next line
        If Right$(temp, 1) = Chr$(34) Then
          temp = Left$(temp, Len(temp) - 1) ' sttip off the trailing quote
        Else
          Print "Error reading room data!"
          Print temp
          End
        EndIf
      EndIf
      rs$(i) = temp
    EndIf
  Next i

  ' Read messages and trim off any leading and trailing quotes
  ' some messages are spanning multiple lines so need to concatenate them
  flag = 0
  For i = 0 To ml : Line Input #1, ms$(i)
    If Left$(ms$(i), 1) = Chr$(34) Then ms$(i) = Right$(ms$(i), Len(ms$(i)) - 1)
    If Right$(ms$(i), 1) = Chr$(34) Then
      ms$(i) = Left$(ms$(i), Len(ms$(i)) - 1)
    Else
      temp = ms$(i)
      Line Input #1, ms$(i)
      If temp = "" Then ' some lines just contain a quote
        temp = temp + crlf$ + ms$(i)
      Else
        temp = temp + ms$(i)
      EndIf
      If Right$(temp, 1) = Chr$(34) Then
        temp = Left$(temp, Len(temp) - 1)
      Else
        Line Input #1, ms$(i)
        temp = temp + crlf$ + ms$(i)
        If Right$(temp, 1) = Chr$(34) Then
          temp = Left$(temp, Len(temp) - 1)
        Else
          j = 0
          Do
            Line Input #1, ms$(i)
            temp = temp + crlf$ + ms$(i)
            If Right$(temp, 1) = Chr$(34) Then
              temp = Left$(temp, Len(temp) - 1)
              flag = 1
            Else
              j = j + 1
            EndIf
          Loop Until flag = 1 Or j = 6
          If j = 6 Then Print " Error reading messages" : End
        EndIf
      EndIf
      ms$(i) = temp
    EndIf
  Next i

  ' Read objects, remove quotes and separate the location
  For i = 0 To il
    Line Input #1, ia_str$(i)
    temp = ia_str$(i)
    flag = 0
    For j = Len(temp) To 2 Step - 1
      If Mid$(temp, j, 1) = Chr$(34) Then
        flag = 1
        Exit For
      EndIf
    Next j
    If flag = 0 Then ' no quote
      Line Input #1, ia_str$(i)
      temp = temp + " " + ia_str$(i)
    EndIf

    For j = Len(temp) - 1 To 1 Step - 1
      temp3 = Mid$(temp, j, 1)
      If temp3 = " " Then
        temp1 = Left$(temp, j - 1)
        temp2 = Right$(temp, Len(temp) - j)
        Exit For
      EndIf
    Next j

    If Left$(temp1, 1) = Chr$(34) Then temp1 = Right$(temp1, Len(temp1) - 1) :
    If Right$(temp1, 1) = Chr$(34) Then temp1 = Left$(temp1, Len(temp1) - 1) :
    If temp1 = " " Then temp1 = ""
    ia_str$(i) = temp1
    ia(i) = Val(temp2)
    If ia(i) = 255 Then ia(i) = -1 ' Some files use 255 as -1 - Bill
    i2(i) = ia(i)
  Next i

  Close #1
End Sub
