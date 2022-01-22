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

Sub debug.dump_actions(nstr$, one_line%)
  Local i%
  If nstr$ = "-1" Then
    debug.println("ACTIONS")
    debug.println("-------")
    debug.println()
    For i% = 0 To cl : debug.dump_action(i%, one_line%) : Next
    debug.println()
  Else
    i% = Int(Val(nstr$))
    If i% < 0 Or i% > cl Then
      debug.println("Invalid action index.")
    Else
      debug.dump_action(i%)
    EndIf
  End If
End Sub

Sub debug.dump_action(idx%, one_line%)
  Local cmd%(3), cond%(4, 1), j%, noun%, n$, verb%, v$

  verb% = Int(ca(idx%, 0) / 150)
  noun% = ca(idx%, 0) - verb% * 150

  For j% = 0 To 4
    cond(j%, 1) = Int(ca(idx%, j% + 1) / 20)
    cond(j%, 0) = ca(idx%, j% + 1) - cond(j%, 1) * 20
  Next j

  cmd%(0) = Int(ca(idx%, 6) / 150)
  cmd%(1) = ca(idx%, 6) - cmd%(0) * 150
  cmd%(2) = Int(ca(idx%, 7) / 150)
  cmd%(3) = ca(idx%, 7) - cmd%(2) * 150

  If verb% = 0 Then
    n$ = Str$(noun%)
    v$ = Str$(verb%)
  Else
    n$ = debug.get_noun$(noun%)
    v$ = debug.get_verb$(verb%)
  EndIf

  debug.print(str.rpad$(Str$(idx%) + ":", 6))
  debug.print(str.rpad$(v$, 6))
  debug.print(str.rpad$(n$, 6))
  debug.print(str.rpad$(debug.get_cond$(cond%(0, 0), cond%(0, 1)), 9))
  debug.print(str.rpad$(debug.get_cond$(cond%(1, 0), cond%(1, 1)), 9))
  debug.print(str.rpad$(debug.get_cond$(cond%(2, 0), cond%(2, 1)), 9))
  debug.print(str.rpad$(debug.get_cond$(cond%(3, 0), cond%(3, 1)), 9))
  debug.print(str.rpad$(debug.get_cond$(cond%(4, 0), cond%(4, 1)), 9))
  If Not one_line% Then debug.println() : debug.print("                  ")
  debug.print(str.rpad$(debug.get_cmd$(cmd%(0)), 9))
  debug.print(str.rpad$(debug.get_cmd$(cmd%(1)), 9))
  debug.print(str.rpad$(debug.get_cmd$(cmd%(2)), 9))
  debug.println(debug.get_cmd$(cmd%(3)))
End Sub

Function debug.get_cond$(code%, num%)
  Local s$
  Select Case code%
    Case 0 : s$ = "Par"
    Case 1 : s$ = "HAS"
    Case 2 : s$ = "IN/W"
    Case 3 : s$ = "AVL"
    Case 4 : s$ = "IN"
    Case 5 : s$ = "-IN/W"
    Case 6 : s$ = "-HAVE"
    Case 7 : s$ = "-IN"
    Case 8 : s$ = "BIT"
    Case 9 : s$ = "-BIT"
    Case 10 : s$ = "ANY"
    Case 11 : s$ = "-ANY"
    Case 12 : s$ = "-AVL"
    Case 13 : s$ = "-RM0"
    Case 14 : s$ = "RM0"
    Case 15 : s$ = "CT<="
    Case 16 : s$ = "CT>"
    Case 17 : s$ = "ORIG"
    Case 18 : s$ = "-ORIG"
    Case 19 : s$ = "CT="
    Case Else : s$ = "<Unknown: " + Str$(code%) + ">"
  End Select
  debug.get_cond$ = s$ + " " + Str$(num%)
End Function

Function debug.get_verb$(v%)
  If v% > Bound(nv_str$(), 1) Then
    debug.println()
    debug.println("  WARNING: unknown verb " + Str$(v%))
    debug.get_verb$ = "<" + Str$(v%) + ">"
  Else
    debug.get_verb$ = nv_str$(v%, 0)
  EndIf
End Function

Function debug.get_noun$(n%)
  If n% > Bound(nv_str$(), 1) Then
    debug.println()
    debug.println("  WARNING: unknown noun" + Str$(n%))
    debug.get_noun$ = "<" + Str$(n%) + ">"
  Else
    debug.get_noun$ = nv_str$(n%, 1)
  EndIf
End Function

Function debug.get_cmd$(c%)
  Local s$
  Select Case c%
    Case 0 : s$ = "0"
    Case 1 To 51 : s$ = "MSG:" + Str$(c%)
    Case 52 : s$ = "GETx"
    Case 53 : s$ = "DROPx"
    Case 54 : s$ = "GOTOy"
    Case 55 : s$ = "x->RM0"
    Case 56 : s$ = "NIGHT"
    Case 57 : s$ = "DAY"
    Case 58 : s$ = "SETz"
    Case 59 : s$ = "x->RM0" ' same as 55
    Case 60 : s$ = "CLRz"
    Case 61 : s$ = "DEAD"
    Case 62 : s$ = "x->y"
    Case 63 : s$ = "FINI"
    Case 64 : s$ = "DspRM"
    Case 65 : s$ = "SCORE"
    Case 66 : s$ = "INV"
    Case 67 : s$ = "SET0"
    Case 68 : s$ = "CLR0"
    Case 69 : s$ = "FILL"
    Case 70 : s$ = "CLS"
    Case 71 : s$ = "SAVEz"
    Case 72 : s$ = "EXx,x"
    Case 73 : s$ = "CONT"
    Case 74 : s$ = "AGETx"
    Case 75 : s$ = "BYx<-x"
    Case 76 : s$ = "DspRM"
    Case 77 : s$ = "CT-1"
    Case 78 : s$ = "DspCT"
    Case 79 : s$ = "CT<-n"
    Case 80 : s$ = "EXRM0"
    Case 81 : s$ = "EXm,CT"
    Case 82 : s$ = "CT+n"
    Case 83 : s$ = "CT-n"
    Case 84 : s$ = "SAYw"
    Case 85 : s$ = "SAYwCR"
    Case 86 : s$ = "SAYCR"
    Case 87 : s$ = "EXc,CR"
    Case 88 : s$ = "DELAY"
    Case 102 To 149 : s$ = "MSG:" + Str$(c% - 50)
    Case Else : s$ = "<Unknown: " + Str$(c%) + ">"
  End Select
  debug.get_cmd$ = s$
End Function

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
