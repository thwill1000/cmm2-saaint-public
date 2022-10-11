' Write human-readable dump of adventure data files in ScottFree format.
' For Colour Maximite 2, MMBasic 5.07
' Copyright (c) 2020-2022 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley

Option Base 0
Option Default Integer
Option Explicit On

#Include "splib/system.inc"
#Include "splib/array.inc"
#Include "splib/bits.inc"
#Include "splib/list.inc"
#Include "splib/string.inc"
#Include "splib/file.inc"
#Include "splib/vt100.inc"
#Include "console.inc"
#Include "advent.inc"
#Include "metadata.inc"
#Include "catalogue.inc"
#Include "state.inc"
#Include "debug.inc"

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
        s$ = catalogue.find$(tokens$(i%))
        If s$ = "" Then Print "File not found: " + tokens$(i%) : End
        dump_file(s$, raw%)
    End Select
  Next
End Sub

Sub dump_all(raw%)
  Local count%
  Local t% = Timer
  Local f$ = file.find$(catalogue.DIR$, "*.dat", "File")
  Do While f$ <> ""
    Inc count%
    dump_file(f$, raw%)
    f$ = file.find$()
  Loop
  Print Str$(count%) " files written in " Str$((Timer - t%) / 1000) + " s"
End Sub

Sub dump_file(in$, raw%)
  Const fd% = 1
  Local out$ = file.trim_extension$(in$) + ".dmp"

  Print "Reading '" in$ "' ... ";
  advent.read_dat(in$)
  state.reset()
  Print "OK"
  Print "Writing '" out$ "' ... ";
  Open out$ For Output As #fd%
  If raw% Then dump_raw(fd%) Else dump(in$, fd%)
  Close #fd%
  Print "OK"
  advent.free()
End Sub

' Dumps adventure data in human-readable format.
Sub dump(f$, fd%)
  Print #fd%, "Data dump for '" f$ "'"
  Print #fd%
  Print #fd%, "Min text size (bytes):  " Str$(advent.txt_sz%)
  Print #fd%, "Max object index:       " Str$(il)
  Print #fd%, "Max action index:       " Str$(cl)
  Print #fd%, "Max vocabulary index:   " Str$(nl)
  Print #fd%, "Max room index:         " Str$(rl)
  Print #fd%, "Max objects carried:    " Str$(mx)
  Print #fd%, "Starting room index:    " Str$(ar)
  Print #fd%, "Number of treasures:    " Str$(tt)
  Print #fd%, "Vocabulary word length: " Str$(ln)
  Print #fd%, "Time limit:             " Str$(lt)
  Print #fd%, "Max message index:      " Str$(ml)
  Print #fd%, "Treasure room index:    " Str$(tr)
  Print #fd%

  debug.fd% = fd%
  debug.dump_actions()
  debug.println()
  debug.dump_vocabulary()
  debug.println()
  debug.dump_rooms()
  debug.println()
  debug.dump_messages()
  debug.println()
  debug.dump_objects()
End Sub

' Dumps adventure data in raw TRS-80 / ScottFree ".dat" format.
Sub dump_raw(fd%)
  Local i%, j%

  ' Header
  Print #fd%, Str$(advent.txt_sz%)
  Print #fd%, Str$(il)
  Print #fd%, Str$(cl)
  Print #fd%, Str$(nl)
  Print #fd%, Str$(rl)
  Print #fd%, Str$(mx)
  Print #fd%, Str$(ar)
  Print #fd%, Str$(tt)
  Print #fd%, Str$(ln)
  Print #fd%, Str$(lt)
  Print #fd%, Str$(ml)
  Print #fd%, Str$(tr)

  ' Action table
  For i% = 0 To cl
    For j% = 0 To 7
      Print #fd%, Str$(ca(i%, j%))
    Next j%
  Next i%

  ' Vocabulary
  For i% = 0 To nl
    Print #fd%, str.quote$(nv_str$(i%, 0))
    Print #fd%, str.quote$(nv_str$(i%, 1))
  Next

  ' Rooms
  For i% = 0 To rl
    For j% = 0 To 5
      Print #fd%, Str$(rm(i%, j%))
    Next j%
    Print #fd%, str.quote$(rs$(i%))
  Next i%

  ' Messages
  For i% = 0 To ml
    Print #fd%, str.quote$(ms$(i%))
  Next

  ' Objects
  For i% = 0 To il
    Print #fd%, str.quote$(ia_str$(i%)) " " Str$(i2(i%))
  Next
End Sub
