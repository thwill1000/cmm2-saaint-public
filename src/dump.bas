' Write human-readable dump of adventure data files in ScottFree format.
' For Colour Maximite 2, MMBasic 5.06
' Copyright (c) 2020-2021 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley

Option Explicit On
Option Default Integer

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "advent.inc"

main()
End

Sub main()
  Local i%, raw%, s$, tokens$(list.new%(10)) Length 128
  list.init(tokens$())

  s$ = str.unquote$(str.next_token$(Mm.CmdLine$, " ", 1))
  Do While s$ <> sys.NO_DATA$
    If list.size%(tokens$()) = list.capacity%(tokens$()) Then
      Error "too many command-line arguments"
    EndIf
    list.add(tokens$(), s$)
    s$ = str.unquote$(str.next_token$())
  Loop
  If list.size%(tokens$()) = 0 Then Error "no file arguments"

  For i% = 0 To list.size%(tokens$()) - 1
    Select Case LCase$(tokens$(i%))
      Case "-r", "--raw"
        If list.size%(tokens$()) = 1 Then Error "no file arguments"
        raw% = 1
      Case "*"
        dump_all(raw%)
      Case Else
        dump_file(advent.find$(tokens$(i%)), raw%)
    End Select
  Next
End Sub

Sub dump_all(raw%)
  Local count%
  Local t% = Timer
  Local f$ = fil.find$(advent.DIR$, "*.dat", "File")
  Do While f$ <> ""
    Inc count%
    dump_file(f$, raw%)
    f$ = fil.find$()
  Loop
  Print Str$(count%) " files written in " Str$((Timer - t%) / 1000) + " s"
End Sub

Sub dump_file(in$, raw%)
  Const fd = 1
  Local out$ = fil.trim_extension$(in$) + ".dmp"

  Print "Reading '" in$ "' ... ";
  advent.read(in$)
  Print "OK"
  Print "Writing '" out$ "' ... ";
  Open out$ For Output As #fd
  If raw% Then dump_raw(fd) Else dump(in$, fd)
  Close #fd
  Print "OK"
  advent.free()
End Sub

' Dumps adventure data in human-readable format.
Sub dump(f$, fd)
  Print #fd, "Data dump for '" f$ "'"
  Print #fd
  Print #fd, "Min text size (bytes):  " Str$(advent.txt_sz%)
  Print #fd, "Max object index:       " Str$(il)
  Print #fd, "Max action index:       " Str$(cl)
  Print #fd, "Max vocabulary index:   " Str$(nl)
  Print #fd, "Max room index:         " Str$(rl)
  Print #fd, "Max objects carried:    " Str$(mx)
  Print #fd, "Starting room index:    " Str$(ar)
  Print #fd, "Number of treasures:    " Str$(tt)
  Print #fd, "Vocabulary word length: " Str$(ln)
  Print #fd, "Time limit:             " Str$(lt)
  Print #fd, "Max message index:      " Str$(ml)
  Print #fd, "Treasure room index:    " Str$(tr)
  Print #fd

  dump_actions(fd)
  Print #fd
  dump_vocab(fd)
  Print #fd
  dump_rooms(fd)
  Print #fd
  dump_messages(fd)
  Print #fd
  dump_objects(fd)
End Sub

Sub dump_actions(fd)
  Local i

  Print #fd, "ACTIONS"
  Print #fd, "-------"
  Print #fd

  For i = 0 To cl
    dump_action(fd, i)
  Next i
End Sub

Sub dump_action(fd, i)
  Local cmd(3), cond(4, 1), j, noun, n$, verb, v$

  verb = Int(ca(i, 0) / 150)
  noun = ca(i, 0) - verb * 150

  For j = 0 To 4
    cond(j, 1) = Int(ca(i, j + 1) / 20)
    cond(j, 0) = ca(i, j + 1) - cond(j, 1) * 20
  Next j

  cmd(0) = Int(ca(i, 6) / 150)
  cmd(1) = ca(i, 6) - cmd(0) * 150
  cmd(2) = Int(ca(i, 7) / 150)
  cmd(3) = ca(i, 7) - cmd(2) * 150

  If verb = 0 Then
    n$ = Str$(noun)
    v$ = Str$(verb)
  Else
    n$ = get_noun$(noun)
    v$ = get_verb$(verb)
  EndIf

  Print #fd, str.rpad$(Str$(i) + ":", 6);
  Print #fd, str.rpad$(v$, 6);
  Print #fd, str.rpad$(n$, 6);
  Print #fd, str.rpad$(get_cond$(cond(0, 0), cond(0, 1)), 9);
  Print #fd, str.rpad$(get_cond$(cond(1, 0), cond(1, 1)), 9);
  Print #fd, str.rpad$(get_cond$(cond(2, 0), cond(2, 1)), 9);
  Print #fd, str.rpad$(get_cond$(cond(3, 0), cond(3, 1)), 9);
  Print #fd, str.rpad$(get_cond$(cond(4, 0), cond(4, 1)), 9);
  Print #fd, str.rpad$(get_cmd$(cmd(0)), 8);
  Print #fd, str.rpad$(get_cmd$(cmd(1)), 8);
  Print #fd, str.rpad$(get_cmd$(cmd(2)), 8);
  Print #fd, get_cmd$(cmd(3));
  Print #fd
