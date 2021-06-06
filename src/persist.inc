' Implementation of Save/Restore and Record/Replay for SAAINT
' For Colour Maximite 2, MMBasic 5.07
' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "crypt", "advent")
sys.provides("persist")
If sys.err$ <> "" Then Error sys.err$

Const SAVE_DIR$   = fil.get_canonical$(fil.PROG_DIR$ + "/../saves")
Const SCRIPT_DIR$ = fil.get_canonical$(fil.PROG_DIR$ + "/../scripts")
Const persist.SCRIPT_FD_IN% = 2
Const persist.SCRIPT_FD_OUT% = 3

' Saves the current game state to a file.
' @return 1 on success, otherwise 0.
Function do_save()
  Local f$, i, game, s$

  con.println()
  con.println("Select saved game:")
  con.println()
  game = select_game()
  If game <> 0 Then f$ = save_file$(game)

  If game <> 0 And fil.exists%(f$) Then
    s$ = prompt$("Overwrite game " + Str$(game) + " [y|N]? ")
    If LCase$(s$) <> "y" Then game = 0
  EndIf

  If game <> 0 Then
    s$ = prompt$("Saved game name ? ")
    If s$ = "" Then game = 0
  EndIf

  If game = 0 Then con.println("Cancelled.") Exit Function

  con.println("Saving '" + f$ + "' ...")

  fil.mkdir(fil.get_parent$(f$))

  Open f$ For Output As #1

  ' Write file header
  Print #1, "SAAINT save file"
  Print #1, "2" ' file format version
  Print #1, Date$ + " " + Time$
  Print #1, s$

  ' Write state
  Print #1, "&b" Bin$(sf, 32)                            ' status flags
  Print #1, Str$(df)                                     ' dark flag
  Print #1, Str$(r)                                      ' current room
  Print #1, Str$(lx)                                     ' light duration
  For i = 0 To il : Print #1, Str$(ia(i)) : Next         ' object locations
  Print #1, Str$(counter)                                ' counter
  For i = 0 To 7 : Print #1, Str$(alt_counter(i)) : Next ' alternate counters
  For i = 0 To 5 : Print #1, Str$(alt_room(i)) : Next    ' alternate rooms

  Close #1

  do_save = 1
End Function

' Gets the path to the file corresponding to saved game slot 'i'.
Function save_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid saved game number"
  Local name$ = fil.trim_extension$(fil.get_name$(advent.file$))
  Local parent_name$ = fil.get_name$(fil.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  save_file$ = SAVE_DIR$ + "/" + parent_name$ + "/" + name$ + "_" + Str$(i) + ".sav"
End Function

' Restores game state from a file.
' @return 1 on success, otherwise 0.
Function do_restore()
  Local err$, f$, i, game, s$, values(19 + il)

  con.println()
  con.println("Select saved game to restore:")
  con.println()
  game = select_game()
  If game <> 0 Then f$ = save_file$(game)

  If game <> 0 Then
    If Not fil.exists%(f$) Then game = 0
  EndIf

  If game = 0 Then con.println("Cancelled.") : Exit Function

  Open f$ For Input As #1

  ' Read file header
  Line Input #1, s$
  Line Input #1, s$
  Line Input #1, s$
  Line Input #1, s$
  con.println("Restoring '" + s$ + "' ...")

  For i = 0 To 19 + il
    Line Input #1, s$
    If s$ = "" Then err$ = "missing data" : Exit For
    values(i) = Val(s$)
  Next i
  If Not Eof(#1) And err$ = "" Then err$ = "unexpected data"

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

    do_restore = 1
  Else
    con.println("Save file is invalid: " + err$)
  EndIf

  Close #1
End Function

' Prompts the user to select a saved game slot.
Function select_game()
  Local i, f$, s$(3) Length 64

  For i = 1 To 10
    f$ = save_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If fil.exists%(f$) Then
      Open f$ For Input As #1
      Line Input #1, s$(0) ' header
      Line Input #1, s$(1) ' version
      Line Input #1, s$(2) ' date/time
      Line Input #1, s$(3) ' game name
      Close #1
      ' TODO: verify header / version ?
      con.println(s$(2) + " - " + s$(3))
    Else
      con.println("Empty")
    EndIf
  Next i

  con.println()
  s$(0) = prompt$("Saved game number ? ")
  select_game = Val(s$(0))
  If select_game < 1 Or select_game > 10 Then select_game = 0

End Function

Sub record_on()
  Local f$, script, s$

  If con.fd_out <> 0 Then con.println("Already recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Cannot record whilst replaying script.") : Exit Sub

  con.println()
  con.println("Select script to record:")
  con.println()
  script = select_script()
  If script <> 0 Then f$ = script_file$(script)

  If script <> 0 And fil.exists%(f$) Then
    s$ = prompt$("Overwrite script " + Str$(script) + " [y|N]? ")
    If LCase$(s$) <> "y" Then script = 0
  EndIf

  If script <> 0 Then
    s$ = prompt$("Script name ? ")
    If s$ = "" Then script = 0
  EndIf

  If script = 0 Then con.println("Cancelled.") : Exit Sub

  con.println("Recording to '" + f$ + "' ...")

  fil.mkdir(fil.get_parent$(f$))

  con.open_out(2, f$)

  Print #2, "# " Date$ " " Time$
  Print #2, "# " s$

End Sub

' Prompts the user to select a script slot.
Function select_script()
  Local i, f$, s$

  For i = 1 To 10
    f$ = script_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If fil.exists%(f$) Then
      Open f$ For Input As #1
      Line Input #1, s$ ' date/time
      con.print(Mid$(s$, 3) + " - ")
      Line Input #1, s$ ' script name
      con.println(Mid$(s$, 3))
      Close #1
    Else
      con.println("Empty")
    EndIf
  Next i

  con.println()
  s$ = prompt$("Script number ? ")
  select_script = Val(s$)
  If select_script < 1 Or select_script > 10 Then select_script = 0

End Function

' Gets the path to the file corresponding to script slot 'i'.
Function script_file$(i)
  If i < 1 Or i > 10 Then Error "Invalid script number"
  Local name$ = fil.trim_extension$(fil.get_name$(advent.file$))
  Local parent_name$ = fil.get_name$(fil.get_parent$(advent.file$))
  If Right$(parent_name$, 1) = ":" Then
    parent_name$ = Left$(parent_name$, Len(parent_name$) - 1) + "-drive"
  EndIf
  script_file$ = SCRIPT_DIR$ + "/" + parent_name$ + "/" + name$ + "_" + Str$(i) + ".scr"
End Function

Sub record_off()
  If con.fd_out = 0 Then con.println("A script is not being recorded!") : Exit Sub
  con.close_out()
  con.println("Recording stopped.")
End Sub

Sub replay_on()
  Local f$, script, s$

  If con.fd_out <> 0 Then con.println("Cannot replay whilst recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Already replaying script.") : Exit Sub

  con.println()
  con.println("Select script to replay:")
  con.println()
  script = select_script()
  If script <> 0 Then f$ = script_file$(script)

  If script <> 0 Then
    If Not fil.exists%(f$) Then script = 0
  EndIf

  If script = 0 Then con.println("Cancelled.") : Exit Sub

  con.println("Replaying from '" + f$ + "' ...")

  con.open_in(3, f$)
End Sub

Sub replay_off()
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

  con.println()

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
