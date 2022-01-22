' Copyright (c) 2020-2022 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file provides subroutines to output debugging information.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "bits", "console", "state", "string")
sys.provides("debug")
If sys.err$ <> "" Then Error sys.err$

Dim debug.enabled%

Sub debug.dump_messages(nstr$)
  If nstr$ = "-1" Then
    con.println()
    con.println("MESSAGES")
    con.println("--------")
    con.println()
    Local i%
    For i% = 0 To ml : debug.dump_message(i%) : Next
    con.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > ml Then
      con.println("Invalid message index.")
    Else
      debug.dump_message(idx%)
    EndIf
  EndIf
End Sub

Sub debug.dump_message(idx%)
  Local s$ = ms$(idx%)
  If s$ = "" Then s$ = "<empty>"
  con.println(str.rpad$(Str$(idx%) + ":", 6) + s$)
End Sub

Sub debug.dump_objects(nstr$)
  If nstr$ = "-1" Then
    con.println()
    con.println("OBJECTS")
    con.println("-------")
    con.println("Id    Room")
    con.println()
    Local i%
    For i% = 0 To il : debug.dump_object(i%) : Next
    con.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > il Then
      con.println("Invalid object index.")
    Else
      debug.dump_object(idx%)
    EndIf
  EndIf
End Sub

Sub debug.dump_object(idx%)
  con.print(str.rpad$(Str$(idx%), 6))
  con.print(str.rpad$(Str$(state.obj_rm%(idx%)), 6))
  Local s$ = Choice(ia_str$(idx%) = "", "<empty>", ia_str$(idx%))
  Local p% = 1, q%
  Do While p% <= Len(s$)
    q% = InStr(p%, s$, sys.CRLF$)
    If q% Then
      con.println(Mid$(s$, p%, q% - p%))
      con.print("            ")
      p% = q% + 2
    Else
      con.println(Mid$(s$, p%))
      p% = 256
    EndIf
  Loop
End Sub

Sub debug.dump_rooms(nstr$)
  If nstr$ = "-1" Then
    con.println()
    con.println("ROOMS")
    con.println("-----")
    con.println()
    Local i%
    For i% = 0 To rl : debug.dump_room(i%) : Next
    con.println()
  Else
    Local idx% = Int(Val(nstr$))
    If idx% < 0 Or idx% > rl Then
      con.println("Invalid room index.")
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
  con.println(str.rpad$(Str$(idx%) + ":", 6) + s$)
  con.print("      Exits: ")
  Local count% = 0
  Local j%
  For j% = 0 To 5
    If rm(idx%, j%) > 0 Then
      Inc count%
      If count% > 1 Then con.print(", ")
      Select Case j%
        Case 0 : con.print("North")
        Case 1 : con.print("South")
        Case 2 : con.print("East")
        Case 3 : con.print("West")
        Case 4 : con.print("Up")
        Case 5 : con.print("Down")
      End Select
      con.print(" [" + Str$(rm(idx%, j%)) + "]")
    EndIf
  Next
  con.println(Choice(count% = 0, "None", ""))
End Sub

Sub debug.dump_state()
  con.println()
  con.println("GAME STATE")
  con.println("----------")
  con.println("Current room:          " + Str$(r))
  con.println("Dark flag:             " + Str$(bits.get%(sf, state.DARK_BIT%)))
  con.println("Remaining light:       " + Str$(lx))
  con.print("Set flags:             ")
  Local count%, i%
  For i% = 0 To 31
    If bits.get%(sf, i%) Then
      Inc count%
      If count% > 1 Then con.print(", ")
      con.print(Str$(i%))
    EndIf
  Next
  con.println()
  con.println("Counter:               " + Str$(counter))
  con.println("                       0,   1,   2,   3,   4,   5,   6,   7")
  con.print("Alternate counters: ")
  For i% = 0 To 7
    If i% > 0 Then con.print(",")
    con.print(Str$(alt_counter(i%), 4))
  Next
  con.println()
  con.print("Alternate rooms:    ")
  For i% = 0 To 5
    If i% > 0 Then con.print(",")
    con.print(Str$(alt_room(i%), 4))
  Next
  con.println()
End Sub

Sub debug.dump_vocabulary()
  con.println()
  con.println("VOCABULARY")
  con.println("----------")
  con.println("Id    Verb      Noun")
  con.println()

  Local i%, j%, s$, w$
  For i% = 0 To nl
    s$ = str.rpad$(Str$(i%), 6)
    For j% = 0 To 1
      w$ = Choice(nv_str$(i%, j%) = "", "<empty>", str.replace$(nv_str$(i%, j%), "*", "+"))
      Cat s$, Choice(j% = 0, str.rpad$(w$, 10), w$)
    Next
    con.println(s$)
  Next

  con.println()
End Sub
