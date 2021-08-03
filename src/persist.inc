' Implementation of Save/Restore and Record/Replay for SAAINT
' For Colour Maximite 2, MMBasic 5.07
' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "console", "crypt", "file")
sys.provides("persist")
If sys.err$ <> "" Then Error sys.err$

Const persist.SCRIPT_DIR$ = file.get_canonical$(file.PROG_DIR$ + "/../scripts")
Const persist.SCRIPT_FD_IN% = 2
Const persist.SCRIPT_FD_OUT% = 3

Sub persist.record_on()
  Local f$, s$

  If con.fd_out <> 0 Then con.println("Already recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Cannot record whilst replaying script.") : Exit Sub

  con.println()
  con.println("Select script to record:")
  con.println()
  Local script% = persist.select_script%()
  If script% <> 0 Then f$ = persist.script_file$(script%)

  If script% <> 0 And file.exists%(f$) Then
    s$ = prompt$("Overwrite script " + Str$(script%) + " [y|N]? ")
    If LCase$(s$) <> "y" Then script% = 0
  EndIf

  If script% <> 0 Then
    s$ = prompt$("Script name ? ")
    If s$ = "" Then script% = 0
  EndIf

  If script% = 0 Then con.println("Cancelled.") : Exit Sub

  con.println("Recording to '" + f$ + "' ...")

  file.mkdir(file.get_parent$(f$))

  Const fd_out% = persist.SCRIPT_FD_OUT%
  con.open_out(fd_out%, f$)
  Print #fd_out%, "# " Date$ " " Time$
  Print #fd_out%, "# " s$

End Sub

' Prompts the user to select a script slot.
Function persist.select_script%()
  Local i, f$, s$
  Const fd% = persist.SCRIPT_FD_IN%

  For i = 1 To 10
    f$ = persist.script_file$(i)
    con.print("  [" + Format$(i, "%2g") + "] ")
    If file.exists%(f$) Then
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
  Local name$ = file.trim_extension$(file.get_name$(advent.file$)) + "_" + Str$(i) + ".scr"
  Local parent_name$ = file.get_name$(file.get_parent$(advent.file$))
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
    If Not file.exists%(f$) Then script% = 0
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

  Local f_in$ = file.trim_extension$(advent.file$) + ".wlk"
  If Not file.exists%(f_in$) Then con.println("No walkthrough available.") : Exit Sub

  If con.fd_out <> 0 Then con.println("Cannot play walkthrough whilst recording script.") : Exit Sub
  If con.fd_in <> 0  Then con.println("Cannot play walkthrough whilst replaying script.") : Exit Sub

  ' Handle unencrypted walkthrough.
  If persist.is_unencrypted%(f_in$) Then
    con.open_in(persist.SCRIPT_FD_IN%, f_in$)
    Exit Sub
  EndIf

  ' Prompt for and hash password.
  Local password$ = prompt$("Password? ")
  If password$ = "" Then con.println("Cancelled.") : Exit Sub
  Local k%(array.new%(2))
  Local ok% = crypt.md5%(Peek(VarAddr password$) + 1, Len(password$), k%())
  If Not ok% Then con.println("Error: " + sys.err$) : Exit Sub

  ' Decrypt walkthough to "walkthrough.tmp"
  Local f_out$ = TMP_DIR$ + "/walkthrough.tmp"
  Const fd_in% = persist.SCRIPT_FD_IN%
  Const fd_out% = persist.SCRIPT_FD_OUT%
  Open f_in$ For Input As fd_in%
  Open f_out$ For Output As fd_out%
  ok% = crypt.xxtea_file%("decrypt", fd_in%, fd_out%, k%(), k%())
  Close fd_out%
  Close fd_in%

  ' If successful then start replaying the walkthrough script, otherwise report the problem.
  If Not ok% Then
    con.println("Error: " + sys.err$)
  ElseIf persist.is_unencrypted%(f_out$) Then
    con.open_in(persist.SCRIPT_FD_IN%, f_out$)
  Else
    con.println("Password incorrect!")
  EndIf

End Sub

' Is file 'f$' unencrypted ?
'
' @param  f$  the file in question.
' @return     1 if there are no non-printable, non-whitespace control codes in the first 255 bytes
'             of the file, otherwise 0.
Function persist.is_unencrypted%(f$)
  Const fd_in% = persist.SCRIPT_FD_IN%
  Open f$ For Input As fd_in%
  Local s$ = LCase$(Input$(255, #fd_in%))
  Close fd_in%
  persist.is_unencrypted% = str.is_plain_ascii%(s$)
End Function
