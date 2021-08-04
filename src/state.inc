' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' Current game state.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "console", "file", "string")
sys.provides("state")
If sys.err$ <> "" Then Error sys.err$

Const state.SAVE_DIR$ = file.get_canonical$(file.PROG_DIR$ + "/../saves")
Const state.FD% = 1
Const state.DARK_BIT% = 15 ' The status flag bit that is set when it is dark.

Dim lx               ' light duration
Dim r                ' current room
Dim sf               ' status flags
Dim counter          ' main counter
Dim alt_counter(7)   ' 8 alternate counters
Dim alt_room(5)      ' 6 alternate room registers
Dim state.obj_rm%(2) ' current object locations
                     ' - initialised with a dummy size, reset by state.reset()

Sub state.reset()
  r = ar  ' current room = starting room
  lx = lt ' light source starts full
  sf = 0  ' status flags are clear
  Erase state.obj_rm%
  Dim state.obj_rm%(il)
  Local i%
  For i% = 0 To il : state.obj_rm%(i%) = advent.obj_rm%(i%) : Next
End Sub

' Saves the current game state to a file.
'
' @return 1 on success, otherwise 0.
Function state.save%()
  Local f$, i, s$

  con.println()
  con.println("Select saved game:")
  con.println()
  Local game% = state.select_game%()
  If game% <> 0 Then
    f$ = state.save_file$(game%)
    If file.exists%(f$) Then
      s$ = prompt$("Overwrite game " + Str$(game%) + " [y|N]? ")
      If LCase$(s$) <> "y" Then game% = 0
    EndIf
  EndIf

  If game% <> 0 Then
    s$ = prompt$("Saved game name ? ")
    If s$ = "" Then game% = 0
  EndIf

  If game% = 0 Then con.println("Cancelled.") : Exit Function

  con.println("Saving '" + f$ + "' ...")

  file.mkdir(file.get_parent$(f$))

  Const fd% = state.FD%
  Open f$ For Output As #fd%

  ' Write file header
  Print #fd%, "SAAINT save file"
  Print #fd%, "2" ' file format version
  Print #fd%, Date$ + " " + Time$
  Print #fd%, s$

  ' Write state
  Print #fd%, "&b" Bin$(sf, 32)                            ' status flags
  Print #fd%, Str$((sf And 1 << state.DARK_BIT%) > 0)      ' dark flag, stored for historical
                                                           ' purposes as now synonymous with
                                                           ' status flag 15
  Print #fd%, Str$(r)                                      ' current room
  Print #fd%, Str$(lx)                                     ' light duration
  For i = 0 To il : Print #fd%, Str$(state.obj_rm%(i)) : Next ' object locations
  Print #fd%, Str$(counter)                                ' counter
  For i = 0 To 7 : Print #fd%, Str$(alt_counter(i)) : Next ' alternate counters
  For i = 0 To 5 : Print #fd%, Str$(alt_room(i)) : Next    ' alternate rooms

  Close #fd%

  state.save% = 1
End Function

' Gets the path to the file corresponding to saved game slot 'i'.
Function state.save_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid saved game number"
  Local name$ = file.trim_extension$(file.get_name$(advent.file$)) + "_" + Str$(i) + ".sav"
  Local parent_name$ = file.get_name$(file.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  state.save_file$ = state.SAVE_DIR$ + "/" + parent_name$ + "/" + name$
End Function

' Restores game state from a file.
'
' @return 1 on success, otherwise 0.
Function state.restore%()
  Local err$, f$, i, s$, values(19 + il)

  con.println()
  con.println("Select saved game to restore:")
  con.println()
  Local game% = state.select_game%()
  If game% <> 0 Then
    f$ = state.save_file$(game%)
    If Not file.exists%(f$) Then game% = 0
  EndIf

  If game% = 0 Then con.println("Cancelled.") : Exit Function

  Const fd% = state.FD%
  Open f$ For Input As #fd%

  ' Read file header
  Line Input #fd%, s$
  Line Input #fd%, s$
  Line Input #fd%, s$
  Line Input #fd%, s$
  con.println("Restoring '" + s$ + "' ...")

  For i = 0 To 19 + il
    Line Input #fd%, s$
    If s$ = "" Then err$ = "missing data" : Exit For
    values(i) = Val(s$)
  Next i
  If Not Eof(#fd%) And err$ = "" Then err$ = "unexpected data"

  If err$ = "" Then
    ' Update game state with values read from file.
    sf = values(0)

    ' Historically we saved a "dark flag" which is synonymous with status flag 15.
    If values(1) Then
      sf = sf Or 1 << state.DARK_BIT%
    Else
      sf = sf And Inv (1 << state.DARK_BIT%)
    EndIf

    r  = values(2)
    lx = values(3)
    Erase state.obj_rm%()
    Dim state.obj_rm%(il)
    For i = 4 To il + 4 : state.obj_rm%(i - 4) = values(i) : Next
    counter = values(il + 5)
    For i = il + 6 To il + 13 : alt_counter(i - il - 6) = values(i) : Next
    For i = il + 14 To il + 19 : alt_room(i - il - 14) = values(i) : Next

    state.restore% = 1
  Else
    con.println("Save file is invalid: " + err$)
  EndIf

  Close #fd%
End Function

' Prompts the user to select a saved game slot.
Function state.select_game%()
  Local i, f$, s$(3) Length 64
  Const fd% = state.FD%

  For i = 1 To 10
    f$ = state.save_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If file.exists%(f$) Then
      Open f$ For Input As fd%
      Line Input #fd%, s$(0) ' header
      Line Input #fd%, s$(1) ' version
      Line Input #fd%, s$(2) ' date/time
      Line Input #fd%, s$(3) ' game name
      Close #fd%
      ' TODO: verify header / version ?
      con.println(s$(2) + " - " + s$(3))
    Else
      con.println("Empty")
    EndIf
  Next i

  con.println()
  s$(0) = prompt$("Saved game number ? ")
  Local game% = Val(s$(0))
  If game% < 1 Or game% > 10 Then game% = 0
  state.select_game% = game%

End Function
