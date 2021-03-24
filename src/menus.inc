' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("catalogue", "console", "file", "map", "metadata", "txtwm")
sys.provides("menus")
If sys.err$ <> "" Then Error sys.err$

' This file contains functions to show the main, adventure selection
' and adventure specific menus as well as the credits and
' instructions.

Function menus.main$()
  Local f$ = fil.PROG_DIR$ + "/title.txt")

  Cls
  con.lines = 0
  Colour Rgb(White)
  con.print_file(f$, 1)
  Colour Rgb(Green)
  con.println()
  con.println("S  Select an adventure", 1)
  con.println("I  Instructions       ", 1)
  con.println("C  Credits & License  ", 1)
  con.println("Q  Quit               ", 1)
  con.println()
  con.println("Version 2.0a", 1)

  Do While Inkey$ <> "" : Loop
  Local k$
  Do
    k$ = LCase$(Inkey$)
    Select Case k$
      Case "c" : menus.main$ = "#credits"
      Case "i" : menus.main$ = "#instructions"
      Case "q" : menus.main$ = "#quit"
      Case "s" : menus.main$ = "#select"
      Case Else : k$ = ""
    End Select
  Loop Until k$ <> ""

  con.lines = 0
End Function

Function menus.adventure$()

  Cls
  con.lines = 0
  Colour Rgb(White)
  If metadata.title_file$ <> "" Then
    con.print_file(metadata.title_file$, 1)
  Else
    con.println()
    con.println(metadata.name$, 1)
  EndIf
  Colour Rgb(Green)
  con.println()
  con.println("S  Start a new game      ", 1)
  con.println("R  Restore a saved game  ", 1)
  con.println("I  Instructions          ", 1)
  If metadata.credits_file$ <> "" Then con.println("C  Credits & License      ", 1)
  con.println("B  Back to adventure list", 1)
  con.println("Q  Quit                  ", 1)

  Do While Inkey$ <> "" : Loop
  Local k$
  Do
    k$ = LCase$(Inkey$)
    Select Case k$
      Case "b" : menus.adventure$ = "#back"
      Case "c"
        If metadata.credits_file$ <> "" Then menus.adventure$ = "#credits" Else k$ = ""
      Case "i" : menus.adventure$ = "#instructions"
      Case "q" : menus.adventure$ = "#quit"
      Case "r" : menus.adventure$ = "#restore"
      Case "s" : menus.adventure$ = "#start"
      Case Else : k$ = ""
    End Select
  Loop Until k$ <> ""

  con.lines = 0
End Function

Sub menus.credits()
  Local f$ = metadata.credits_file$
  f$ = Choice(f$ <> "", f$, fil.PROG_DIR$ + "/credits.txt")

  Cls
  con.lines = 0
  Colour Rgb(White)
  con.println()
  con.println("CREDITS & LICENSE", 1)
  con.println("=================", 1)
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

Sub menus.instructions()
  Local f$ = metadata.instructions_file$
  f$ = Choice(f$ <> "", f$, fil.PROG_DIR$ + "/instructions.txt")

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

