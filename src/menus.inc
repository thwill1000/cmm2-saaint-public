' Copyright (c) 2020-2023 Thomas Hugo Williams
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("catalogue", "console", "file", "map", "metadata", "txtwm")
sys.provides("menus")
If sys.err$ <> "" Then Error sys.err$

' This file contains functions to show the main, adventure selection
' and adventure specific menus as well as the credits and
' instructions.

Function menus.main$(advent$)
  Local f$ = Mm.Info$(Path) + "title.txt")

  Cls
  twm.enable_cursor(0)
  con.lines = 0
  con.foreground("white")
  con.println()
  con.print_file(f$, 1)
  con.foreground("green")
  con.println()
  Local play_item$ = Choice(advent$ = "", "", "P  Play '" + metadata.read_name$(advent$) + "'")
  Local select_item$ = "S  Select a " + Choice(advent$ = "", "new", "different") + " adventure"
  Local width% = Max(Len(play_item$), Len(select_item$))
  If play_item$ <> "" Then con.println(str.rpad$(play_item$, width%), 1)
  con.println(str.rpad$(select_item$,           width%), 1)
  con.println(str.rpad$("I  Instructions",      width%), 1)
  con.println(str.rpad$("C  Credits & License", width%), 1)
  con.println(str.rpad$("Q  Quit",              width%), 1)
  con.println()
  con.println("Version " + SAAINT_VERSION$, 1)

  Do While Inkey$ <> "" : Loop
  Local k$
  Do
    k$ = LCase$(Inkey$)
    If Asc(k$) = 27 Then k$ = "escape"
    Select Case k$
      Case "p" : menus.main$ = "#play"
      Case "c" : menus.main$ = "#credits"
      Case "i" : menus.main$ = "#instructions"
      Case "q", "escape" : menus.main$ = "#quit"
      Case "s" : menus.main$ = "#select"
      Case Else : k$ = "" : Pause 1
    End Select
  Loop Until k$ <> ""

  con.lines = 0
End Function

Function menus.adventure$()

  Cls
  twm.enable_cursor(0)
  con.lines = 0
  con.foreground("white")
  If metadata.title_file$ <> "" Then
    con.print_file(metadata.title_file$, 1)
  Else
    con.println()
    con.println(metadata.name$, 1)
  EndIf
  con.foreground("green")
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
    If Asc(k$) = 27 Then k$ = "escape"
    Select Case k$
      Case "b", "escape" : menus.adventure$ = "#back"
      Case "c"
        If metadata.credits_file$ <> "" Then menus.adventure$ = "#credits" Else k$ = ""
      Case "i" : menus.adventure$ = "#instructions"
      Case "q" : menus.adventure$ = "#quit"
      Case "r" : menus.adventure$ = "#restore"
      Case "s" : menus.adventure$ = "#start"
      Case Else : k$ = "" : Pause 1
    End Select
  Loop Until k$ <> ""

  con.lines = 0
End Function

Sub menus.credits(top%)
  Local f$ = Choice(top%, "", metadata.credits_file$)
  f$ = Choice(f$ <> "", f$, Mm.Info$(Path) + "credits.txt")

  Cls
  twm.enable_cursor(0)
  con.lines = 0
  con.foreground("white")
  con.println()
  con.println("CREDITS & LICENSE", 1)
  con.println("=================", 1)
  con.println()
  con.foreground("green")
  con.print_file(f$, 1)
  con.println()
  con.foreground("white")
  con.println("Press any key to continue", 1)
  con.foreground("green")
  Do While Inkey$ <> "" : Loop
  Do While Inkey$ = "" : Pause 1 : Loop
End Sub

Sub menus.instructions(top%)
  Local f$ = Choice(top%, "", metadata.instructions_file$)
  f$ = Choice(f$ <> "", f$, Mm.Info$(Path) + "instructions.txt")

  Cls
  twm.enable_cursor(0)
  con.lines = 0
  con.foreground("white")
  con.println()
  con.println("HOW TO PLAY", 1)
  con.println("===========", 1)
  con.println()
  con.foreground("green")
  con.print_file(f$, 1)
  con.println()
  con.foreground("white")
  con.println("Press any key to continue", 1)
  con.foreground("green")
  Do While Inkey$ <> "" : Loop
  Do While Inkey$ = "" : Pause 1 : Loop
End Sub

