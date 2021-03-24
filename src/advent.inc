' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley
' Based on original TRS-80 Level II BASIC code (c) 1978 Scott Adams
' For Colour Maximite 2, MMBasic 5.07

' This file declares the variables that hold the (read-only) adventure
' data/structure and contains the subroutines that fill those
' variables from '.dat' files in ScottFree format.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.provides("advent")
If sys.err$ <> "" Then Error sys.err$

Const advent.FD_IN% = 1

Dim advent.file$    ' Data file for the current adventure
Dim advent.buf$     ' 255 char buffer for reading adventure files
Dim advent.buf_ptr% ' Current position within the buffer

Dim advent.txt_sz% ' Minimum number of bytes required to contain all text (UNUSED)
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

' Reads a '.dat' file.
Sub advent.read_dat(f$)
  advent.free()
  advent.file$ = Choice(LCase$(fil.get_extension$(f$)) = ".dat", f$, f$ + ".dat")
  Open advent.file$ For Input As advent.FD_IN%
  advent.buf$ = ""
  advent.buf_ptr% = 1
  advent.read_header()
  advent.read_action_table()
  advent.read_vocab_table()
  advent.read_rooms()
  advent.read_messages()
  advent.read_objects()
  Close advent.FD_IN%
End Sub

Sub advent.read_header()
  advent.txt_sz% = advent.read_int%()
  il = advent.read_int%()
  cl = advent.read_int%()
  nl = advent.read_int%()
  rl = advent.read_int%()
  mx = advent.read_int%()
  ar = advent.read_int%()
  tt = advent.read_int%()
  ln = advent.read_int%()
  lt = advent.read_int%()
  ml = advent.read_int%()
  tr = advent.read_int%()

  Dim ca(cl, 7)      ' action table
  Dim nv_str$(nl, 1) ' vocabulary table - verbs at index 0, nouns at index 1
  Dim ia_str$(il)    ' object descriptions
  Dim ia(il)         ' object locations
  Dim i2(il)         ' backup copy of object locations
  Dim rs$(rl)        ' room descriptions
  Dim rm(rl, 5)      ' room exits: N, S, E, W, U, D
  Dim ms$(ml)        ' messages table
End Sub

Function advent.read_int%()
  Local ch%, s$

  ' Look for opening minus-sign or digit.
  Do
    ch% = advent.peek_char%()
    Select Case ch%
      Case 10, 13, 32
        Inc advent.buf_ptr%
      Case 45 ' minus sign
        s$ = "-"
        Inc advent.buf_ptr%
        Exit Do
      Case 48 To 57 ' digits
        Exit Do
      Case Else
        Error "looking for integer, found: " + Chr$(ch%)
    End Select
  Loop

  ' Accumulate digits.
  Do
    ch% = advent.peek_char%()
    Inc advent.buf_ptr%
    Select Case ch%
      Case 48 To 57 : Cat s$, Chr$(ch%)
      Case Else     : Exit Do
    End Select
  Loop

  advent.read_int% = Val(s$)
End Function

Function advent.peek_char%()
  If advent.buf_ptr% > Len(advent.buf$) Then
    advent.buf_ptr% = 1
    advent.buf$ = Input$(255, advent.FD_IN%)
  EndIf
  advent.peek_char% = Peek(Var advent.buf$, advent.buf_ptr%)
End Function

' Reads a quoted string that might be spread over several lines.
Function advent.read_string$()
  Local ch%, s$

  ' Look for opening quote.
  Do
    ch% = advent.peek_char%()
    Select Case ch%
      Case 10, 13, 32 ' line-feed, carriage-return and space
        Inc advent.buf_ptr%
      Case 34 ' double quotation mark
        Inc advent.buf_ptr%
        Exit Do
      Case Else
        Error "looking for opening-quote, found: " + Chr$(ch%)
    End Select
  Loop

  ' Accumulate string until find closing quote.
  Do
    ch% = advent.peek_char%()
    Inc advent.buf_ptr%
    Select Case ch%
      Case 10 ' \n - line feed
        Cat s$, sys.CRLF$
      Case 13 ' \r - carriage return
        If advent.peek_char%() <> 10 Then Cat s$, sys.CRLF$
      Case 34
        Exit Do
      Case Else
        Cat s$, Chr$(ch%)
    End Select
  Loop

  advent.read_string$ = s$
End Function

Sub advent.read_action_table()
  Local i, j
  For i = 0 To cl
    For j = 0 To 7
      ca(i, j) = advent.read_int%()
    Next j
  Next i
End Sub

Sub advent.read_vocab_table()
  Local i
  For i = 0 To nl
    nv_str$(i, 0) = advent.read_string$() ' verb
    nv_str$(i, 1) = advent.read_string$() ' noun
  Next
End Sub

Sub advent.read_rooms()
  Local i, j
  For i = 0 To rl
    For j = 0 To 5
      rm(i, j) = advent.read_int%()
    Next
    rs$(i) = advent.read_string$()
  Next
End Sub

Sub advent.read_messages()
  Local i
  For i = 0 To ml
    ms$(i) = advent.read_string$()
  Next
End Sub

Sub advent.read_objects()
  Local i
  For i = 0 To il
    ia_str$(i) = advent.read_string$()
    ia(i) = advent.read_int%()
    i2(i) = ia(i)
  Next
End Sub

Sub advent.free()

  ' If there are no objects then we assume no adventure has been loaded
  ' and there is thus nothing to clear.
  If il <= 0 Then Exit Sub

  advent.file$ = ""
  il = 0 : cl = 0 : nl = 0 : rl = 0 : mx = 0 : ar = 0
  tt = 0 : ln = 0 : lt = 0 : ml = 0 : tr = 0
  Erase ca, nv_str$, ia_str$, ia, i2, rs$, rm, ms$
End Sub
