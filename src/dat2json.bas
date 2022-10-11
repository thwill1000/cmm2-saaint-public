' Write adventure data files in JSON format.
' Copyright (c) 2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.05

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

json.init()
main()
End

Sub main()
  Local i%, s$, tokens$(list.new%(10)) Length 128
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
      Case "*"
        write_all()
      Case Else
        s$ = catalogue.find$(tokens$(i%))
        If s$ = "" Then Print "File not found: " + tokens$(i%) : End
        write_file(s$)
    End Select
  Next
End Sub

Sub write_all()
  Const out$ = "all_adventures.json"
  Const fd% = 2
  Local count%
  Local t% = Timer
  Print "Writing '" out$ "' ... "
  Open out$ For Output As #fd%

  json.write_document_start(fd%)
  json.write_array_start(fd%, "adventures")

  Local f$ = file.find$(catalogue.DIR$, "*.dat", "File")
  Do While f$ <> ""
    Inc count%
    Print "Reading '" f$ "' ... ";
    advent.read_dat(f$)
    state.reset()
    Print "OK"
    Print "Writing ... ";
    write_adventure(f$, fd%)
    Print "OK"
    advent.free()
    f$ = file.find$()
  Loop

  json.write_array_end(fd%)
  json.write_document_end(fd%)

  Close #fd%
  Print Str$(count%) " files written in " Str$((Timer - t%) / 1000) + " s"
End Sub

Sub write_file(in$)
  Const fd% = 1
  Local out$ = file.trim_extension$(in$) + ".json"

  Print "Reading '" in$ "' ... ";
  advent.read_dat(in$)
  state.reset()
  Print "OK"
  Print "Writing '" out$ "' ... ";
  Open out$ For Output As #fd%
  json.write_document_start(fd%)
  json.write_array_start(fd%, "adventures")
  write_adventure(in$, fd%)
  json.write_array_end(fd%)
  json.write_document_end(fd%)
  Close #fd%
  Print "OK"
  advent.free()
End Sub

Sub write_adventure(f$, fd%)
  json.write_object_start(fd%)
  Local filename$ = Mid$(f$, InStr(f$, "adventures/") + 11)
  json.write_string(fd%, "filename", filename$)
  write_header(fd%)
  write_actions(fd%)
  write_verbs(fd%)
  write_nouns(fd%)
  write_rooms(fd%)
  write_objects(fd%)
  write_messages(fd%)
  json.write_object_end(fd%)
End Sub

Sub write_header(fd%)
  json.write_object_start(fd%, "header")
  json.write_int(fd%, "minTextSize", advent.txt_sz%)
  json.write_int(fd%, "maxObjectIndex", il)
  json.write_int(fd%, "maxActionIndex", cl)
  json.write_int(fd%, "maxVocabIndex", nl)
  json.write_int(fd%, "maxRoomIndex", rl)
  json.write_int(fd%, "maxObjectsCarried", mx)
  json.write_int(fd%, "startRoomIndex", ar)
  json.write_int(fd%, "numTreasures", tt)
  json.write_int(fd%, "vocabWordLength", ln)
  json.write_int(fd%, "timeLimit", lt)
  json.write_int(fd%, "maxMessageIndex", ml)
  json.write_int(fd%, "treasureRoomIndex", tr)
  json.write_object_end(fd%)
End Sub

Sub write_actions(fd%)
  json.write_array_start(fd%, "actions")

  Local i%
  For i% = 0 To cl
    write_action(fd%, i%)
  Next

  json.write_array_end(fd%)
End Sub

Sub write_action(fd%, idx%)
  json.write_object_start(fd%)

  Local cmd%(3), cond%(4, 1), i%, noun%, n$, verb%, v$

  verb% = Int(ca(idx%, 0) / 150)
  noun% = ca(idx%, 0) - verb% * 150

  For i% = 0 To 4
    cond(i%, 1) = Int(ca(idx%, i% + 1) / 20)
    cond(i%, 0) = ca(idx%, i% + 1) - cond(i%, 1) * 20
  Next i%

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

  json.write_string(fd%, "verb", v$)
  json.write_string(fd%, "noun", n$)

  json.write_array_start(fd%, "conditions")
  For i% = 0 To 4
    json.write_string(fd%, "", debug.get_cond$(cond%(i%, 0), cond%(i%, 1)))
  Next
  json.write_array_end(fd%)

  json.write_array_start(fd%, "commands")
  For i% = 0 To 3
    json.write_string(fd%, "", debug.get_cmd$(cmd%(i%)))
  Next
  json.write_array_end(fd%)

  json.write_object_end(fd%)
