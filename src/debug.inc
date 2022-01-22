' Copyright (c) 2020-2022 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file provides subroutines to output debugging information.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "bits", "console", "state", "string")
sys.provides("debug")
If sys.err$ <> "" Then Error sys.err$

Dim debug.enabled%

Sub debug.print(s$)
  con.print(s$)
End Sub

Sub debug.println(s$)
  con.println(s$)
End Sub

Sub debug.dump_messages(nstr$)
  If nstr$ = "-1" Then
    debug.println()
    debug.println("MESSAGES")
    debug.println("--------")
    debug.println()
    Local i%
    For i% = 0 To ml : debug.dump_message(i%) : Next
    debug.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > ml Then
      debug.println("Invalid message index.")
    Else
      debug.dump_message(idx%)
    EndIf
  EndIf
End Sub

Sub debug.dump_message(idx%)
  Local s$ = ms$(idx%)
  If s$ = "" Then s$ = "<empty>"
  debug.println(str.rpad$(Str$(idx%) + ":", 6) + s$)
End Sub

Sub debug.dump_objects(nstr$)
  If nstr$ = "-1" Then
    debug.println()
    debug.println("OBJECTS")
    debug.println("-------")
    debug.println("Id    Room")
    debug.println()
    Local i%
    For i% = 0 To il : debug.dump_object(i%) : Next
    debug.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > il Then
      debug.println("Invalid object index.")
    Else
      debug.dump_object(idx%)
    EndIf
  EndIf
End Sub

Sub debug.dump_object(idx%)
  debug.print(str.rpad$(Str$(idx%), 6))
  debug.print(str.rpad$(Str$(state.obj_rm%(idx%)), 6))
  Local s$ = Choice(ia_str$(idx%) = "", "<empty>", ia_str$(idx%))
  Local p% = 1, q%
  Do While p% <= Len(s$)
    q% = InStr(p%, s$, sys.CRLF$)
    If q% Then
      debug.println(Mid$(s$, p%, q% - p%))
      debug.print("            ")
      p% = q% + 2
    Else
      debug.println(Mid$(s$, p%))
      p% = 256
    EndIf
  Loop
End Sub

Sub debug.dump_rooms(nstr$)
  If nstr$ = "-1" Then
    debug.println()
    debug.println("ROOMS")
    debug.println("-----")
    debug.println()
    Local i%
    For i% = 0 To rl : debug.dump_room(i%) : Next
    debug.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > rl Then
      debug.println("Invalid room index.")
    Else
      debug.dump_room(idx%)
    EndIf
  EndIf
End Sub

Sub debug.dump_room(idx%)
  Local s$ = rs$(idx%)
  If s$ = "" Then
    If idx% = 0 Then s$ = "<storeroom>" Else s$ = "<empty>"
  EndIf
  debug.println(str.rpad$(Str$(idx%) + ":", 6) + s$)
  debug.print("      Exits: ")
  Local count% = 0
  Local j%
  For j% = 0 To 5
    If rm(idx%, j%) > 0 Then
      Inc count%
      If count% > 1 Then debug.print(", ")
      Select Case j%
        Case 0 : debug.print("North")
        Case 1 : debug.print("South")
        Case 2 : debug.print("East")
        Case 3 : debug.print("West")
        Case 4 : debug.print("Up")
        Case 5 : debug.print("Down")
      End Select
      debug.print(" [" + Str$(rm(idx%, j%)) + "]")
    EndIf
  Next
  debug.println(Choice(count% = 0, "None", ""))
End Sub

Sub debug.dump_state()
  debug.println()
  debug.println("GAME STATE")
  debug.println("----------")
  debug.println("Current room:          " + Str$(r))
  debug.println("Dark flag:             " + Str$(bits.get%(sf, state.DARK_BIT%)))
  debug.println("Remaining light:       " + Str$(lx))
  debug.print("Set flags:             ")
  Local count%, i%
  For i% = 0 To 31
    If bits.get%(sf, i%) Then
      Inc count%
      If count% > 1 Then debug.print(", ")
      debug.print(Str$(i%))
    EndIf
  Next
  debug.println()
  debug.println("Counter:               " + Str$(counter))
  debug.println("                       0,   1,   2,   3,   4,   5,   6,   7")
  debug.print("Alternate counters: ")
  For i% = 0 To 7
    If i% > 0 Then debug.print(",")
    debug.print(Str$(alt_counter(i%), 4))
  Next
  debug.println()
  debug.print("Alternate rooms:    ")
  For i% = 0 To 5
    If i% > 0 Then debug.print(",")
    debug.print(Str$(alt_room(i%), 4))
  Next
  debug.println()
End Sub

Sub debug.dump_vocabulary()
  debug.println()
  debug.println("VOCABULARY")
  debug.println("----------")
  debug.println("Id    Verb      Noun")
  debug.println()

  Local i%, j%, s$, w$
  For i% = 0 To nl
    s$ = str.rpad$(Str$(i%), 6)
    For j% = 0 To 1
      w$ = Choice(nv_str$(i%, j%) = "", "<empty>", str.replace$(nv_str$(i%, j%), "*", "+"))
      Cat s$, Choice(j% = 0, str.rpad$(w$, 10), w$)
    Next
    debug.println(s$)
  Next

  debug.println()
End Sub