Function menus.choose_advent$()
  Const MENU_WIDTH% = Int(con.WIDTH / 2) - 4
  Const MENU_HEIGHT% = con.HEIGHT - 6

  Cls
  Option Console Serial
  twm.enable_cursor(0)

  Local twm_sz% = 7 + 2 * (con.WIDTH * con.HEIGHT)
  Inc twm_sz%, 7 + 2 * (MENU_WIDTH * MENU_HEIGHT)
  Inc twm_sz%, 7 + 2 * ((MENU_WIDTH + 1) * MENU_HEIGHT)
  twm.init(3, twm_sz%)
  Local win0% = twm.new_win%(0, 0, con.WIDTH, con.HEIGHT)
  Local left% = twm.new_win%(2, 4, MENU_WIDTH%, MENU_HEIGHT%)
  Local right% = twm.new_win%(con.WIDTH / 2 + 1, 4, MENU_WIDTH% + 1, MENU_HEIGHT%)

  twm.switch(win0%)
  twm.box(0, 2, con.WIDTH, con.HEIGHT - 2)
  twm.box(0, 2, con.WIDTH / 2, con.HEIGHT - 2)
  twm.bold(1)
  twm.print_at(0, 0, str.centre$("Select adventure using [Up], [Down], [Page Up], [Page Down] and [Enter]", con.WIDTH))
  twm.switch(left%)
  twm.print_at(0, 0, "Reading adventures...")

  Select Case Mm.Device$
    Case "MMB4L", "MMBasic for Windows"
      Local m$(map.new%(50))
    Case Else
      Local m$(map.new%(50)) Length 64
  End Select
  map.init(m$())
  catalogue.get_all(m$())

  Local size% = map.size%(m$())
  Local first% = 0
  Local last% = first% + MENU_HEIGHT% - 1
  Local sel% = 0
  Local new_first% = first%
  Local new_sel% = sel%
  Local requires_update% = 1
  Local i%

  menus.paint_menu(left%, m$(), first%, sel%)

  Local k$ = Input$(255, #0)

  Do
    k$ = Inkey$
    Select Case Asc(k$)
      Case 10, 13, 27, 32, 113 ' Enter, Escape, Space or Q
        Exit Do
      Case 128 ' Up
        new_sel% = sel% - 1
      Case 129 ' Down
        new_sel% = sel% + 1
      Case 136 ' Page Up
        new_sel% = Choice(sel% = first%, sel% - MENU_HEIGHT%, first%)
      Case 137 ' Page Down
        new_sel% = Choice(sel% = last%, sel% + MENU_HEIGHT%, last%)
      Case Asc("A") To Asc("Z"), Asc("a") To Asc("z"), Asc("0") To Asc("9")
        ' Select adventure to first entry whose name begins with letter/digit.
        ' If current selection and next entry begin with letter/digit then select
        ' next entry.
        ' Relies on all adventure names beginning with digit or upper-case character.
        k$ = UCase$(k$)
        If Left$(m$(sel%), 1) = k$ Then new_sel% = sel% + 1
        If Left$(m$(new_sel%), 1) <> k$ Then
          For i% = 0 To size% - 1
            If Left$(m$(i%), 1) = k$ Then
              new_sel% = i%
              Exit For
            EndIf
          Next
        EndIf
      Case 0
        If requires_update% Then
          menus.paint_description(right%, map.get$(m$(), m$(sel%)))
          requires_update% = 0
        EndIf
        Pause 1
    End Select

    ' Clear the keyboard buffer without blocking when it is empty.
    If k$ <> "" Then k$ = Input$(255, #0)

    ' Keep selected item within bounds of list.
    new_sel% = Min(size% - 1, Max(0, new_sel%))

    ' Short-circuit if new selected item = old selected item.
    If new_sel% = sel% Then Continue Do

    ' Update new_first% to keep new_sel% within display bounds.
    If new_sel% < first% Then
      new_first% = new_sel%
    ElseIf new_sel% > last% Then
      new_first% = new_sel% - MENU_HEIGHT% + 1
    EndIf

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
  Select Case Asc(k$)
    Case 10, 13, 32 : menus.choose_advent$ = map.get$(m$(), m$(sel%))
  End Select

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
  metadata.read_description(file.trim_extension$(catalogue.find$(advent$)) + ".ext", desc%())

  twm.switch(win%)
  twm.cls()
  twm.print_at(0, 0)

  Local ch%, i%, s$
  For i% = 1 To LLen(desc%())
    ch% = Peek(Var desc%(), i% + 7)
    Select Case ch%
      Case 10 ' LF
        If twm.x% + Len(s$) >= twm.w% Then twm.x% = 0 : Inc twm.y%
        twm.print(s$)
        s$ = ""
        twm.x% = 0
        Inc twm.y%
      Case 13 ' CR
        ' Do nothing.
      Case 32 ' Space
        If twm.x% + Len(s$) > twm.w% Then
          twm.x% = 0
          Inc twm.y%
        EndIf
        If s$ = " " Then
          If twm.x% > 0 Then twm.print(" ")
        Else
          twm.print(s$)
        EndIf
        s$ = " "
      Case Else
        If s$ = " " Then
          If twm.x% > 0 Then twm.print(" ")
          s$ = ""
        EndIf
        Cat s$, Chr$(ch%)
    End Select
  Next
  twm.print(s$)

End Sub
