' Scott Adams Adventure Game Interpreter
' For Colour Maximite 2, MMBasic 5.07
' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley
' Based on original TRS-80 Level II BASIC code (c) 1978 Scott Adams

Option Base 0
Option Default Integer
Option Explicit On

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/bits.inc"
#Include "splib/list.inc"
#Include "splib/map.inc"
#Include "splib/string.inc"
#Include "splib/txtwm.inc"
#Include "splib/file.inc"
#Include "splib/crypt.inc"
#Include "splib/inifile.inc"
#Include "splib/math.inc"
#Include "splib/vt100.inc"
#Include "advent.inc"
#Include "console.inc"
#Include "metadata.inc"
#Include "catalogue.inc"
#Include "menus.inc"
#Include "script.inc"
#Include "state.inc"
#Include "interp.inc"

Const SAAINT_VERSION$ = "2.0.4"
Const ROOT_DIR$ = file.get_canonical$(file.PROG_DIR$ + "/..")
Const TMP_DIR$ = ROOT_DIR$ + "/tmp"
Const INI_FILE$ = ROOT_DIR$ + "/saaint.ini"

con.HEIGHT = 33
con.WIDTH  = 80

Mode 2
main()
End

Sub main()
  file.mkdir(TMP_DIR$)
  read_inifile()

  ' Allow an adventure file to be specified at the command line.
  Local f$
  If str.trim$(Mm.CmdLine$) <> "" Then
    f$ = catalogue.find$(str.trim$(Mm.CmdLine$))
    If f$ = "" Then
      Print "File not found: " + str.trim$(Mm.CmdLine$)
      End
    Else
      Goto read_adventure
    EndIf
  EndIf

main_menu:

  f$ = map.get$(options$(), "current")
  If f$ <> "" Then f$ = catalogue.find$(str.trim$(f$))

  advent.free()

  Do
    Select Case menus.main$(f$)
      Case "#play"         : Goto read_adventure
      Case "#select"       : Goto select_adventure
      Case "#credits"      : menus.credits(1)
      Case "#instructions" : menus.instructions(1)
      Case "#quit"         : Goto quit
    End Select
  Loop

select_adventure:

  f$ = menus.choose_advent$()
  If f$ = "" Then Goto main_menu
  Cls
  f$ = catalogue.find$(f$)

read_adventure:

  advent.read_dat(f$)
  metadata.read_ext(f$)

adventure_menu:

  Do
    Select Case menus.adventure$()
      Case "#start"        : Goto new_game
      Case "#restore"      : Goto restore_game
      Case "#credits"      : menus.credits()
      Case "#instructions" : menus.instructions()
      Case "#back"         : Goto select_adventure
      Case "#quit"         : Goto quit
    End Select
  Loop

new_game:

  state.reset()
  Goto play_game

restore_game:

  If state.restore%() Then Goto play_game
  Pause 2000
  Goto adventure_menu

play_game:

  con.more = map.get$(options$(), "more") <> "0"
  seed_random_number_generator("option")
  write_inifile() ' Updates .ini file with the selected adventure.
  twm.enable_cursor(1)
  Cls
  game_loop()
  con.close_all()
  write_inifile() ' Updates .ini file with any options changed during play.
  If state <> STATE_QUIT Then Goto adventure_menu

quit:

  con.endl()
  con.println("Goodbye!", 1)
  con.close_all()
  Pause 2000

End Sub

' Reads contents of options$() map from .ini file.
Sub read_inifile()

  ' Backward compatibility: if the .ini file isn't present in "<saaint-root>"
  ' but it is present in "<saaint-root>/src" then move the latter to the former.
  If Not file.exists%(INI_FILE$) Then
    If file.exists%(ROOT_DIR$ + "/src/saaint.ini") Then
      Rename ROOT_DIR$ + "/src/saaint.ini" As INI_FILE$
    EndIf
  EndIf

  If file.exists%(INI_FILE$) Then
    Open INI_FILE$ For Input As #1
    Local ok% = inifile.read%(1, options$())
    Close #1
    If Not ok% Then Error "read_inifile: " + sys.err$
  EndIf

  Local s$

  s$ = map.get$(options$(), "current")
  If s$ = sys.NO_DATA$ Then map.put(options$(), "current", "")

  s$ = map.get$(options$(), "more")
  Select Case s$
    Case "0", "1" : ' the value is valid so do nothing.
    Case Else     : map.put(options$(), "more", "1")
  End Select

  s$ = map.get$(options$(), "prehistoric_lamp")
  Select Case s$
    Case "0", "1" : ' the value is valid so do nothing.
    Case Else     : map.put(options$(), "prehistoric_lamp", "1")
  End Select

  s$ = map.get$(options$(), "seed")
  ' If the value isn't a +ve integer then make it 0.
  If Str$(Int(Val(s$))) <> s$ Or Val(s$) < 0 Then map.put(options$(), "seed", "0")
End Sub

' Writes contents of options$() map to .ini file.
Sub write_inifile()
  map.put(options$(), "current", advent.file$)
  map.put(options$(), "more", Str$(con.more))
  ' We do not need to update the value of "seed" since the program never changes it.

  Open INI_FILE$ For Output As #1
  Local ok% = inifile.write%(1, options$())
  Close #1
  If Not ok% Then Error "write_inifile: " + sys.err$
End Sub
