#!/usr/local/bin/mmbasic

' Copyright (c) 2025-2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00

If Mm.Device$ <> "MMB4L" Then Error "Requires MMBasic for Linux"

Const PATH$ = Choice(Mm.Info$(Path) = "NONE", Cwd$, Mm.Info$(Path))
Const OLD$ = Cwd$

ChDir PATH$
On Error Skip 1
Kill "bin/saaint.bas"
' On Error Skip 1
' Kill "bin/saaint_rp2040.bas"
On Error SKip 1
Mkdir "bin"

'flags$ = "-e=1 -i=1 -n -s=1 -T -DNO_INCLUDE_GUARDS -DNO_EXTRA_CHECKS -DINLINE_CONSTANTS"
flags$ = "-e=1 -i=1 -s=1 -T -DNO_INCLUDE_GUARDS"
cmd$ = "sptrans " + flags$ + " src/saaint.bas bin/saaint.bas"
Print cmd$
System cmd$

' cmd$ = "sptrans " + flags$ + " -DLOW_MEMORY " + "src/saaint.bas bin/saaint_rp2040.bas"
' Print cmd$
' System cmd$

ChDir OLD$
