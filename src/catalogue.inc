' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file contains functions for finding and listing '.dat' files.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "string", "metadata")
sys.provides("catalogue")
If sys.err$ <> "" Then Error sys.err$

Const catalogue.DIR$ = fil.PROG_DIR$ + "/../adventures"
Const catalogue.FD_IN% = 1

' Finds and returns the full path to a named adventure.
'
' @param   name$  the name of the adventure to find, the '.dat' extension will
'                 be appended if missing. Searches in the following order:
'                 - is 'name$' an absolute path or a path relative to the
'                   current working directory,
'                 - is 'name$' a path relative to the 'adventures/' directory,
'                 - is 'name$' a path relative to an immediate sub-directory of
'                   the 'adventures/' directory.
' @return  the file path, or an empty string if the adventure cannot be found.
Function catalogue.find$(name$)
  Local f$ = str.unquote$(str.trim$(name$))
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

  If Not fil.exists%(f$) Then f$ = ""

  catalogue.find$ = f$
End Function

' Fills a map of (adventure name -> filename) for all the adventures in the
' "adventures/" directory.
Sub catalogue.get_all(m$())
  Local dirs$(list.new%(10)) Length 64
  list.init(dirs$())
  list.add(dirs$(), ".")
  Local f$ = Dir$(catalogue.DIR$ + "/*", Dir)
  Do While f$ <> "" And Not list.is_full%(dirs$())
    list.add(dirs$(), f$)
    f$ = Dir$()
  Loop

  Local i%, lb% = 0, ub% = list.size%(dirs$()) - 1
  Local d$
  For i% = lb% To ub%
    d$ = catalogue.DIR$ + "/" + dirs$(i%) + "/"
    f$ = Dir$(d$ + "*.dat")
    Do While f$ <> "" And Not map.is_full%(m$())
      map.put(m$(), metadata.read_name$(d$ + f$), f$)
      f$ = Dir$()
    Loop
  Next
End Sub
