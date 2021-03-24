' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file contains functions for finding and listing '.dat' files.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "string")
sys.provides("catalogue")
If sys.err$ <> "" Then Error sys.err$

Const catalogue.DIR$ = fil.PROG_DIR$ + "/../adventures"
Const catalogue.FD_IN% = 1

Function catalogue.find$(f$)
  f$ = str.unquote$(str.trim$(f$))
  If LCase$(fil.get_extension$(f$)) <> ".dat" Then Cat f$, ".dat"

  ' Is f$ just a simple absolute or relative path to the file ?
  If fil.exists%(f$) Then
    ' Do nothing.

  ' Is f$ a path relative to catalogue.DIR$ ?
  ElseIf fil.exists%(catalogue.DIR$ + "/" + f$) Then
    f$ = catalogue.DIR$ +  "/" + f$

  ' Is f$ a path relative to a sub-directory of catalogue.DIR$ ?
  Else
    Local num_dirs% = fil.count_files%(catalogue.DIR$, "*", "Dir")
    Local all_dirs$(num_dirs% - 1) Length 128
    fil.get_files(catalogue.DIR$, "*", "Dir", all_dirs$())
    Local i%
    For i% = 0 To num_dirs% - 1
      If fil.exists%(catalogue.DIR$ + "/" + all_dirs$(i%) + "/" + f$) Then
        f$ = catalogue.DIR$ + "/" + all_dirs$(i%) + "/" + f$
        Exit For
      EndIf
    Next
  EndIf

  If Not fil.exists%(f$) Then Error "File not found: " + f$

  catalogue.find$ = f$
End Function

' Gets a map of (adventure name -> filename) for all the adventures in the
' "adventures/" directory.
Sub catalogue.get_all(m$())
  Local dirs$(list.new%(10)) Length 64
  list.init(dirs$())
  list.add(dirs$(), ".")
  Local f$ = Dir$(catalogue.DIR$ + "/*", Dir)
  Do While (f$ <> "") And (list.size%(dirs$()) <= list.capacity%(dirs$()))
    ' TODO: Add list.is_full%()
    ' What does list do if you add when full ?
    If list.size%(dirs$()) = list.capacity%(dirs$()) Then Exit Do
    list.add(dirs$(), f$)
    f$ = Dir$()
  Loop

  Local i%, lb% = 0, ub% = list.size%(dirs$()) - 1
  Local name$
  Local d$
  For i% = lb% To ub%
    d$ = catalogue.DIR$ + "/" + dirs$(i%) + "/"
    f$ = Dir$(d$ + "*.dat")
    Do While f$ <> ""
      ' TODO: Add map.is_full%()
      If map.size%(m$()) = map.capacity%(m$()) Then Exit Do
      name$ = fil.trim_extension$(f$)
      If fil.exists%(d$ + name$ + ".ext") Then
        Open d$ + name$ + ".ext" For Input As catalogue.FD_IN%
        Line Input #catalogue.FD_IN%, name$
        Close catalogue.FD_IN%
      Else
        name$ = UCase$(Left$(name$, 1)) + Mid$(name$, 2)
      EndIf
      map.put(m$(), name$, f$)
      f$ = Dir$()
    Loop
  Next
End Sub