End Sub

Function get_cond$(code, num)
  Local s$
  Select Case code
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
    Case Else : s$ = "<Unknown: " + Str$(code) + ">"
  End Select
  get_cond$ = s$ + " " + Str$(num)
End Function

Function get_verb$(v)
  If v > Bound(nv_str$(), 1) Then
    Print
    Print "  WARNING: unknown verb" v
    get_verb$ = "<" + Str$(v) + ">"
  Else
    get_verb$ = nv_str$(v, 0)
  EndIf
End Function

Function get_noun$(n)
  If n > Bound(nv_str$(), 1) Then
    Print
    Print "  WARNING: unknown noun" n
    get_noun$ = "<" + Str$(n) + ">"
  Else
    get_noun$ = nv_str$(n, 1)
  EndIf
End Function

Function get_cmd$(c)
  Local s$
  Select Case c
    Case 0 : s$ = "0"
    Case 1 To 51 : s$ = "MSG:" + Str$(c)
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
    Case 102 To 149 : s$ = "MSG:" + Str$(c - 50)
    Case Else : s$ = "<Unknown: " + Str$(c) + ">"
  End Select
  get_cmd$ = s$
End Function

Sub dump_vocab(fd)
  Local i

  Print #fd, "VOCAB"
  Print #fd, "-----"
  Print #fd

  For i = 0 To nl
    Print #fd, str.rpad$(Str$(i) + ":", 6) str.rpad$(nv_str$(i, 0), ln + 3) nv_str$(i, 1)
  Next i
End Sub

Sub dump_rooms(fd)
  Local count, i, j, s$

  Print #fd, "ROOMS"
  Print #fd, "-----"
  Print #fd

  For i = 0 To rl
    s$ = rs$(i)
    If s$ = "" Then
      If i = 0 Then s$ = "<storeroom>" Else s$ = "<empty>"
    EndIf
    Print #fd, str.rpad$(Str$(i) + ":", 6) s$
    Print #fd, "      Exits: ";
    count = 0
    For j = 0 To 5
      If rm(i, j) > 0 Then
        count = count + 1
        If count > 1 Then Print #fd, ", ";
        Select Case j
          Case 0 : Print #fd, "North";
          Case 1 : Print #fd, "South";
          Case 2 : Print #fd, "East";
          Case 3 : Print #fd, "West";
          Case 4 : Print #fd, "Up";
          Case 5 : Print #fd, "Down";
        End Select
      EndIf
    Next j
    If count = 0 Then Print #fd, "None" Else Print #fd
  Next i
End Sub

Sub dump_messages(fd)
  Local i, s$

  Print #fd, "MESSAGES"
  Print #fd, "--------"
  Print #fd

  For i = 0 To ml
    s$ = ms$(i)
    If s$ = "" Then s$ = "<empty>"
    Print #fd, str.rpad$(Str$(i) + ":", 6) s$
  Next i
End Sub

Sub dump_objects(fd)
  Local i, s$

  Print #fd, "OBJECTS"
  Print #fd, "--------"
  Print #fd, "No    Rm" ' Added this - Bill
  Print #fd

  For i = 0 To il
    s$ = ia_str$(i)
    If s$ = "" Then s$ = "<empty>"
    Print #fd, str.rpad$(Str$(i) + ":", 6) str.rpad$(Str$(ia(i)), 6) s$
  Next i
End Sub

' Dumps adventure data in raw TRS-80 / ScottFree ".dat" format.
Sub dump_raw(fd)
  Local i%, j%

  ' Header
  Print #fd, Str$(advent.txt_sz%)
  Print #fd, Str$(il)
  Print #fd, Str$(cl)
  Print #fd, Str$(nl)
  Print #fd, Str$(rl)
  Print #fd, Str$(mx)
  Print #fd, Str$(ar)
  Print #fd, Str$(tt)
  Print #fd, Str$(ln)
  Print #fd, Str$(lt)
  Print #fd, Str$(ml)
  Print #fd, Str$(tr)

  ' Action table
  For i% = 0 To cl
    For j% = 0 To 7
      Print #fd, Str$(ca(i%, j%))
    Next j%
  Next i%

  ' Vocabulary
  For i% = 0 To nl
    Print #fd, str.quote$(nv_str$(i%, 0))
    Print #fd, str.quote$(nv_str$(i%, 1))
  Next

  ' Rooms
  For i% = 0 To rl
    For j% = 0 To 5
      Print #fd, Str$(rm(i%, j%))
    Next j%
    Print #fd, str.quote$(rs$(i%))
  Next i%

  ' Messages
  For i% = 0 To ml
    Print #fd, str.quote$(ms$(i%))
  Next

  ' Objects
  For i% = 0 To il
    Print #fd, str.quote$(ia_str$(i%)) " " Str$(i2(i%))
  Next
End Sub