Function menus.choose_advent$()
  Local m$(map.new%(50)) Length 64
  map.init(m$())
  catalogue.get_all(m$())

  Const MENU_WIDTH% = Int(con.WIDTH / 2) - 4
  Const MENU_HEIGHT% = con.HEIGHT - 6

  Cls

  Option Console Serial

  twm.init(3, 10075)
  Local win0% = twm.new_win%(0, 0, con.WIDTH, con.HEIGHT)
  Local left% = twm.new_win%(2, 4, MENU_WIDTH%, MENU_HEIGHT%)
  Local right% = twm.new_win%(con.WIDTH / 2 + 1, 4, MENU_WIDTH% + 1, MENU_HEIGHT%)

  twm.switch(win0%)
  twm.box(0, 2, con.WIDTH, con.HEIGHT - 2)
  twm.box(0, 2, con.WIDTH / 2, con.HEIGHT - 2)
  twm.bold(1)
  twm.print_at(0, 0, str.centre$("Select adventure using [Up], [Down], [Page Up], [Page Down] and [Enter]", con.WIDTH))

  Local size% = map.size%(m$())
  Local first% = 0
  Local last% = first% + MENU_HEIGHT% - 1
  Local sel% = 0
  Local new_first% = first%
  Local new_sel% = sel%
  Local requires_update% = 1

  menus.paint_menu(left%, m$(), first%, sel%)

  Local k$ = Input$(255, #0)

  Do
    k$ = Inkey$
    Select Case Asc(k$)
      Case 13, 27, 32, 113 ' Enter, Escape, Space or Q
        Exit Do
      Case 128 ' Up
        new_sel% = sel% - 1
        If new_sel% < first% Then new_first% = first% - 1
      Case 129 ' Down
        new_sel% = sel% + 1
        If new_sel% > last% Then new_first% = first% + 1
      Case 136 ' Page Up
        new_sel% = Choice(sel% = first%, sel% - MENU_HEIGHT%, first%)
        new_first% = Choice(sel% = first%, new_sel%, first%)
      Case 137 ' Page Down
        new_sel% = Choice(sel% = last%, sel% + MENU_HEIGHT%, last%)
        new_first% = Choice(sel% = last%, new_sel%, first%)
      Case 0
        If requires_update% Then
          menus.paint_description(right%, map.get$(m$(), m$(sel%)))
          requires_update% = 0
        EndIf
    End Select

    ' Clear the keyboard buffer without blocking when it is empty.
    If k$ <> "" Then k$ = Input$(255, #0)

    ' Keep selected and first item within bounds of list.
    new_sel% = Min(size% - 1, Max(0, new_sel%))
    new_first% = Min(size% - MENU_HEIGHT%, Max(0, new_first%))

    ' Short-circuit if new selected item = old selected item.
    If new_sel% = sel% Then Continue Do

    twm.switch(left%)
    twm.inverse(0)
    twm.print_at(0, sel% - first%, menus.fmt_item$(m$(sel%), MENU_WIDTH%)) 

    If new_first% = first% + 1 Then
      twm.scroll_up(1)
    ElseIf new_first% = first% - 1 Then
      twm.scroll_down(1)
    ElseIf new_first% <> first% Then
      menus.paint_menu(left%, m$(), new_first%, new_sel%)
    EndIf

    twm.inverse(1)
    twm.print_at(0, new_sel% - new_first%, menus.fmt_item$(m$(new_sel%), MENU_WIDTH%))      

    first% = new_first%
    last% = first% + MENU_HEIGHT% - 1
    sel% = new_sel%
    requires_update% = 1

    Pause 100
  Loop

  ' Enter or Space to select.
  If Asc(k$) = 13 Or Asc(k$) = 32 Then menus.choose_advent$ = map.get$(m$(), m$(sel%))

  Option Console Both
  twm.free()

End Function

Sub menus.paint_menu(win%, m$(), first%, sel%)
  twm.switch(win%)
  twm.inverse(0)
  twm.cls()
  Local i%
  Local size% = map.size%(m$())
  Local last% = first% + twm.h% - 1
  If last% >= size% Then last% = size% - 1
  For i% = first% To last%
    twm.inverse(i% = sel%)
    twm.print_at(0, i% - first%, menus.fmt_item$(m$(i%), twm.w%))
  Next
End Sub

Function menus.fmt_item$(s$, w%)
  menus.fmt_item$ = str.centre$(Mid$(s$, 1, w%), w%)
End Function

Sub menus.paint_description(win%, advent$)
  Local desc%(200)
  metadata.read_description(fil.trim_extension$(catalogue.find$(advent$)) + ".ext", desc%())

  twm.switch(win%)
  twm.cls()
  twm.print_at(0, 0)

  Local ch%, i%, s$
  For i% = 1 To LLen(desc%())
    ch% = Peek(Var desc%(), i% + 7)
    If ch% = 10 Then
      twm.print(s$)
      s$ = ""
      Inc twm.y%
      twm.x% = 0
    ElseIf ch% = 13 Then
      ' Do nothing.
    Else
      Cat s$, Chr$(ch%)
      If Len(s$) = 255 Then twm.print(s$) : s$ = ""
    EndIf
  Next
  twm.print(s$)

End Sub
