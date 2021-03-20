' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "console", "file")
sys.provides("menus")
If sys.err$ <> "" Then Error sys.err$

Function menus.show_intro$()
  Local f$ = fil.trim_extension$(advent.file$) + ".tit"
  f$ = Choice(fil.exists%(f$), f$, fil.PROG_DIR$ + "/default.tit")

  Cls
  con.lines = 0
  Colour Rgb(White)
  con.print_file(f$, 1)
  Colour Rgb(Green)
  con.println()
  con.println("S  Start a new game           ", 1)
  con.println("R  Restore a saved game       ", 1)
  con.println("C  Show credits               ", 1)
  con.println("I  Instructions on how to play", 1)
  con.println("Q  Quit                       ", 1)
  con.println()
  con.println("Version 2.0a", 1)

  Do While Inkey$ <> "" : Loop
  Local k$
  Do
    k$ = LCase$(Inkey$)
    Select Case k$
      Case "s" : menus.show_intro$ = "#start"
      Case "r" : menus.show_intro$ = "#restore"
      Case "c" : menus.show_intro$ = "#credits"
      Case "i" : menus.show_intro$ = "#instructions"
      Case "q" : menus.show_intro$ = "#quit"
      Case Else : k$ = ""
    End Select
  Loop Until k$ <> ""

  con.lines = 0
End Function

Sub menus.show_credits()
  Local f$ = fil.trim_extension$(advent.file$) + ".cre"
  f$ = Choice(fil.exists%(f$), f$, fil.PROG_DIR$ + "/default.cre")

  Cls
  con.lines = 0
  Colour Rgb(White)
  con.println()
  con.println("CREDITS", 1)
  con.println("=======", 1)
  con.println()
  Colour Rgb(Green)
  con.print_file(f$, 1)
  con.println()
  Colour Rgb(White)
  con.println("Press any key to continue", 1)
  Colour Rgb(Green)
  Do While Inkey$ <> "" : Loop
  Do While Inkey$ = "" : Loop
End Sub

Sub menus.show_instructions()
  Local f$ = fil.trim_extension$(advent.file$) + ".ins"
  f$ = Choice(fil.exists%(f$), f$, fil.PROG_DIR$ + "/default.ins")

  Cls
  con.lines = 0
  Colour Rgb(White)
  con.println()
  con.println("HOW TO PLAY", 1)
  con.println("===========", 1)
  con.println()
  Colour Rgb(Green)
  con.print_file(f$, 1)
  con.println()
  Colour Rgb(White)
  con.println("Press any key to continue", 1)
  Colour Rgb(Green)
  Do While Inkey$ <> "" : Loop
  Do While Inkey$ = "" : Loop
End Sub
