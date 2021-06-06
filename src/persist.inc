' Implementation of Save/Restore and Record/Replay for SAAINT
' For Colour Maximite 2, MMBasic 5.07
' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "crypt", "advent")
sys.provides("persist")
If sys.err$ <> "" Then Error sys.err$

Const persist.SAVE_DIR$ = fil.get_canonical$(fil.PROG_DIR$ + "/../saves")
Const persist.SCRIPT_DIR$ = fil.get_canonical$(fil.PROG_DIR$ + "/../scripts")
Const persist.FD% = 1
Const persist.SCRIPT_FD_IN% = 2
Const persist.SCRIPT_FD_OUT% = 3

' Saves the current game state to a file.
'
' @return 1 on success, otherwise 0.
Function persist.save%()
  Local f$, i, s$

  con.println()
  con.println("Select saved game:")
  con.println()
  Local game% = persist.select_game%()
  If game% <> 0 Then
    f$ = persist.save_file$(game%)
    If fil.exists%(f$) Then
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

  fil.mkdir(fil.get_parent$(f$))

  Const fd% = persist.FD%
  Open f$ For Output As #fd%

  ' Write file header
  Print #fd%, "SAAINT save file"
  Print #fd%, "2" ' file format version
  Print #fd%, Date$ + " " + Time$
  Print #fd%, s$

  ' Write state
  Print #fd%, "&b" Bin$(sf, 32)                            ' status flags
  Print #fd%, Str$(df)                                     ' dark flag
  Print #fd%, Str$(r)                                      ' current room
  Print #fd%, Str$(lx)                                     ' light duration
  For i = 0 To il : Print #fd%, Str$(ia(i)) : Next         ' object locations
  Print #fd%, Str$(counter)                                ' counter
  For i = 0 To 7 : Print #fd%, Str$(alt_counter(i)) : Next ' alternate counters
  For i = 0 To 5 : Print #fd%, Str$(alt_room(i)) : Next    ' alternate rooms

  Close #fd%

  persist.save% = 1
End Function