End Sub

Sub write_verbs(fd%)
  json.write_array_start(fd%, "verbs")

  Local i%
  For i% = 0 To nl
    json.write_string(fd%, "", nv_str$(i%, 0))
  Next

  json.write_array_end(fd%)
End Sub

Sub write_nouns(fd%)
  json.write_array_start(fd%, "nouns")

  Local i%
  For i% = 0 To nl
    json.write_string(fd%, "", nv_str$(i%, 1))
  Next

  json.write_array_end(fd%)
End Sub

Sub write_rooms(fd%)
  json.write_array_start(fd%, "rooms")

  Local i%
  For i% = 0 To rl
    write_room(fd%, i%)
  Next

  json.write_array_end(fd%)
End Sub

Sub write_room(fd%, idx%)
  json.write_object_start(fd%)

  Local s$ = rs$(idx%)
  If s$ = "" Then
    If idx% = 0 Then s$ = "<storeroom>" Else s$ = "<empty>"
  EndIf
  s$ = str.replace$(s$, sys.CRLF$, "\n")

  json.write_string(fd%, "description", s$)
  json.write_int(fd%, "north", rm(idx%, 0))
  json.write_int(fd%, "south", rm(idx%, 1))
  json.write_int(fd%, "east",  rm(idx%, 2))
  json.write_int(fd%, "west",  rm(idx%, 3))
  json.write_int(fd%, "up",    rm(idx%, 4))
  json.write_int(fd%, "down",  rm(idx%, 5))
  
  json.write_object_end(fd%)
End Sub

Sub write_objects(fd%)
  json.write_array_start(fd%, "objects")

  Local i%
  For i% = 0 To il
    write_object(fd%, i%)
  Next

  json.write_array_end(fd%)
End Sub

Sub write_object(fd%, idx%)
  json.write_object_start(fd%)
  json.write_string(fd%, "description", str.replace$(ia_str$(idx%), sys.CRLF$, "\n"))
  json.write_int(fd%, "room", advent.obj_rm%(idx%))
  json.write_object_end(fd%)
End Sub

Sub write_messages(fd%)
  json.write_array_start(fd%, "messages")

  Local i%
  For i% = 0 To ml
    json.write_string(fd%, "", str.replace$(ms$(i%), sys.CRLF$, "\n"))
  Next

  json.write_array_end(fd%)
End Sub

Sub json.init()
  Dim json.comma% = 0
  Dim json.indent% = 0
End Sub

Sub json.write_document_start(fd%)
  Print #fd%, "{"
  Inc json.indent%
End Sub

Sub json.write_document_end(fd%)
  Print #fd%
  Print #fd%, "}"
  Inc json.indent%, -1
End Sub

Sub json.write_name(fd%, name$)
  If json.comma% Then Print #fd%, ","
  Print #fd%, Space$(json.indent% * 2);
  If Len(name$) <= 0 Then Exit Sub
  Print #fd%, Chr$(34) + name$ + Chr$(34) + " : ";
End Sub

Sub json.write_array_start(fd%, name$)
  json.write_name(fd%, name$)
  Print #fd%, "["
  Inc json.indent%
  json.comma% = 0
End Sub

Sub json.write_array_end(fd%)
  Inc json.indent%, -1
  Print #fd%
  Print #fd%, Space$(json.indent% * 2);
  Print #fd%, "]";
End Sub

Sub json.write_object_start(fd%, name$)
  json.write_name(fd%, name$)
  Print #fd%, "{"
  Inc json.indent%, 1
  json.comma% = 0
End Sub

Sub json.write_object_end(fd%)
  Inc json.indent%, -1
  Print #fd%
  Print #fd%, Space$(json.indent% * 2) + "}";
  json.comma% = 1
End Sub

Sub json.write_int(fd%, name$, value%)
  json.write_name(fd%, name$)
  Print #fd%, Str$(value%);
  json.comma% = 1
End Sub

Sub json.write_string(fd%, name$, value$)
  json.write_name(fd%, name$)
  Print #fd%, Chr$(34) + value$ + Chr$(34);
  json.comma% = 1
End Sub
