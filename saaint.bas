Cls
Print "SAAINT is loading, please wait ..."
Const file$ = Mm.Info$(Path) + "src/saaint.bas"
If InStr(Mm.Device$, "Colour Maximite 2") Then
  Execute "Run " + Chr$(34) + file$ + Chr$(34) + ", " + Mm.CmdLine$
ElseIf Mm.HRes = 320 And Mm.VRes = 320 Then
  Run Mm.Info$(Path) + "bin/saaint.bas", Mm.CmdLine$
ElseIf InStr(Mm.Device$, "PicoMite") Then
  Cmm2 Run file$, Mm.CmdLine$
Else
  Run file$, Mm.CmdLine$
EndIf
