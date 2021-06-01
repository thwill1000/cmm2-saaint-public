' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file contains functions for reading SAAINT metadata '.ext'
' files.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "string")
sys.provides("metadata")
If sys.err$ <> "" Then Error sys.err$

Const metadata.FD_IN% = 1
Const metadata.FD_OUT% = 2

Dim metadata.name$              ' Name of the current adventure
Dim metadata.title_file$        ' File containing current adventure title card, empty if none
Dim metadata.credits_file$      ' File containing current adventure credits, empty if none
Dim metadata.instructions_file$ ' File containing current adventure instructions, empty if none

' Reads adventure name from ".ext" file.
'
' @param  f$  the full file path.
' @return     the adventure name,
'             if 'f$' does not exist then returns the name of the file withou
'             any path or extension and with the first letter capitalised.
Function metadata.read_name$(f$)
  Local extfile$ = fil.trim_extension$(f$) + ".ext"
  Local name$

  If fil.exists%(extfile$) Then
    Open extfile$ For Input As metadata.FD_IN%
    Line Input #metadata.FD_IN%, name$
    Close metadata.FD_IN%
  Else
    name$ = fil.trim_extension$(fil.get_name$(f$))
    name$ = UCase$(Left$(name$, 1)) + Mid$(name$, 2)
  EndIf

  metadata.read_name$ = str.trim$(name$)
End Function


' Reads description from ".ext" file.
'
' @param       f$      the full file path.
' @param[out]  out%()  the description is appended to this LongString.
Sub metadata.read_description(f$, out%())
  If Not fil.exists%(f$) Then
    LongString Append out%(), "No description provided."
    Exit Sub
  EndIf

  Local max_len% = (Bound(out%(), 1) - Bound(out%(), 0)) * 8
  Local cont%, s$
  Open f$ For Input As metadata.FD_IN%
  Do While Not Eof(metadata.FD_IN%)
    Line Input #metadata.FD_IN%, s$

    If metadata.find_section_header$(s$) <> "" Then Exit Do

    ' Handle line continuation.
    cont% = Right$(s$, 1) = "\"
    If cont% Then s$ = Left$(s$, Len(s$) - 1) + " "

    LongString Append out%(), Left$(s$, Min(255, max_len% - LLen(out%())))

    If Not cont% Then LongString Append out%(), Left$(sys.CRLF$, Min(255, max_len% - LLen(out%())))
  Loop
  Close metadata.FD_IN%
End Sub

Function metadata.find_section_header$(s$)
  If Not InStr(s$, "##") Then Exit Function
  Local us$ = UCase$(s$)
  If InStr(us$, "##TITLE##") Then
    us$ = "##TITLE##"
  ElseIf InStr(us$, "##CREDITS##") Then
    us$ = "##CREDITS##"
  ElseIf InStr(us$, "##INSTRUCTIONS##") Then
    us$ = "##INSTRUCTIONS##"
  Else
    us$ = ""
  EndIf
  metadata.find_section_header$ = us$
End Function

' Reads the '.ext' file.
' Assumes that the file has LF or CRLF line-endings, and not Mac style CR line-endings.
' Reports ERROR if encounters line > 255 characters.
Sub metadata.read_ext(f$)
  Select Case LCase$(fil.get_extension$(f$))
    Case ".dat" : Local f_in$ = fil.trim_extension$(f$) + ".ext"
    Case ".ext" : Local f_in$ = f$
    Case Else   : Local f_in$ = f$ + ".ext"
  End Select

  metadata.name$ = fil.trim_extension$(f$) + ".dat"
  metadata.title_file$ = ""
  metadata.credits_file$ = ""
  metadata.instructions_file$ = ""

  If Not fil.exists%(f_in$) Then Exit Sub

  Open f_in$ For Input As metadata.FD_IN%

  ' Adventure name should be on the first (non-blank) line.
  Local s$
  Do While Not Eof(metadata.FD_IN%)
    Line Input #metadata.FD_IN%, s$
    s$ = str.trim$(s$)
    If s$ <> "" Then
      metadata.name$ = s$
      Exit Do
    EndIf
  Loop

  ' Extract temporary TITLE, CREDITS and INSTRUCTIONS files.
  Local f_out$ = ""
  Local file_open% = 0
  Local first_line% = 0
  Local num_blank_lines% = 0
  Local header$
  Do While Not Eof(metadata.FD_IN%)
    Line Input #metadata.FD_IN%, s$

    ' Check for section headings and if found open the appropriate output file.
    header$ = metadata.find_section_header$(s$)
    Select Case header$
      Case "##TITLE##"
        metadata.title_file$ = fil.PROG_DIR$ + "/title.tmp"
        f_out$ = metadata.title_file$
        first_line% = -1
      Case "##CREDITS##"
        metadata.credits_file$ = fil.PROG_DIR$ + "/credits.tmp"
        f_out$ = metadata.credits_file$
        first_line% = -1
      Case "##INSTRUCTIONS##"
        metadata.instructions_file$ = fil.PROG_DIR$ + "/instructions.tmp"
        f_out$ = metadata.instructions_file$
        first_line% = -1
    End Select

    If first_line% = -1 Then
      If file_open% Then Close metadata.FD_OUT%
      Open f_out$ For Output As metadata.FD_OUT%
      file_open% = 1
      first_line% = 1
      num_blank_lines% = 0
      Continue Do
    EndIf

    If Not file_open% Then Continue Do

    ' We don't want the file to contain any leading or trailing blank lines.
    If str.trim$(s$) = "" Then
      Inc num_blank_lines%
    Else
      If Not first_line% Then
        Do While num_blank_lines% > 0
          Print #metadata.FD_OUT%
          Inc num_blank_lines%, -1
        Loop
      EndIf
      Print #metadata.FD_OUT%, s$
      first_line% = 0
      num_blank_lines% = 0
    EndIf

  Loop

  If file_open% Then Close metadata.FD_OUT%
  Close metadata.FD_IN%
End Sub