' Gets the path to the file corresponding to saved game slot 'i'.
Function persist.save_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid saved game number"
  Local name$ = fil.trim_extension$(fil.get_name$(advent.file$)) + "_" + Str$(i) + ".sav"
  Local parent_name$ = fil.get_name$(fil.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  persist.save_file$ = persist.SAVE_DIR$ + "/" + parent_name$ + "/" + name$
End Function

' Restores game state from a file.
'
' @return 1 on success, otherwise 0.
Function persist.restore%()
  Local err$, f$, i, s$, values(19 + il)

  con.println()
  con.println("Select saved game to restore:")
  con.println()
  Local game% = persist.select_game%()
  If game% <> 0 Then
    f$ = persist.save_file$(game%)
    If Not fil.exists%(f$) Then game% = 0
  EndIf

  If game% = 0 Then con.println("Cancelled.") : Exit Function

  Const fd% = persist.FD%
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
    df = values(1)
    r  = values(2)
    lx = values(3)
    For i = 4 To il + 4 : ia(i - 4) = values(i) : Next
    counter = values(il + 5)
    For i = il + 6 To il + 13 : alt_counter(i - il - 6) = values(i) : Next
    For i = il + 14 To il + 19 : alt_room(i - il - 14) = values(i) : Next

    persist.restore% = 1
  Else
    con.println("Save file is invalid: " + err$)
  EndIf

  Close #fd%
End Function

' Prompts the user to select a saved game slot.
Function persist.select_game%()
  Local i, f$, s$(3) Length 64
  Const fd% = persist.FD%

  For i = 1 To 10
    f$ = persist.save_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If fil.exists%(f$) Then
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
  persist.select_game% = game%

End Function

Sub persist.record_on()
  Local f$, s$

  If con.fd_out <> 0 Then con.println("Already recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Cannot record whilst replaying script.") : Exit Sub

  con.println()
  con.println("Select script to record:")
  con.println()
  Local script% = persist.select_script%()
  If script% <> 0 Then f$ = persist.script_file$(script%)

  If script% <> 0 And fil.exists%(f$) Then
    s$ = prompt$("Overwrite script " + Str$(script%) + " [y|N]? ")
    If LCase$(s$) <> "y" Then script% = 0
  EndIf

  If script% <> 0 Then
    s$ = prompt$("Script name ? ")
    If s$ = "" Then script% = 0
  EndIf

  If script% = 0 Then con.println("Cancelled.") : Exit Sub

  con.println("Recording to '" + f$ + "' ...")

  fil.mkdir(fil.get_parent$(f$))

  Const fd_out% = persist.SCRIPT_FD_OUT%
  con.open_out(fd_out%, f$)
  Print #fd_out%, "# " Date$ " " Time$
  Print #fd_out%, "# " s$

End Sub

' Prompts the user to select a script slot.
Function persist.select_script%()
  Local i, f$, s$
  Const fd% = persist.FD%

  For i = 1 To 10
    f$ = persist.script_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If fil.exists%(f$) Then
      Open f$ For Input As #fd%
      Line Input #fd%, s$ ' date/time
      con.print(Mid$(s$, 3) + " - ")
      Line Input #fd%, s$ ' script name
      con.println(Mid$(s$, 3))
      Close #fd%
    Else
      con.println("Empty")
    EndIf
  Next i

  con.println()
  s$ = prompt$("Script number ? ")
  Local script% = Val(s$)
  If script% < 1 Or script% > 10 Then script% = 0
  persist.select_script% = script%

End Function

' Gets the path to the file corresponding to script slot 'i'.
Function persist.script_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid script number"
  Local name$ = fil.trim_extension$(fil.get_name$(advent.file$)) + "_" + Str$(i) + ".scr"
  Local parent_name$ = fil.get_name$(fil.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  persist.script_file$ = persist.SCRIPT_DIR$ + "/" + parent_name$ + "/" + name$
End Function

Sub persist.record_off()
  If con.fd_out = 0 Then con.println("A script is not being recorded!") : Exit Sub
  con.close_out()
  con.println("Recording stopped.")
End Sub

Sub persist.replay_on()
  If con.fd_out <> 0 Then con.println("Cannot replay whilst recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Already replaying script.") : Exit Sub

  con.println()
  con.println("Select script to replay:")
  con.println()
  Local script% = persist.select_script%()
  If script% <> 0 Then
    Local f$ = persist.script_file$(script%)
    If Not fil.exists%(f$) Then script% = 0
  EndIf

  If script% = 0 Then con.println("Cancelled.") : Exit Sub

  con.println("Replaying from '" + f$ + "' ...")

  con.open_in(persist.SCRIPT_FD_IN%, f$)
End Sub

Sub persist.replay_off()
  If con.fd_in = 0 Then con.println("A script is not being replayed!") : Exit Sub
  con.close_in()
  con.println("Replaying stopped.")
End Sub

' Replays the walkthrough file (.wlk) for the current adventure.
Sub persist.walkthrough()

  Local f_in$ = fil.trim_extension$(advent.file$) + ".wlk"
  If Not fil.exists%(f_in$) Then con.println("No walkthrough available.") : Exit Sub

  If con.fd_out <> 0 Then con.println("Cannot play walkthrough whilst recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Cannot play walkthrough whilst replaying script.") : Exit Sub

  ' Prompt for and hash password.
  Local password$ = con.in$("Password? ")
  If password$ = "" Then con.println("Cancelled.") : Exit Sub
  Local k%(array.new%(2))
  Local ok% = crypt.md5%(Peek(VarAddr password$) + 1, Len(password$), k%())
  If Not ok% Then con.println("Error: " + sys.err$) : Exit Sub

  ' Decrypt walkthough to "walkthrough.tmp"
  Local f_out$ = fil.PROG_DIR$ + "/walkthrough.tmp"
  Const fd_in% = persist.SCRIPT_FD_IN%
  Const fd_out% = persist.SCRIPT_FD_OUT%
  Open f_in$ For Input As fd_in%
  Open f_out$ For Output As fd_out%
  ok% = crypt.xxtea_file%("decrypt", fd_in%, fd_out%, k%(), k%())
  Close fd_out%
  Close fd_in%
  If Not ok% Then con.println("Error: " + sys.err$) : Exit Sub

  ' Check for the text "walkthrough" in the first 255 characters,
  ' if not present then password incorrect.
  Open f_out$ For Input As fd_in%
  Local s$ = LCase$(Input$(255, #fd_in%))
  Close fd_in%
  If InStr(s$, "walkthrough") < 1 Then con.println("Password incorrect!") : Exit Sub

  ' Start replaying the walkthrough script.
  con.open_in(persist.SCRIPT_FD_IN%, f_out$)
End Sub
