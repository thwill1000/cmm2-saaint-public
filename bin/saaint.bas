' Transpiled on 08-11-2026 21:20:54
' Scott Adams Adventure Game Interpreter
' For MMBasic 6
' Copyright (c) 2020-2026 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley
' Based on original TRS-80 Level II BASIC code (c) 1978 Scott Adams
Option Base 0
Option Default Integer
Option Explicit On
Const SAAINT_VERSION=201001 ' 2.1 alpha 1
' src/splib/system.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
On Error Skip
xyz_not_declared%=1
If Not Mm.ErrNo Then Error "OPTION EXPLICIT is required by splib"
On Error Clear
Const sys.VERSION=103300 ' 1.3.0
Const sys.NO_DATA$=Chr$(&h7F)
Const sys.CRLF$=Chr$(13)+Chr$(10)
If Mm.Info$(Device X)="MMB4L" Then
 Const sys.FIRMWARE=Mm.Info(Version)
Else
 Const sys.FIRMWARE=Int(1000000*Mm.Info(Version))
EndIf
Const sys.SUCCESS=0
Const sys.FAILURE=-1
Dim sys.break_flag%
Dim sys.err$

' Formats an integer version as a string.
'
' @param  v%   version number: AABBCDD
'              - AA is the 2-digit major version.
'              - BB is the 2-digit minor version.
'              - C  = 0 for alpha
'                   = 1 for beta
'                   = 2 for release candidate
'                   = 3..9 for release.
'              - DD is the micro version if c <= 3.
'                If c > 3 Then CDD - 300 is the micro version.
Function sys.format_version$(v%)
 Const v_%=Choice(v%,v%,sys.VERSION)
 Local s$=Str$(v_%\10^5)+"."+Str$((v_% Mod 10^5)\10^3)
 Select Case v_% Mod 1000
  Case <100 : Cat s$," alpha "+Str$(v_% Mod 1000)
  Case <200 : Cat s$," beta "+Str$((v_% Mod 1000)-100)
  Case <300 : Cat s$," RC "+Str$((v_% Mod 1000)-200)
  Case Else : Cat s$,"."+Str$((v_% Mod 1000)-300)
 End Select
 sys.format_version$=s$
End Function

Function sys.is_windows%()
 If Mm.Device$="MMB4L" Then
  sys.is_windows%=(Mm.Info$(Arch)="Windows x86_64")
 Else
  sys.is_windows%=(Mm.Device$="MMBasic for Windows")
 EndIf
End Function

Sub sys.normalize_separators(path$)
 Local i%
 For i%=1 To Len(path$)
  If Peek(Var path$,i%)=Asc("\") Then Poke Var path$,i%,Asc("/")
 Next
End Sub

Function sys.HOME$()
 If sys.is_windows%() Then
  sys.HOME$=Mm.Info$(EnvVar "USERPROFILE")
  If sys.HOME$="" Then sys.HOME$=Mm.Info$(EnvVar "HOMEDIR")+Mm.Info$(EnvVar "HOMEPATH")
  sys.normalize_separators(sys.HOME$)
 ElseIf Mm.Info$(Device X)="MMB4L" Then
  sys.HOME$=Mm.Info$(EnvVar "HOME")
 Else
  sys.HOME$="A:"
 EndIf
End Function

Function sys.SEPARATOR$()
 sys.SEPARATOR$=Choice(Mm.Device$="MMBasic for Windows","\","/")
End Function

Function sys.error%(code%,msg$)
 If Not code% Then Error "Invalid error code"
 sys.error%=code%
 sys.err$=msg$
End Function

' Reads the '.mmbasic-shell' file.
'
' @param  exist%  If 1 then ERROR if file does not exist, otherwise return empty string.
' @param  fnbr%   File number to use for accessing the file, if unspecified/0 then uses #9.
' @return         The contents of the first line of the file.
Function sys.read_shell_file$(exist%,fnbr%)
 Const f$=sys.HOME$()+"/.mmbasic-shell"
 If Not exist% And Not Mm.Info(Exists f$) Then Exit Function
 Const _fnbr%=Choice(fnbr%,fnbr%,9)
 Open f$ For Input As _fnbr%
 Line Input #_fnbr%,sys.read_shell_file$
 Close _fnbr%
End Function

' Runs the program specified by the '.mmbasic-shell' file.
'
' @param  fnbr%  File number to use for accessing the file, if unspecified/0 then uses #9.
Sub sys.run_shell(fnbr%)
 Const prog$=sys.read_shell_file$(1,fnbr%)
 If prog$<>"" Then Run prog$
End Sub

' ---- src/splib/system.inc
' src/splib/array.inc ++++
' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Gets the upper-bound that should be used to dimension an array of the given
' capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can hold 10 elements:
'        Dim my_array$(array.new%(10))
Function array.new%(capacity%)
 array.new%=capacity%+Mm.Info(Option Base)-1
End Function

' Binary search for a value in a SORTED array.
'
' @param  a$()    the array.
' @param  s$      the value to search for.
' @param  flags$  "i" to search case-insensitively,
' @param  lb%     the lower bound to search from,
'                 if 0/unset then search from the first element.
' @param  num%    the number of elements to search,
'                 if 0/unset then search all the elements (from lb%).
' @return         the index of the element containing the value,
'                 or -1 if not present.
Function array.bsearch%(a$(),s$,flags$,lb_%,num_%)
 Local lb%=Choice(lb_%=0,Bound(a$(),0),lb_%)
 Local num%=Choice(num_%=0,Bound(a$(),1)-Bound(a$(),0)+1,num_%)
 Local ub%=lb%+num%-1
 Local i%
 If InStr(UCase$(flags$),"I") Then
  Local us$=UCase$(s$)
  Local ua$
  Do While ub%>=lb%
   i%=(lb%+ub%)\2
   ua$=UCase$(a$(i%))
   If us$>ua$ Then
    lb%=i%+1
   ElseIf us$<ua$ Then
    ub%=i%-1
   Else
    Exit Do
   EndIf
  Loop
 Else
  Do While ub%>=lb%
   i%=(lb%+ub%)\2
   If s$>a$(i%) Then
    lb%=i%+1
   ElseIf s$<a$(i%) Then
    ub%=i%-1
   Else
    Exit Do
   EndIf
  Loop
 EndIf
 If ub%>=lb% Then array.bsearch%=i% Else array.bsearch%=-1
End Function

' ---- src/splib/array.inc
' src/splib/bits.inc ++++
' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Sets bit i% of x%.
Sub bits.set(x%,i%)
 If i%<0 Or i%>63 Then Error "Index out of bounds"
 x%=x% Or 1<<i%
End Sub

' Clears bit i% of x%.
Sub bits.clear(x%,i%)
 If i%<0 Or i%>63 Then Error "Index out of bounds"
 x%=x% And Inv(1<<i%)
End Sub

' Gets bit i% of x%.
Function bits.get%(x%,i%)
 If i%<0 Or i%>63 Then Error "Index out of bounds"
 bits.get%=(x% And 1<<i%)<>0
End Function

' ---- src/splib/bits.inc
' src/splib/list.inc ++++
' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Gets the upper-bound that should be used to dimension an array to hold a list
' of the given capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can be used as a list of 10 elements:
'        Dim my_list$(list.new%(10))
Function list.new%(capacity%)
 list.new%=capacity%+Mm.Info(Option Base)
End Function

' Initialises the list.
Sub list.init(lst$())
 Local i%
 For i%=Bound(lst$(),0) To Bound(lst$(),1)
  lst$(i%)=sys.NO_DATA$
 Next
 lst$(Bound(lst$(),1))="0"
End Sub

' Appends an element to the end of the list.
Sub list.add(lst$(),s$)
 Local lb%=Bound(lst$(),0)
 Local ub%=Bound(lst$(),1)
 Local sz%=Val(lst$(ub%))
 ' TODO: report error if adding to a full list.
 lst$(lb%+sz%)=s$
 lst$(ub%)=Str$(sz%+1)
End Sub

Function list.is_full%(lst$())
 Local ub%=Bound(lst$(),1)
 '             = (ub% - lb%) = sz%
 list.is_full%=(ub%-Bound(lst$(),0))=Val(lst$(ub%))
End Function

' Gets the size of the list.
Function list.size%(list$())
 list.size%=Val(list$(Bound(list$(),1)))
End Function

' ---- src/splib/list.inc
' src/splib/map.inc ++++
' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Gets the upper-bound that should be used to dimension an array to hold a map
' of the given capacity, irrespective of OPTION BASE.
'
' e.g. To create a string array that can be used as a map of 10 elements:
'        Dim my_map$(map.new%(10))
Function map.new%(capacity%)
 map.new%=2*capacity%+Mm.Info(Option Base)
End Function

' Initialises the map.
Sub map.init(mp$())
 Local lb%=Bound(mp$(),0)
 Local ub%=Bound(mp$(),1)
 Local i%
 For i%=lb% To ub% : mp$(i%)=sys.NO_DATA$ : Next
 mp$(ub%)="0"
End Sub

' Gets the capacity of the map.
Function map.capacity%(mp$())
 map.capacity%=(Bound(mp$(),1)-Bound(mp$(),0))\2
End Function

' Gets the value corresponding to a key, or sys.NO_DATA$ if the key is not present.
Function map.get$(mp$(),k$)
 Local lb%=Bound(mp$(),0)
 Local ub%=Bound(mp$(),1)
 Local off%=(ub%-lb%)\2
 Local sz%=Val(mp$(ub%))
 Local i%=array.bsearch%(mp$(),k$,"",lb%,sz%)
 If i%>-1 Then
  map.get$=mp$(i%+off%)
 Else
  map.get$=sys.NO_DATA$
 EndIf
End Function

Function map.is_full%(map$())
 Local ub%=Bound(map$(),1)
 '             = (ub% - lb%) \ 2 = sz%
 map.is_full%=(ub%-Bound(map$(),0))\2=Val(map$(ub%))
End Function

' Adds a key/value pair.
Sub map.put(mp$(),k$,v$)
 Local lb%=Bound(mp$(),0)
 Local ub%=Bound(mp$(),1)
 Local off%=(ub%-lb%)\2
 Local sz%=Val(mp$(ub%))
 Local i%=array.bsearch%(mp$(),k$,"",lb%,sz%)
 If i%<>-1 Then mp$(i%+off%)=v$ : Exit Sub
 If sz%=off% Then Error "map full" : Exit Sub
 sz%=sz%+1
 mp$(lb%+sz%-1)=k$
 mp$(lb%+sz%+off%-1)=v$
 mp$(ub%)=Str$(sz%)
 If sz%>1 Then
  If k$<mp$(lb%+sz%-2) Then map.sort(mp$())
 EndIf
End Sub

' Gets the size / number of entries in the map.
Function map.size%(mp$())
 map.size%=Val(mp$(Bound(mp$(),1)))
End Function

' Sorts the map to place the keys in ascending order.
Sub map.sort(mp$())
 Local lb%=Bound(mp$(),0)
 Local ub%=Bound(mp$(),1)
 Local off%=(ub%-lb%)\2
 Local sz%=Val(mp$(ub%))
 Local idx%(map.new%(off%))
 ' Sort keys.
 Sort mp$(),idx%(),,lb%,sz%
 ' Copy values to tmp$().
 Local i%
 Select Case Mm.Device$
  Case "PicoMite","PicoMiteVGA"
   Local tmp$(map.new%(sz%)) Length Peek(Byte Peek(VarHeader mp$())+34)
  Case Else
   Local tmp$(map.new%(sz%))
 End Select
 ub%=lb%+sz%-1
 For i%=lb% To ub% : tmp$(i%)=mp$(i%+off%) : Next
 ' Copy re-ordered values back into mp$().
 For i%=lb% To ub% : mp$(i%+off%)=tmp$(idx%(i%)) : Next
End Sub

' ---- src/splib/map.inc
' src/splib/string.inc ++++
' Copyright (c) 2020-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Pads a string with spaces to the left and right so that it will be centred
' within a fixed length field. If the string is longer than the field then
' this function just returns the string. If an odd number of spaces are
' required then the extra space is added to the left hand side of the string.
'
' @param  s$  the string to centre.
' @param  x   the field length.
Function str.centre$(s$,x%)
 If Len(s$)<x% Then
  str.centre$=s$+Space$((x%-Len(s$))\2)
  str.centre$=Space$(x%-Len(str.centre$))+str.centre$
 Else
  str.centre$=s$
 EndIf
End Function

' Does a string contain only printable and/or whitespace ASCII ?
'
' @param  s$  the string.
' @return     1 if the string only contains printable and/or whitespace ASCII, otherwise 0.
Function str.is_plain_ascii%(s$)
 Local i%
 For i%=1 To Len(s$)
  Select Case Peek(Var s$,i%)
   Case 9,10,13 : ' Tab, line-feed and carriage-return are acceptable.
   Case <32,>126 : Exit Function
   Case Else : ' ASCII printable characters.
  End Select
 Next
 str.is_plain_ascii%=1
End Function

' Tokenises a string separated by delimiters.
'
'  - delimiters are ignored between pairs of double-quotes.
'  - a double-quote preceeded by a backslash does not end a pair of
'    double-quotes.
'  - double-quotes and backslashes are included verbatim in the returned tokens.
'
' @param   s$     string to tokenise.
' @param   dlm$   one or more token delimiter characters.
'                 If empty then use space and skip empty tokens.
' @param   skip%  1 to skip empty tokens, 0 to return them.
' @return  the first token. To retrieve subsequent tokens call this function
'          with no parameters, i.e. tk$ = str.next_token$().
'          Returns sys.NO_DATA$ if there are no more tokens.
'
' WARNING! Take care when calling this function naively in cases where s$ might
' be the empty string as that will return data from a previously incomplete
' tokenisation. If necessary call str.next_token$(sys.NO_DATA$) to clear the
' internal state first.
Function str.next_token$(s$,dlm$,skip%)
 Static s_$,dlm_$,skip_%,p%
 If s$<>"" Then
  s_$=s$
  dlm_$=Choice(dlm$=""," ",dlm$)
  skip_%=Choice(dlm$="",1,skip%)
  p%=1 ' Index to process from.
 EndIf
 ' If we've reached the end of the string then return either NO_DATA or an
 ' empty token depending on the value of skip_% and then force skip_% =
 If p%>Len(s_$) Then
  str.next_token$=Choice(skip_%,sys.NO_DATA$,"")
  skip_%=1
  Exit Function
 EndIf
 Local ch%,state%=0
 For p%=p% To Len(s_$)
  ch%=Peek(Var s_$,p%)
  Select Case state%
   Case 0  ' Base state
    If ch%=&h22 Then
     state%=1
    ElseIf InStr(dlm_$,Chr$(ch%)) Then
     If skip_% Then
      If Len(str.next_token$)=0 Then Continue For
     EndIf
     Inc p%
     Exit For
    EndIf
   Case 1  ' Inside double-quote
    Select Case ch%
     Case &h22 : state%=0  ' double-quote
     Case &h5C : state%=2  ' backslash
    End Select
   Case 2  ' Inside double-quote and following backslash
    state%=1
  End Select
  Cat str.next_token$,Chr$(ch%)
 Next
 ' If we reach the end of the string and the last character is not a delimiter
 ' then force skip_% = 1 so we do not return an empty token on the next call.
 If p%>Len(s_$) Then
  If Not InStr(dlm_$,Chr$(ch%)) Then skip_%=1
 EndIf
End Function

' Gets copy of 'haystack$' with occurrences of 'needle$' replaced by 'rep$'.
Function str.replace$(haystack$,needle$,rep$)
 Local p%,st%,s$
 Do
  Inc st%
  p%=InStr(st%,haystack$,needle$)
  If p%<1 Then Exit Do
  Cat s$,Mid$(haystack$,st%,p%-st%)+rep$
  st%=p%+Len(needle$)-1
 Loop
 Cat s$,Mid$(haystack$,st%)
 str.replace$=s$
End Function

' Gets a string padded to a given width to the right.
'
' @param  s$  the string.
' @param  w%  the width.
' @param  c$  the padding character, a space if omitted.
' @return     the padded string.
'             If Len(s$) > w% then returns the unpadded string.
Function str.rpad$(s$,x%,c$)
 str.rpad$=s$
 If c$="" Then c$=" "
 If Len(s$)<x% Then str.rpad$=s$+String$(x%-Len(s$),c$)
End Function

' Returns a copy of s$ with leading and trailing spaces removed.
Function str.trim$(s$)
 Local st%,en%
 For st%=1 To Len(s$)
  If Peek(Var s$,st%)<>32 Then Exit For
 Next
 For en%=Len(s$) To 1 Step -1
  If Peek(Var s$,en%)<>32 Then Exit For
 Next
 If en%>=st% Then str.trim$=Mid$(s$,st%,en%-st%+1)
End Function

' If s$ both begins and ends with " then returns a copy of s$ with those characters removed,
' otherwise returns an unmodified copy of s$.
Function str.unquote$(s$)
 str.unquote$=s$
 If Len(s$)<2 Then Exit Function
 If Peek(Var s$,1)<>34 Then Exit Function
 If Peek(var s$,Len(s$))=34 Then
  str.unquote$=Mid$(s$,2,Len(s$)-2)
 EndIf
End Function

' ---- src/splib/string.inc
' src/splib/txtwm.inc ++++
' Copyright (c) 2021-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
If Mm.Info(Option Base)<>0 Then Error "expects OPTION BASE 0"
Const twm.BLACK%=0
Const twm.RED%=1
Const twm.GREEN%=2
Const twm.YELLOW%=3
Const twm.BLUE%=4
Const twm.MAGENTA%=5
Const twm.CYAN%=6
Const twm.WHITE%=7
' All these arrays are created by twm.init() and destroyed by twm.free().
' Dim twm.vt$(255)  ' map of attribute values to VT100 control-codes
' Dim twm.fg%(255)  ' map of attribute values to VGA foreground colours
' Dim twm.bg%(255)  ' map of attribute values to VGA background colours
' Dim twm.data%()   ' large block of memory for storing window state.
' Dim twm.ptr%()    ' pointers into twm.data%() such that twm.ptr%(i) is the
' memory address where the data for window 'i' starts.
' Dim twm.c2b%(255) ' map from ASCII chars to box-drawing data.
' Dim twm.b2c%(15)  ' map from box-drawing data to ASCII chars.
Dim twm.max_num%    ' max number of windows allowed
Dim twm.num%        ' current number of windows created
Dim twm.fw%         ' font width
Dim twm.fh%         ' font height
Dim twm.last_at%    ' as an optimisation we keep a record of the last attribute
' / vt100 control-code that the txtwm library wrote to the
' serial output so that we only write a new one when
' necessary. WARNING! if code outside of txtwm is also
' writing vt100 control-codes then this may get out of
' synch. It can be cleared by setting it to -1 or calling
' twm.switch().
Dim twm.cursor_enabled%
Dim twm.cursor_locked%
' For the currently selected window:
Dim twm.id% ' id
Dim twm.a%  ' x-coordinate of left hand side
Dim twm.b%  ' y-coordinate of top
Dim twm.w%  ' width
Dim twm.h%  ' height
Dim twm.x%  ' x cursor-position
Dim twm.y%  ' y cursor-position
Dim twm.at% ' attributes to use for printing
Dim twm.pc% ' pointer to the character data
Dim twm.pa% ' pointer to the attribute data
Dim twm.console_only%=0 ' Set 1 to only write to console.
' Initialises the 'txtwm' library.
'
' @param  max_num%  the maximum number of windows to support.
' @param  mem_sz%   number of bytes of memory to allocate for window data.
'                   Each window requires 7 + 2 * (width * height) bytes.
Sub twm.init(max_num%,mem_sz%)
 If twm.max_num%>0 Then Error "'txtwm' already initialised"
 If max_num%<1 Or max_num%>10 Then Error "Invalid 'max_num'; must be between 1 and 10: "+Str$(max_num%)
 If mem_sz%<100 Then Error "Invalid 'mem_sz'; must be >= 100: "+Str$(mem_sz%)
 twm.max_num%=max_num%
 twm.id%=-1
 twm.last_at%=-1
 twm.fw%=Mm.Info(FontWidth)
 twm.fh%=Mm.Info(FontHeight)
 ' Allocate data buffer (possibly with a few extra bytes).
 Dim twm.data%((mem_sz%\8)+1)
 ' Allocate array of pointers (one for each window) into the data buffer.
 ' Because MMBasic can't have 1 element arrays we always allocate space for at least 2 windows.
 Dim twm.ptr%(Choice(max_num%=1,1,max_num%-1))
 twm.init_serial_attrs()
 twm.init_screen_attrs()
 twm.init_box_chars()
 twm.enable_cursor(0)
End Sub

Sub twm.init_serial_attrs()
 Local i%,vt$
 Dim twm.vt$(255) Length 20
 For i%=0 To 255
  ' Clear attributes
  vt$=Chr$(27)+"[0m"
  ' Foreground (with/out bold)
  Cat vt$,Chr$(27)+"["+Choice(i% And &b01000000,"1;3","3")+Str$(i% And &b00000111)+"m"
  ' Background
  Cat vt$,Chr$(27)+"[4"+Str$((i% And &b00111000)>>3)+"m"
  ' Reverse video
  If i% And &b10000000 Then Cat vt$,Chr$(27)+"[7m"
  twm.vt$(i%)=vt$
 Next
End Sub

Sub twm.init_screen_attrs()
 Local bg%,fg%,i%
 Dim twm.fg%(255)
 Dim twm.bg%(255)
 For i%=0 To 255
  ' Foreground
  Select Case i% And &b00000111
   Case twm.BLACK% : fg%=RGB(Black)
   Case twm.RED% : fg%=RGB(Red)
   Case twm.GREEN% : fg%=RGB(Green)
   Case twm.YELLOW% : fg%=RGB(Yellow)
   Case twm.BLUE% : fg%=RGB(Blue)
   Case twm.MAGENTA% : fg%=RGB(Magenta)
   Case twm.CYAN% : fg%=RGB(Cyan)
   Case twm.WHITE% : fg%=RGB(White)
   Case Else Error
  End Select
  ' Bold/Bright text
  If i% And &b01000000 Then
   If fg%<>0 Then fg%=fg% Or &h404040
  EndIf
  ' Background
  Select Case(i% And &b00111000)>>3
   Case twm.BLACK% : bg%=RGB(Black)
   Case twm.RED% : bg%=RGB(Red)
   Case twm.GREEN% : bg%=RGB(Green)
   Case twm.YELLOW% : bg%=RGB(Yellow)
   Case twm.BLUE% : bg%=RGB(Blue)
   Case twm.MAGENTA% : bg%=RGB(Magenta)
   Case twm.CYAN% : bg%=RGB(Cyan)
   Case twm.WHITE% : bg%=RGB(White)
   Case Else Error
  End Select
  If i% And &b10000000 Then
   ' Reverse video
   twm.bg%(i%)=fg%
   twm.fg%(i%)=bg%
  Else
   ' Normal video
   twm.bg%(i%)=bg%
   twm.fg%(i%)=fg%
  EndIf
 Next
End Sub

Sub twm.init_box_chars()
 Dim twm.c2b%(255)
 twm.c2b%(&hB9)=&b1101
 twm.c2b%(&hBA)=&b0101
 twm.c2b%(&hBB)=&b1100
 twm.c2b%(&hBC)=&b1001
 twm.c2b%(&hC8)=&b0011
 twm.c2b%(&hC9)=&b0110
 twm.c2b%(&hCA)=&b1011
 twm.c2b%(&hCB)=&b1110
 twm.c2b%(&hCC)=&b0111
 twm.c2b%(&hCD)=&b1010
 twm.c2b%(&hCE)=&b1111
 Dim twm.b2c%(15)
 twm.b2c%(&b1101)=&hB9
 twm.b2c%(&b0101)=&hBA
 twm.b2c%(&b1100)=&hBB
 twm.b2c%(&b1001)=&hBC
 twm.b2c%(&b0011)=&hC8
 twm.b2c%(&b0110)=&hC9
 twm.b2c%(&b1011)=&hCA
 twm.b2c%(&b1110)=&hCB
 twm.b2c%(&b0111)=&hCC
 twm.b2c%(&b1010)=&hCD
 twm.b2c%(&b1111)=&hCE
End Sub

Sub twm.free()
 If twm.max_num%=0 Then Exit Sub
 Erase twm.data%()
 Erase twm.ptr%()
 Erase twm.c2b%()
 Erase twm.b2c%()
 Erase twm.vt$()
 Erase twm.fg%()
 Erase twm.bg%()
 twm.max_num%=0
 twm.num%=0
 twm.fw%=0
 twm.fh%=0
 twm.id%=0
 twm.a%=0
 twm.b%=0
 twm.w%=0
 twm.h%=0
 twm.x%=0
 twm.y%=0
 twm.at%=0
 twm.pc%=0
 twm.pa%=0
 twm.last_at%=0
End Sub

Function twm.new_win%(x%,y%,w%,h%)
 If twm.num%>Bound(twm.ptr%(),1) Then Error "maximum number of windows reached: "+Str$(twm.num%)
 ' Store pointer into the data buffer for the new window.
 Local ptr%
 If twm.num%=0 Then
  ptr%=Peek(VarAddr twm.data%())
 Else
  ptr%=twm.ptr%(twm.num%-1)
  Inc ptr%,7+Peek(Byte ptr%+2)*Peek(Byte ptr%+3)*2
 EndIf
 twm.ptr%(twm.num%)=ptr%
 Const reqd%=ptr%+7+w%*h%*2-twm.ptr%(0)
 Const alloc%=(Bound(twm.data%(),1)-Bound(twm.data%(),0))*8
 If reqd%>alloc% Then
  Error "out of txtwm memory: "+Str$(alloc%)+" bytes allocated, "+Str$(reqd%)+" required"
 EndIf
 ' Note we add 1 to window x & y positions to account for VT100 using (1, 1) as origin.
 Poke Byte ptr%+0,x%+1                          ' window x-position
 Poke Byte ptr%+1,y%+1                          ' window y-position
 Poke Byte ptr%+2,w%                              ' window width
 Poke Byte ptr%+3,h%                              ' window height
 Poke Byte ptr%+4,0                               ' x-cursor position
 Poke Byte ptr%+5,0                               ' y-cursor position
 Poke Byte ptr%+6,twm.WHITE%                      ' current attribute value
 Memory Set ptr%+7,32,w%*h%                    ' character buffer
 Memory Set ptr%+7+w%*h%,twm.WHITE%,w%*h%  ' attribute buffer
 twm.new_win%=twm.num%
 Inc twm.num%
End Function

Sub twm.switch(id%)
 ' Calling twm.switch() always resets this even if no actually window switch
 ' is required.
 twm.last_at%=-1
 If twm.id%=id% Then Exit Sub
 twm.lock_vga_cursor(1)
 Local ptr%
 If twm.id%>-1 Then
  ptr%=twm.ptr%(twm.id%)
  Poke Byte ptr%+4,twm.x%
  Poke Byte ptr%+5,twm.y%
  Poke Byte ptr%+6,twm.at%
 EndIf
 twm.id%=id%
 ptr%=twm.ptr%(twm.id%)
 twm.a%=Peek(Byte ptr%+0)
 twm.b%=Peek(Byte ptr%+1)
 twm.w%=Peek(Byte ptr%+2)
 twm.h%=Peek(Byte ptr%+3)
 twm.x%=Peek(Byte ptr%+4)
 twm.y%=Peek(Byte ptr%+5)
 twm.at%=Peek(Byte ptr%+6)
 twm.pc%=ptr%+7
 twm.pa%=twm.pc%+twm.w%*twm.h%
 twm.lock_vga_cursor(0)
End Sub

Sub twm.bold(z%)
 twm.at%=(twm.at% And &b10111111) Or (z%<<6)
End Sub

Sub twm.inverse(z%)
 twm.at%=(twm.at% And &b01111111) Or (z%<<7)
End Sub

' Print s$ at (x%, y%) in the current window.
' Leaves twm.x% and twm.y% one beyond the last printed char position.
Sub twm.print_at(x%,y%,s$)
 twm.lock_vga_cursor(1)
 twm.x%=x%
 twm.y%=y%
 twm.print(s$)
 twm.lock_vga_cursor(0)
End Sub

Sub twm.putc(ch%)
 Local at%=twm.at%
 Local s$=Chr$(ch%)
 Local of%=twm.y%*twm.w%+twm.x%
 Local ax%=twm.a%+twm.x%
 Local by%=twm.b%+twm.y%
 ' Write ch% and at% to twm.data%()
 Poke Byte twm.pc%+of%,ch%
 Poke Byte twm.pa%+of%,at%
 ' Update serial console:
 If twm.last_at%<>at% Then Print vt$; : twm.last_at%=at%
 Print Chr$(27) "[" Str$(by%) ";" Str$(ax%) "H" s$;
 ' Update VGA display:
 If Not twm.console_only% Then
  Text(ax%-1)*twm.fw%,(by%-1)*twm.fh%,s$,,,,twm.fg%(at%),twm.bg%(at%)
  If at% And &b01000000 Then Text(ax%-1)*twm.fw%+1,(by%-1)*twm.fh%,s$,,,,twm.fg%(at%),-1
 EndIf
End Sub

Sub twm.print(s$)
 '  If twm.x% < 0 Or twm.x% >= twm.w% Then Error sys.int_bounds_err$("x", twm.x%, 0, twm.w% - 1)
 '
 '  If twm.y% = twm.h% then the window will immediately scroll before printing the first character.
 '  If twm.y% < 0 Or twm.y% > twm.h% Then Error sys.int_bounds_err$("y", twm.y%, 0, twm.h%)
 Local is%=1                         ' current index into s$
 Local ls%=Len(s$)                   ' length of s$
 Local ps%=Peek(VarAddr s$)          ' pointer to s$
 Local nc%=Min(twm.w%-twm.x%,ls%) ' number of characters to print on the current line
 Local of%                             ' offset for writing to twm.data%()
 Local at%=twm.at%
 Local fg%=twm.fg%(at%)
 Local bg%=twm.bg%(at%)
 Local ax%
 Local by%
 Local seg$
 Local vt$=twm.vt$(at%)
 If nc%=0 Then Exit Sub
 ' Set serial console VT100 attributes
 If twm.last_at%<>at% Then Print vt$; : twm.last_at%=at%
 twm.lock_vga_cursor(1)
 Do
  If twm.y%=twm.h% Then
   twm.scroll_up(1)
   Inc twm.y%,-1
   ' Restore attributes that may have been changed by scroll_up()
   If twm.last_at%<>at% Then Print vt$ : twm.last_at%=at%
  EndIf
  ' Write text and attributes to twm.data%()
  of%=twm.y%*twm.w%+twm.x%
  Memory Copy ps%+is%,twm.pc%+of%,nc%
  Memory Set twm.pa%+of%,at%,nc%
  seg$=Mid$(s$,is%,nc%)
  ax%=twm.a%+twm.x%
  by%=twm.b%+twm.y%
  ' Update serial console:
  Print Chr$(27) "[" Str$(by%) ";" Str$(ax%) "H" seg$;
  ' Update VGA display:
  If Not twm.console_only% Then
   Text(ax%-1)*twm.fw%,(by%-1)*twm.fh%,seg$,,,,fg%,bg%
   If at% And &b01000000 Then Text(ax%-1)*twm.fw%+1,(by%-1)*twm.fh%,seg$,,,,fg%,-1
  EndIf
  Inc is%,nc%
  Inc twm.x%,nc%
  ' Otherwise move to the next line of text.
  If twm.x%=twm.w% Then
   twm.x%=0
   Inc twm.y%
   nc%=Min(twm.w%-twm.x%,ls%-is%+1)
  EndIf
 Loop While is%<=ls%
 twm.lock_vga_cursor(0)
End Sub

Sub twm.scroll_down(redraw%)
 twm.lock_vga_cursor(1)
 Local pa%=twm.pa%+twm.w%*(twm.h%-1)
 Local pc%=twm.pc%+twm.w%*(twm.h%-1)
 Local y%
 Do While pa%>twm.pa%
  ' Copy attribute and character data down one line.
  Memory Copy pa%-twm.w%,pa%,twm.w%
  Memory Copy pc%-twm.w%,pc%,twm.w%
  Inc pa%,-twm.w%
  Inc pc%,-twm.w%
 Loop
 ' Clear the first line using the current attributes.
 Memory Set pa%,twm.at%,twm.w%
 Memory Set pc%,32,twm.w%
 If redraw% Then twm.redraw()
 twm.lock_vga_cursor(0)
End Sub

Sub twm.scroll_up(redraw%)
 twm.lock_vga_cursor(1)
 Local pa%=twm.pa%
 Local pc%=twm.pc%
 Local y%
 For y%=1 To twm.h%-1
  ' Copy attribute and character data from line y + 1 to line y.
  Memory Copy pa%+twm.w%,pa%,twm.w%
  Memory Copy pc%+twm.w%,pc%,twm.w%
  Inc pa%,twm.w%
  Inc pc%,twm.w%
 Next
 ' Clear the last line using the current attributes.
 Memory Set pa%,twm.at%,twm.w%
 Memory Set pc%,32,twm.w%
 If redraw% Then twm.redraw()
 twm.lock_vga_cursor(0)
End Sub

Sub twm.redraw()
 Local at%,ch$,x%,y%
 Local pa%=twm.pa%
 Local pc%=twm.pc%
 Local vx%,vy%
 vy%=(twm.b%-1)*twm.fh%
 For y%=0 To twm.h%-1
  Print Chr$(27) "[" Str$(twm.b%+y%) ";" Str$(twm.a%) "H";
  vx%=(twm.a%-1)*twm.fw%
  For x%=0 To twm.w%-1
   at%=Peek(Byte pa%+x%)
   ch$=Chr$(Peek(Byte pc%+x%))
   ' Update serial console:
   If twm.last_at%<>at% Then Print twm.vt$(at%); : twm.last_at%=at%
   Print ch$;
   ' Update VGA display:
   If Not twm.console_only% Then
    Text vx%,vy%,ch$,,,,twm.fg%(at%),twm.bg%(at%)
    If at% And &b01000000 Then Text vx%+1,vy%,ch$,,,,twm.fg%(at%),-1
   EndIf
   Inc vx%,twm.fw%
  Next ' x%
  Inc pa%,twm.w%
  Inc pc%,twm.w%
  Inc vy%,twm.fh%
 Next ' y%
End Sub

Sub twm.cls(x%,y%,w%,h%)
 twm.lock_vga_cursor(1)
 Local s$=Space$(Choice(w%,w%,twm.w%)),yy%
 For yy%=y% To y%+Choice(h%,h%,twm.h%)-1
  twm.x%=x% : twm.y%=yy%
  twm.print(s$)
 Next
 twm.lock_vga_cursor(0)
End Sub

Sub twm.box(x%,y%,w%,h%)
 Local ad%,i%,pc%=twm.pc%,s$
 twm.lock_vga_cursor(1)
 ' Top
 Poke Var s$,0,w%
 ad%=pc%+twm.w%*y%+x%
 Poke Var s$,1,twm.box_or%(&hC9,Peek(Byte ad%))
 For i%=2 To w%-1
  Poke Var s$,i%,twm.box_or%(&hCD,Peek(Byte ad%+i%-1))
 Next
 Poke Var s$,w%,twm.box_or%(&hBB,Peek(Byte ad%+w%-1))
 twm.print_at(x%,y%,s$)
 ' Sides
 For twm.y%=y%+1 To y%+h%-2
  Inc ad%,twm.w%
  twm.x%=x%
  twm.putc(twm.box_or%(&hBA,Peek(Byte ad%)))
  twm.x%=x%+w%-1
  twm.putc(twm.box_or%(&hBA,Peek(Byte ad%+w%-1)))
 Next
 ' Bottom
 Inc ad%,twm.w%
 Poke Var s$,1,twm.box_or%(&hC8,Peek(Byte ad%))
 For i%=2 To w%-1
  Poke Var s$,i%,twm.box_or%(&hCD,Peek(Byte ad%+i%-1))
 Next
 Poke Var s$,w%,twm.box_or%(&hBC,Peek(Byte ad%+w%-1))
 twm.print_at(x%,y%+h%-1,s$)
 twm.lock_vga_cursor(0)
End Sub

' Combines a new character 'ch%' and an existing character 'ex%'.
' If they are both 'box-drawing' characters then returns an appropriate junction character,
' otherwise returns the new character 'ch%'.
'
' @param ch%  new 'box-drawing' character.
' @param ex%  existing character.
' @return     junction character, or 'ch%'.
Function twm.box_or%(ch%,ex%)
 Local tmp%=twm.c2b%(ch%)
 twm.box_or%=Choice(tmp%=0,ch%,twm.b2c%(tmp% Or twm.c2b%(ex%)))
End Function

' Sends VT100 control-code to hide/show cursor to the serial console.
Sub twm.enable_cursor(z%)
 Local s$=LCase$(Mm.Info$(Option Console))
 Select Case s$
  Case "screen" : Exit Sub
  Case "both"
   ' Note MMB4W cannot call OPTION CONSOLE SERIAL if it is on the same line
   ' as a CASE clause. This is because in MMB4W this OPTION checks
   ' 'CurrentLinePtr' to make sure it is only being used from within a
   ' program. However due to a long-standing and gnarly bug in the MMBasic
   ' core 'CurrentLinePtr' is not correctly set when processing a command on
   ' the same line as a CASE clause.
   Option Console Serial
 End Select
 Print Chr$(27) Choice(z%,"[?25h","[?25l");
 If s$="both" Then Option Console Both
 If z%=twm.cursor_enabled% Then Exit Sub
 twm.cursor_enabled%=z%
 If z% Then
  SetTick 500,twm.update_vga_cursor,4
 Else
  SetTick 0,twm.update_vga_cursor,4
 EndIf
End Sub

' Toggle whether the VGA cursor is lit or not,
' intended to be called as an ISR via SetTick.
Sub twm.update_vga_cursor()
 If twm.console_only% Then Exit Sub
 Static lit%=0
 If twm.cursor_locked% Then Exit Sub
 ' Do not draw the cursor if it is out of bounds,
 ' if there are issues may need to check for < 0 too.
 If twm.x%>=twm.w% Or twm.y%>=twm.h% Then Exit Sub
 lit%=Not lit%
 Local of%=twm.y%*twm.w%+twm.x%
 Local ax%=twm.a%+twm.x%
 Local by%=twm.b%+twm.y%
 Local fg%=Choice(lit%,RGB(Black),RGB(White))
 Text(ax%-1)*twm.fw%,(by%-1)*twm.fh%,"_",,,,fg%,-1
 Text(ax%-1)*twm.fw%,(by%-1)*twm.fh%+1,"_",,,,fg%,-1
End Sub

' Lock/unlock the VGA cursor.
' The cursor should be locked whilst manipulating twm.x% & twm.y%
Sub twm.lock_vga_cursor(lock%)
 If twm.console_only% Then Exit Sub
 Inc twm.cursor_locked%,Choice(lock%,1,-1))
 If twm.id%=-1 Then Exit Sub
 If twm.cursor_locked%<0 Then Error "Unbalanced cursor lock/unlock."
 ' No need to restore cell contents if unlocking.
 If Not lock% Then Exit Sub
 ' Character cell contents has already been restored and we are just counting up.
 If twm.cursor_locked%>1 Then Exit Sub
 ' Do not restore character cell contents if cursor is out of bounds,
 ' if there are issues may need to check for < 0 too.
 If twm.x%>=twm.w% Or twm.y%>=twm.h% Then Exit Sub
 ' Restore character cell contents.
 Local ax%=twm.a%+twm.x%
 Local by%=twm.b%+twm.y%
 Local of%=twm.y%*twm.w%+twm.x%
 Local ch%=Peek(Byte twm.pc%+of%)
 Local at%=Peek(Byte twm.pa%+of%)
 Local fg%=twm.fg%(at%)
 Text(ax%-1)*twm.fw%,(by%-1)*twm.fh%,Chr$(ch%),,,,fg%,twm.bg%(at%)
 If at% And &b01000000 Then Text(ax%-1)*twm.fw%+1,(by%-1)*twm.fh%,Chr$(ch%),,,,fg%,-1
End Sub

' ---- src/splib/txtwm.inc
' src/splib/file.inc ++++
' Copyright (c) 2020-2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00
Const file.SEPARATOR=sys.SEPARATOR$()
' Gets the number of files in directory d$ whose names match pattern$.
'
' @param   d$        directory to process.
' @param   pattern$  file pattern to match on, e.g. "*.bas".
' @param   type$     type of files to return: "dir", "file" or "all".
' @return  the number of matching files.
Function file.count_files%(d$,pattern$,type$)
 If Not file.is_directory%(d$) Then
  file.count_files%=sys.error%(sys.FAILURE,"Not a directory '"+d$+"'")
  Exit Function
 EndIf
 Local f$
 Select Case LCase$(type$)
  Case "all"
   f$=Dir$(d$+"/*",All)
  Case "dir"
   f$=Dir$(d$+"/*",Dir)
  Case "file",""
   f$=Dir$(d$+"/*",File)
  Case Else
   file.count_files%=sys.error%(sys.FAILURE,"Invalid file type '"+type$+"'")
   Exit Function
  EndIf
End Select
Do While f$<>""
 If file.fnmatch%(pattern$,f$) Then Inc file.count_files%
 f$=Dir$()
Loop
End Function

' Does the file/directory 'f$' exist?
'
' @param  f$     name/path of file/directory
' @param  type$  type of files to check for: "dir", "file" or "all".
' @return        1 if the file/directory exists, otherwise 0
Function file.exists%(f$,type$)
 Local f_$=Choice(Len(f$),f$,"."),i%
 Local type_$="|"+Choice(Len(type$),LCase$(type$),"all")+"|"
 If f_$="." Then f_$=Cwd$
 If Len(f_$)=2 Then
  If Mid$(f_$,2,1)=":" Then Cat f_$,"/"
 EndIf
 For i%=1 To Len(f_$)
  If Peek(Var f_$,i%)=92 Then Poke Var f_$,i%,47
 Next
 If InStr("|file|all|",type_$) Then Inc file.exists%,Mm.Info(Exists File f_$)
 If InStr("|dir|all|",type_$) Then Inc file.exists%,Mm.Info(Exists Dir f_$)
 file.exists%=file.exists%>0
End Function

' Does name$ match pattern$ ?
'
' @param   pattern$  *nix style 'shell wildcard' pattern.
' @param   name$     the name to test.
' @return  1 if the name matches the pattern otherwise 0.
'
' Derived from the work of Russ Cox: https://research.swtch.com/glob
Function file.fnmatch%(pattern$,name$)
 Local p$=UCase$(pattern$)
 Local n$=UCase$(name$)
 Local c%,px%=1,nx%=1,nextPx%=0,nextNx%=0
 Do While px%<=Len(p$) Or nx%<=Len(n$)
  If px%<=Len(p$) Then
   c%=Peek(Var p$,px%)
   Select Case c%
    Case 42 ' *
     ' Zero-or-more-character wildcard
     ' Try to match at sx%,
     ' if that doesn't work out,
     ' restart at nx%+1 next.
     nextPx%=px%
     nextNx%=nx%+1
     Inc px%
     Goto file.fnmatch_cont
    Case 63 ' ?
     ' Single-character wildcard
     If nx%<=Len(n$) Then
      Inc px%
      Inc nx%
      Goto file.fnmatch_cont
     EndIf
    Case Else
     ' Ordinary character
     If nx%<=Len(n$) Then
      If c%=Peek(Var n$,nx%) Then
       Inc px%
       Inc nx%
       Goto file.fnmatch_cont
      EndIf
     EndIf
   End Select
  EndIf
  If nextNx%>0 Then
   If nextNx%<=Len(n$)+1 Then
    px%=nextPx%
    nx%=nextNx%
    Goto file.fnmatch_cont
   EndIf
  EndIf
  Exit Function
file.fnmatch_cont:
 Loop
 file.fnmatch%=1
End Function

' Gets the canonical path for file/directory 'f$'.
Function file.get_canonical$(f$)
 Local tmp$=f$
 Local current$=Cwd$
 If InStr("/\",Right$(current$,1)) Then current$=Left$(current$,Len(current$)-1)
 Select Case Left$(tmp$,1)
  Case "/","\"
   tmp$="A:"+tmp$
  Case "~"
   If tmp$="~" Then
    tmp$=sys.HOME$()
   ElseIf Left$(tmp$,2)="~/" Or Left$(tmp$,2)="~\" Then
    tmp$=sys.HOME$()+Mid$(tmp$,2)
   Else
    tmp$=Cwd$+"/"+tmp$
   EndIf
  Case "a" To "z","A" To "Z"
   If Mid$(tmp$,2,1)=":" Then
    ' Do nothing
   Else
    tmp$=Cwd$+"/"+tmp$
   EndIf
  Case Else
   tmp$=Cwd$+"/"+tmp$
 End Select
 ' Convert backslash to slash to simplify algorithm.
 ' On Windows we convert back to backslash before returning the result.
 Local i%
 For i%=1 To Len(tmp$)
  If Peek(Var tmp$,i%)=92 Then Poke Var tmp$,i%,47
 Next
 ' Capitalise first letter of a drive specification.
 If Mid$(tmp$,2,1)=":" Then Poke Var tmp$,1,Asc(UCase$(Chr$(Peek(Var tmp$,1))))
 ' Ensure there is a trailing slash,
 ' this helps with the next step and is ultimately stripped off.
 If Right$(tmp$,1)<>"/" Then Cat tmp$,"/"
 ' Process dot, dot-dot and consecutive slash characters.
 file.get_canonical$=tmp$
 tmp$=""
 Local ch%,j%,s$=""
 For i%=1 To Len(file.get_canonical$)+1
  ch%=Peek(Var file.get_canonical$,i%)
  Select Case ch%
   Case 47 ' /
    Select Case s$
     Case "/","/."
      ' Do nothing
     Case "/.."
      ' Back track
      For j%=Len(tmp$) To 1 Step -1
       If Peek(Var tmp$,j%)=47 Then
        Poke Var tmp$,0,j%-1 : Exit For
       EndIf
      Next
     Case Else
      Cat tmp$,s$
    End Select
    s$="/"
   Case Else
    Cat s$,Chr$(ch%)
  End Select
 Next
 ' On Windows convert slash to backslash.
 If Mm.Device$="MMBasic for Windows" Then
  For i%=1 To Len(tmp$)
   If Peek(Var tmp$,i%)=47 Then Poke Var tmp$,i%,92
  Next
 EndIf
 file.get_canonical$=tmp$
End Function

' Gets the dot file-extension, from filename f$.
' e.g. file.get_extension("foo.bas") => ".bas"
Function file.get_extension$(f$)
 Local i%
 For i%=Len(f$) To 1 Step -1
  Select Case Peek(Var f$,i%)
   Case 46     ' .
    file.get_extension$=Mid$(f$,i%)
    Exit Function
   Case 47,92 ' / or \
    Exit For
  End Select
 Next
End Function

' Gets the files in directory d$ whose names match pattern$.
'
' @param       d$         directory to process.
' @param       pattern$   file pattern to match on, e.g. "*.bas".
' @param       type$      type of files to return: "dir", "file" or "all".
' @param[out]  onames$()  the names of matching files are copied into this array.
'                         If there are too many matching files then this array
'                         will be incomplete, but the returned number of files
'                         will be correct.
' @return                 the number of files matching the pattern.
Function file.get_files%(d$,pattern$,type$,onames$())
 If Not file.is_directory%(d$) Then
  file.get_files%=sys.error%(sys.FAILURE,"Not a directory '"+d$+"'")
  Exit Function
 EndIf
 Local f$
 Select Case LCase$(type$)
  Case "all"
   f$=Dir$(d$+"/*",All)
  Case "dir"
   f$=Dir$(d$+"/*",Dir)
  Case "file",""
   f$=Dir$(d$+"/*",File)
  Case Else
   file.get_files%=sys.error%(sys.FAILURE,"Invalid file type '"+type$+"'")
   Exit Function
 End Select
 Local i%=Mm.Info(Option Base)
 Do While f$<>""
  If file.fnmatch%(pattern$,f$) Then
   If i%<=Bound(onames$(),1) Then onames$(i%)=f$ : Inc i%
   Inc file.get_files%
  EndIf
  f$=Dir$()
 Loop
 If file.get_files%>0 Then
  Sort onames$(),,&b10,Mm.Info(Option Base),i%-Mm.Info(Option Base)
 EndIf
End Function

' Gets the name of file/directory 'f$' minus any path information.
Function file.get_name$(f$)
 Local i%
 For i%=Len(f$) To 1 Step -1
  If InStr("/\",Mid$(f$,i%,1))>0 Then Exit For
 Next
 file.get_name$=Mid$(f$,i%+1)
End Function

' Gets the parent directory of 'f$', or the empty string if it does not have one.
Function file.get_parent$(f$)
 Select Case Len(f$)
  Case 1
   If f$="/" Or f$="\" Then Exit Function
  Case 2
   If Mid$(f$,2,1)=":" Then Exit Function
  Case 3
   Select Case Right$(f$,2)
    Case ":/",":\"
     Exit Function
   End Select
 End Select
 Local i%
 For i%=Len(f$) To 1 Step -1
  If InStr("/\",Mid$(f$,i%,1))>0 Then Exit For
 Next
 If i%>0 Then file.get_parent$=Left$(f$,i%-1)
 If file.get_parent$="" Then
  If InStr("/\",Left$(f$,1)) Then file.get_parent$=Left$(f$,1)
 EndIf
End Function

Function file.is_directory%(f$)
 file.is_directory%=file.exists%(f$,"dir")
End Function

' Makes directory 'f$' and its parents if they do not already exist.
Function file.mkdir%(f$)
 Local ad%,faddr%=Peek(VarAddr f$),parent$
 sys.err$=""
 For ad%=faddr%+1 To faddr%+Len(f$)
  Select Case Peek(Byte ad%)
   Case 47,92 ' / and \
    parent$=Left$(f$,ad%-faddr%-1)
    If file.exists%(parent$) Then
     If Not file.is_directory%(parent$) Then
      file.mkdir%=sys.error%(sys.FAILURE,"File exists")
      Exit Function
     EndIf
    Else
     If parent$<>"" Then MkDir parent$
    EndIf
  End Select
 Next
 If file.exists%(f$) Then
  If Not file.is_directory%(f$) Then file.mkdir%=sys.error%(sys.FAILURE,"File exists")
 Else
  MkDir f$
 EndIf
End Function

' Returns a copy of f$ with any dot file-extension removed.
' e.g. file.trim_extension("foo.bas") => "foo"
Function file.trim_extension$(f$)
 Local i%
 For i%=Len(f$) To 1 Step -1
  Select Case Peek(Var f$,i%)
   Case 46     ' .
    file.trim_extension$=Mid$(f$,1,i%-1)
    Exit Function
   Case 47,92 ' / or \
    Exit For
  End Select
 Next
 file.trim_extension$=f$
End Function

' ---- src/splib/file.inc
' src/splib/crypt.inc ++++
' Copyright (c) 2021-2025 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.00
' MD5 algorithm from https://en.wikipedia.org/wiki/MD5
' XXTEA algorithm from https://en.wikipedia.org/wiki/XXTEA
' Calculates the MD5 hash of bytes held in a buffer.
'
' To calculate the MD5 hash of a string s$:
'   ok% = crypt.md5%(Peek(VarAddr s$) + 1, Len(s$), md5%())
'
' To calculate the MD5 hash of a long string ls%():
'   ok% = crypt.md5%(Peek(VarAddr ls%()) + 8, LLen(ls%()), md5%())
'
' @param       ad%      address of the buffer.
' @param       size%    number of bytes to process.
' @param[out]  omd5%()  on return the MD5 hash in little-endian format
'                       (2 elements = 16 bytes = 128-bits)
' @return               1 on success, 0 on failure, see sys.err$ for details of failure.
Function crypt.md5%(ad%,size%,omd5%())
 If Bound(omd5%(),1)-Bound(omd5%(),0)<>1 Then Error "omd5%() should have 2 elements"
 Local block%(array.new%(64))
 Const b_addr%=Peek(VarAddr block%())
 ' Storage for hash, each element treated as 32-bit unsigned integer.
 Local h%(array.new%(4))
 ' Storage for constants, each element treated as 32-bit unsigned integer.
 Local r%(array.new%(64))
 Local k%(array.new%(64))
 Local cur%=0,num%
 Do
  ' Process blocks of 64 bytes / 512 bits at a time.
  num%=Min(size%-cur%,64)
  Memory Set b_addr%,0,64
  Memory Copy ad%+cur%,b_addr%,num%
  If num%<64 Then
   ' Append '1' bit to block%, the remainder will already be padded with zeros.
   Poke Byte b_addr%+num%,&h80
   If num%>55 Then
    crypt.md5_block(block%(),h%(),r%(),k%())
    Memory Set b_addr%,0,64
   EndIf
   ' Last 64-bits of block% should be data length in bits as a 64-bit little-endian integer.
   Poke Integer b_addr%+56,size%*8
  EndIf
  crypt.md5_block(block%(),h%(),r%(),k%())
  Inc cur%,64
 Loop While num%=64
 Const BASE%=Mm.Info(Option Base)
 omd5%(BASE%)=h%(BASE%) Or h%(BASE%+1)<<32
 omd5%(BASE%+1)=h%(BASE%+2) Or h%(BASE%+3)<<32
 crypt.md5%=1
End Function

' Process 512-bit block in MD5 hash calculation.
'
' @param  block%()  512-bit block to process (64 elements).
' @param  h%()      hash-values (4 elements).
' @param  r%()      per-round shift amounts (64 elements).
' @param  k%()      binary integer part of the sines of integers (Radians) as constants (64 elements).
Sub crypt.md5_block(block%(),h%(),r%(),k%())
 Const BASE%=Mm.Info(Option Base)
 ' Note that all variables should be treated as unsigned 32-bit integers
 ' and wrap modulo 2^32 when calculating.
 ' Initialise hash and constants if this is the first call.
 Local i%
 If r%(BASE%)=0 Then
  On Error Skip 1
  Read Save ' Save the global DATA pointer, may not be implemented.
  Restore crypt.md5_data
  For i%=Bound(h%(),0) To Bound(h%(),1) : Read h%(i%) : Next
  For i%=Bound(r%(),0) To Bound(r%(),1) : Read r%(i%) : Next
  For i%=Bound(k%(),0) To Bound(k%(),1) : Read k%(i%) : Next
  On Error Skip 1
  Read Restore ' Restore the global DATA pointer, may not be implemented.
 EndIf
 ' Split block into 16 x 32-bit words.
 Local b_addr%=Peek(VarAddr block%())
 Local w%(array.new%(16))
 For i%=0 To 15
  w%(i%+BASE%)=Peek(Word b_addr%+4*i%)
 Next
 ' Main loop.
 Local a%=h%(BASE%),b%=h%(BASE%+1),c%=h%(BASE%+2),d%=h%(BASE%+3),f%,g%,tmp%
 For i%=0 To 63
  Select Case i%
   Case 0 To 15
    f%=d% Xor(b% And (c% Xor d%))
    g%=i%
   Case 16 To 31
    f%=c% Xor(d% And (b% Xor c%))
    g%=(5*i%+1) Mod 16
   Case 32 To 47
    f%=b% Xor c% Xor d%
    g%=(3*i%+5) Mod 16
   Case Else :
    f%=c% Xor(b% Or (d% Xor &hFFFFFFFF))
    g%=(7*i%) Mod 16
  End Select
  tmp%=d%
  d%=c%
  c%=b%
  b%=(a%+f%) And &hFFFFFFFF
  b%=(b%+k%(i%+BASE%)) And &hFFFFFFFF
  b%=(b%+w%(g%+BASE%)) And &hFFFFFFFF
  b%=(b%<<r%(i%+BASE%)) Or (b%>>(32-r%(i%+BASE%)))
  b%=(b%+c%) And &hFFFFFFFF
  a%=tmp%
 Next
 ' Add this block's hash to the result.
 h%(BASE%)=(h%(BASE%)+a%) And &hFFFFFFFF
 h%(BASE%+1)=(h%(BASE%+1)+b%) And &hFFFFFFFF
 h%(BASE%+2)=(h%(BASE%+2)+c%) And &hFFFFFFFF
 h%(BASE%+3)=(h%(BASE%+3)+d%) And &hFFFFFFFF
End Sub

' Data for initialising MD5 constants.
crypt.md5_data:
' 4 x 32-bit values to initialise hash 'h'
DATA &h67452301,&hEFCDAB89,&h98BADCFE,&h10325476
' 64 x 32-bit values for 'r'
DATA &h00000007,&h0000000C,&h00000011,&h00000016,&h00000007,&h0000000C,&h00000011,&h00000016
DATA &h00000007,&h0000000C,&h00000011,&h00000016,&h00000007,&h0000000C,&h00000011,&h00000016
DATA &h00000005,&h00000009,&h0000000E,&h00000014,&h00000005,&h00000009,&h0000000E,&h00000014
DATA &h00000005,&h00000009,&h0000000E,&h00000014,&h00000005,&h00000009,&h0000000E,&h00000014
DATA &h00000004,&h0000000B,&h00000010,&h00000017,&h00000004,&h0000000B,&h00000010,&h00000017
DATA &h00000004,&h0000000B,&h00000010,&h00000017,&h00000004,&h0000000B,&h00000010,&h00000017
DATA &h00000006,&h0000000A,&h0000000F,&h00000015,&h00000006,&h0000000A,&h0000000F,&h00000015
DATA &h00000006,&h0000000A,&h0000000F,&h00000015,&h00000006,&h0000000A,&h0000000F,&h00000015
' 64 x 32-bit values for 'k'
DATA &hD76AA478,&hE8C7B756,&h242070DB,&hC1BDCEEE,&hF57C0FAF,&h4787C62A,&hA8304613,&hFD469501
DATA &h698098D8,&h8B44F7AF,&hFFFF5BB1,&h895CD7BE,&h6B901122,&hFD987193,&hA679438E,&h49B40821
DATA &hF61E2562,&hC040B340,&h265E5A51,&hE9B6C7AA,&hD62F105D,&h02441453,&hD8A1E681,&hE7D3FBC8
DATA &h21E1CDE6,&hC33707D6,&hF4D50D87,&h455A14ED,&hA9E3E905,&hFCEFA3F8,&h676F02D9,&h8D2A4C8A
DATA &hFFFA3942,&h8771F681,&h6D9D6122,&hFDE5380C,&hA4BEEA44,&h4BDECFA9,&hF6BB4B60,&hBEBFBC70
DATA &h289B7EC6,&hEAA127FA,&hD4EF3085,&h04881D05,&hD9D4D039,&hE6DB99E5,&h1FA27CF8,&hC4AC5665
DATA &hF4292244,&h432AFF97,&hAB9423A7,&hFC93A039,&h655B59C3,&h8F0CCC92,&hFFEFF47D,&h85845DD1
DATA &h6FA87E4F,&hFE2CE6E0,&hA3014314,&h4E0811A1,&hF7537E82,&hBD3AF235,&h2AD7D2BB,&hEB86D391
' Encrypts/decrypts file using XXTEA/CBC/PKCS#7 algorithm.
'
' @param  cmd$       command to perform, either "encrypt" or "decrypt".
' @param  in_fd%     reads input from this file descriptor.
' @param  out_fd%    writes output to this file descriptor.
' @param  k%()       encryption key (2 elements = 16 bytes = 128-bits).
' @param  iv%()      initialisation vector (2 elements = 16 bytes = 128-bits),
'                    this is ignored when cmd$ = "decrypt".
' @return            1 on success, 0 on failure, see sys.err$ for details of failure.
Function crypt.xxtea_file%(cmd$,in_fd%,out_fd%,k%(),iv%())
 If Bound(k%(),1)-Bound(k%(),0)<>1 Then Error "k%() should have 2 elements"
 If Bound(iv%(),1)-Bound(iv%(),0)<>1 Then Error "iv%() should have 2 elements"
 Local s$,num%
 Const s_addr%=Peek(VarAddr s$)
 Local block%(array.new%(2)) ' 16-bytes = 128-bits
 Const b_addr%=Peek(VarAddr block%())
 Local iv2%(array.new%(2)) ' 16-bytes = 128-bits
 Const iv2_addr%=Peek(VarAddr iv2%())
 If cmd$="encrypt" Then
  ' Write 128-bit initialisation vector.
  Poke Byte s_addr%,16
  Memory Copy Peek(VarAddr iv%()),s_addr%+1,16
  Print #out_fd%,s$;
  ' iv2%() = iv%()
  Memory Copy Peek(VarAddr iv%()),iv2_addr%,16
  Do
   ' Read 128-bit block.
   s$=Input$(16,#in_fd%)
   num%=Len(s$)
   If num%>0 Then Memory Copy s_addr%+1,b_addr%,num%
   ' If we read a block of N bytes where N < 16 bytes long then we append PKCS#7
   ' padding of 16 - N bytes each of value 16 - N. In the event the input file
   ' size is an exact multiple of 16 then we append 16 bytes of value 16.
   If num%<16 Then Memory Set b_addr%+num%,16-num%,16-num%
   ' Implement CBC by XORing iv2%() with block%().
   Poke Integer b_addr%,Peek(Integer b_addr%) Xor Peek(Integer iv2_addr%)
   Poke Integer b_addr%+8,Peek(Integer b_addr%+8) Xor Peek(Integer iv2_addr%+8)
   ' Encrypt block.
   If Not crypt.xxtea_block%(cmd$,block%(),k%()) Then Exit Do
   ' Write 128-bit block.
   Poke Byte s_addr%,16
   Memory Copy b_addr%,s_addr%+1,16
   Print #out_fd%,s$;
   ' iv2%() = block%()
   Memory Copy b_addr%,iv2_addr%,16
  Loop Until num%<16
 ElseIf cmd$="decrypt" Then
  Local iv3%(array.new%(2))
  Local iv3_addr%=Peek(VarAddr iv3%())
  ' Read 128-bit initialisation vector.
  s$=Input$(16,#in_fd%)
  If Len(s$)<16 Then
   sys.err$="encrypted file too short: "+Str$(Len(s$))+" bytes"
   Exit Function
  EndIf
  Memory Copy s_addr%+1,iv2_addr%,16
  Do
   ' Read 128-bit block.
   s$=Input$(16,#in_fd%)
   If Len(s$)<16 Then
    sys.err$="encrypted file length not multiple of 16 bytes"
    Exit Function
   EndIf
   Memory Copy s_addr%+1,b_addr%,16
   ' iv3%() = block%(), which we will need for the next iteration.
   Memory Copy b_addr%,iv3_addr%,16
   ' Decrypt block.
   If Not crypt.xxtea_block%(cmd$,block%(),k%()) Then Exit Function
   ' Implement CBC by XORing iv2%() with block%().
   Poke Integer b_addr%,Peek(Integer b_addr%) Xor Peek(Integer iv2_addr%)
   Poke Integer b_addr%+8,Peek(Integer b_addr%+8) Xor Peek(Integer iv2_addr%+8)
   ' iv2%() = iv3%()
   Memory Copy iv3_addr%,iv2_addr%,16
   ' If we've reached the EOF then we do not want to write the entire
   ' block, the last byte in the block will indicate the number of bytes
   ' we should ignore, which may be the entire block.
   num%=Choice(Eof(#in_fd%),16-Peek(Byte b_addr%+15),16)
   ' Write block.
   Poke Byte s_addr%,num%
   If num%>0 Then Memory Copy b_addr%,s_addr%+1,num%
   Print #out_fd%,s$;
  Loop Until num%<16
 Else
  Error "Unknown encryption command: "+cmd$
 EndIf
 crypt.xxtea_file%=1
End Function

' Encrypts/decrypts block using XXTEA algorithm.
'
' @param  cmd$      command to perform, either "encrypt" or "decrypt".
' @param  block%()  data to encrypted, interpreted as 32-bit words.
' @param  k%()      encryption key (2 elements = 16 bytes = 128-bits).
' @return           1 on success, 0 on failure, see sys.err$ for details of failure.
Function crypt.xxtea_block%(cmd$,block%(),k%())
 Const DELTA%=&h9e3779b9 ' 4-bytes
 Const b_addr%=Peek(VarAddr block%())
 Const k_addr%=Peek(VarAddr k%())
 Const N%=2*(Bound(block%(),1)-Bound(block%(),0)+1)
 Local rounds%=6+52\N%
 Local sum%,y%,z%,e%,p%
 If cmd$="encrypt" Then
  sum%=0
  y%=0
  z%=Peek(Word b_addr%+4*(N%-1))
  Do
   sum%=(sum%+DELTA%) And &hFFFFFFFF
   e%=(sum%>>2) And 3
   For p%=0 To N%-2
    y%=Peek(Word b_addr%+4*(p%+1))
    z%=(Peek(Word b_addr%+4*p%)+crypt.mx%(y%,z%,sum%,k_addr%,p%,e%)) And &hFFFFFFFF
    Poke Word b_addr%+4*p%,z%
   Next
   y%=Peek(Word b_addr%)
   z%=(Peek(Word b_addr%+4*(N%-1))+crypt.mx%(y%,z%,sum%,k_addr%,p%,e%)) And &hFFFFFFFF
   Poke Word b_addr%+4*(N%-1),z%
   Inc rounds%,-1
  Loop While rounds%
 ElseIf cmd$="decrypt" Then
  sum%=rounds%*DELTA%
  y%=Peek(Word b_addr%)
  z%=0
  Do
   e%=(sum%>>2) And 3
   For p%=N%-1 To 1 Step -1
    z%=Peek(Word b_addr%+4*(p%-1))
    y%=(Peek(Word b_addr%+4*p%)-crypt.mx%(y%,z%,sum%,k_addr%,p%,e%)) And &hFFFFFFFF
    Poke Word b_addr%+4*p%,y%
   Next
   z%=Peek(Word b_addr%+4*(N%-1))
   y%=(Peek(Word b_addr%)-crypt.mx%(y%,z%,sum%,k_addr%,p%,e%)) And &hFFFFFFFF
   Poke Word b_addr%,y%
   sum%=(sum%-DELTA%) And &hFFFFFFFF
   Inc rounds%,-1
  Loop While rounds%
 Else
  Error "Unknown encryption command: "+cmd$
 EndIf
 crypt.xxtea_block%=1
End Function

Function crypt.mx%(y%,z%,sum%,k_addr%,p%,e%)
 Local lhs%=(z%>>5) Xor((y%<<2) And &hFFFFFFFF)
 Inc lhs%,(y%>>3) Xor((z%<<4) And &hFFFFFFFF)
 Local rhs%=(sum% Xor y%)+(Peek(Word k_addr%+4*((p% And 3) Xor e%)) Xor z%)
 crypt.mx%=(lhs% And &hFFFFFFFF) Xor(rhs% And &hFFFFFFFF)
End Function

' ---- src/splib/crypt.inc
' src/splib/inifile.inc ++++
' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Reads key/value pairs from a .INI file into a map.
'
' @param       fd%    file descriptor of open file to read from.
' @param[out]  mp$()  map to add key/value pairs to, this is not cleared first.
' @param[out]  num%   the number of key/value pairs read.
' @return             1 on success, 0 on failure, see sys.err$ for details of failure.
' @errors             "too many values" if the map overflows;
'                     num% will contain the TOTAL number of key/value pairs in the file.
'                     "missing key"     if a value appears without a key.
'                     "missing value"   if a key appears without a value.
Function inifile.read%(fd%,mp$(),num%)
 Local lc%,s$,key$,value$,p%
 Const free%=map.capacity%(mp$())-map.size%(mp$())
 ' TODO: support quoted string values.
 ' TODO: support escapes for = and ; characters.
 num%=0
 Do While Not Eof(fd%)
  Line Input #fd%,s$
  If free%>=0 Then Inc lc%
  p%=InStr(s$,";")
  If p%>0 Then s$=Left$(s$,p%-1)
  s$=str.trim$(s$)
  If s$="" Then Continue Do
  p%=InStr(s$,"=")
  key$=Choice(p%=0,s$,str.trim$(Left$(s$,p%-1)))
  value$=Choice(p%=0,"",str.trim$(Mid$(s$,p%+1)))
  If key$="" Then sys.err$="missing key"
  If value$="" And p%=0 Then sys.err$="missing value"
  If sys.err$<>"" Then Exit Do
  Inc num%
  If num%<=free% Then map.put(mp$(),key$,value$)
 Loop
 If num%>free% Then sys.err$="too many values"
 If sys.err$<>"" Then Cat sys.err$," (line "+Str$(lc%)+")"
 inifile.read%=(sys.err$="")
End Function

' Writes key/value pairs from a map into a .INI file.
'
' @param       fd%    file descriptor of open file to write to.
' @param       mp$()  map of key/value pairs to write.
' @param[out]  num%   the number of key/value pairs written.
' @return             1 on success, 0 on failure, see sys.err$ for details of failure.
Function inifile.write%(fd%,mp$(),num%)
 Local i%
 Local lb%=Bound(mp$(),0)
 Local ub%=map.size%(mp$())-1+lb%
 num%=0
 For i%=lb% To ub%
  Print #fd%,mp$(i%) " = " map.get$(mp$(),mp$(i%))
  Inc num%
 Next
 inifile.write%=1
End Function

' ---- src/splib/inifile.inc
' src/splib/math.inc ++++
' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
' Generates a pseudo random integer between 1 and 'range%' inclusive.
'
' @param  range%  if > 0 then upper bound of generated number,
'                 if = 0 then reinitialises seed based on Timer value,
'                 if < 0 then sets seed to Abs(range%)
Function math.pseudo_rnd%(range%)
 Static x%=Timer ' 7
 Static a%=1103515245
 Static c%=12345
 Static m%=2^31
 If range%=0 Then
  x%=Timer
 ElseIf range%<0 Then
  x%=Abs(range%)
 Else
  x%=(a%*x%+c%) Mod m%
  math.pseudo_rnd%=1+CInt((range%-1)*(x%/m%))
 EndIf
End Function

' ---- src/splib/math.inc
' src/splib/vt100.inc ++++
' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07
Function vt100$(s$)
 vt100$=Chr$(27)+"["+s$
End Function

Function vt100.colour$(c$)
 Select Case LCase$(c$)
  Case "black" : vt100.colour$=vt100$("30m")
  Case "red" : vt100.colour$=vt100$("31m")
  Case "green" : vt100.colour$=vt100$("32m")
  Case "yellow" : vt100.colour$=vt100$("33m")
  Case "blue" : vt100.colour$=vt100$("34m")
  Case "magenta","purple" : vt100.colour$=vt100$("35m")
  Case "cyan" : vt100.colour$=vt100$("36m")
  Case "white" : vt100.colour$=vt100$("37m")
  Case "reset" : vt100.colour$=vt100$("0m")
  Case Else : Error "Unknown VT100 colour: "+c$
 End Select
End Function

' ---- src/splib/vt100.inc
' src/advent.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley
' Based on original TRS-80 Level II BASIC code (c) 1978 Scott Adams
' For MMBasic 6
' This file declares the variables that hold the (read-only) adventure
' data/structure and contains the subroutines that fill those
' variables from '.dat' files in ScottFree format.
Const advent.FD_IN%=1
Dim advent.file$    ' Data file for the current adventure
Dim advent.buf$     ' 255 char buffer for reading adventure files
Dim advent.buf_ptr% ' Current position within the buffer
Dim advent.txt_sz% ' Minimum number of bytes required to contain all text (UNUSED)
Dim il ' Highest numbered object 0..il
Dim cl ' Highest action number 0..cl
Dim nl ' Highest vocabulary number 0..nl
Dim rl ' Highest room number 0..rl
Dim mx ' Maximum number of objects carried
Dim ar ' Starting room
Dim tt ' Number of treasures
Dim ln ' Word length
Dim lt ' Time limit
Dim ml ' Highest message number
Dim tr ' Treasure room
' Reads a '.dat' file.
Sub advent.read_dat(f$)
 advent.free()
 advent.file$=Choice(LCase$(file.get_extension$(f$))=".dat",f$,f$+".dat")
 Open advent.file$ For Input As advent.FD_IN%
 advent.buf$=""
 advent.buf_ptr%=1
 advent.read_header()
 advent.read_action_table()
 advent.read_vocab_table()
 advent.read_rooms()
 advent.read_messages()
 advent.read_objects()
 Close advent.FD_IN%
End Sub

Sub advent.read_header()
 advent.txt_sz%=advent.read_int%()
 il=advent.read_int%()
 cl=advent.read_int%()
 nl=advent.read_int%()
 rl=advent.read_int%()
 mx=advent.read_int%()
 ar=advent.read_int%()
 tt=advent.read_int%()
 ln=advent.read_int%()
 lt=advent.read_int%()
 ml=advent.read_int%()
 tr=advent.read_int%()
 ' The interpreter expects at least 10 objects, numbered from 0,
 ' this is so the artifical light source (hardcoded as object 9) exists.
 If il<9 Then Error "a well formed adventure must contain at least 10 objects"
 ' The interpreter expects at least 19 verbs, numbered from 0,
 ' this is so that DROP (hardcoded as verb 18) exists.
 If nl<18 Then Error "a well formed adventure must contain at least 19 verbs"
 Dim ca(cl,7)      ' action table
 Dim nv_str$(nl,1) ' vocabulary table - verbs at index 0, nouns at index 1
 Dim ia_str$(il)    ' object descriptions
 Dim advent.obj_rm%(il) ' initial object locations
 Dim rs$(rl)        ' room descriptions
 Dim rm(rl,5)      ' room exits: N, S, E, W, U, D
 Dim ms$(ml)        ' messages table
End Sub

Function advent.read_int%()
 Local ch%,s$
 ' Look for opening minus-sign or digit.
 Do
  ch%=advent.peek_char%()
  Select Case ch%
   Case 10,13,32
    Inc advent.buf_ptr%
   Case 45 ' minus sign
    s$="-"
    Inc advent.buf_ptr%
    Exit Do
   Case 48 To 57 ' digits
    Exit Do
   Case Else
    Error "looking for integer, found: "+Chr$(ch%)
  End Select
 Loop
 ' Accumulate digits.
 Do
  ch%=advent.peek_char%()
  Inc advent.buf_ptr%
  Select Case ch%
   Case 48 To 57 : Cat s$,Chr$(ch%)
   Case Else : Exit Do
  End Select
 Loop
 advent.read_int%=Val(s$)
End Function

Function advent.peek_char%()
 If advent.buf_ptr%>Len(advent.buf$) Then
  advent.buf_ptr%=1
  advent.buf$=Input$(255,advent.FD_IN%)
  If advent.buf$="" Then Error "adventure file is truncated: "+file.get_name$(advent.file$)
 EndIf
 advent.peek_char%=Peek(Var advent.buf$,advent.buf_ptr%)
End Function

' Reads a quoted string that might be spread over several lines.
Function advent.read_string$()
 Local ch%,s$
 ' Look for opening quote.
 Do
  ch%=advent.peek_char%()
  Select Case ch%
   Case 10,13,32 ' line-feed, carriage-return and space
    Inc advent.buf_ptr%
   Case 34 ' double quotation mark
    Inc advent.buf_ptr%
    Exit Do
   Case Else
    Error "looking for opening-quote, found: "+Chr$(ch%)
  End Select
 Loop
 ' Accumulate string until find closing quote.
 Do
  ch%=advent.peek_char%()
  Inc advent.buf_ptr%
  Select Case ch%
   Case 10 ' \n - line feed
    Cat s$,sys.CRLF$
   Case 13 ' \r - carriage return
    If advent.peek_char%()<>10 Then Cat s$,sys.CRLF$
   Case 34
    Exit Do
   Case Else
    Cat s$,Chr$(ch%)
  End Select
 Loop
 advent.read_string$=s$
End Function

Sub advent.read_action_table()
 Local i,j
 For i=0 To cl
  For j=0 To 7
   ca(i,j)=advent.read_int%()
  Next j
 Next i
End Sub

Sub advent.read_vocab_table()
 Local i%,j%,s$
 For i%=0 To nl
  For j%=0 To 1 ' 0 is verb, 1 is noun.
   s$=advent.read_string$()
   ' Not sure what these . and *. entries are, but suspect they are crud.
   ' Until I learn better replace them with empty string, or previous word as appropriate.
   Select Case s$
    Case "." : nv_str$(i%,j%)=""
    Case "*." : nv_str$(i%,j%)=nv_str$(i%-1,j%)
    Case Else : nv_str$(i%,j%)=s$
   End Select
  Next
 Next
End Sub

Sub advent.read_rooms()
 Local i,j
 For i=0 To rl
  For j=0 To 5
   rm(i,j)=advent.read_int%()
  Next
  rs$(i)=advent.read_string$()
 Next
End Sub

Sub advent.read_messages()
 Local i
 For i=0 To ml
  ms$(i)=advent.read_string$()
 Next
End Sub

Sub advent.read_objects()
 Local i
 For i=0 To il
  ' Trim the object name because the " * RUBY */RUB/" treasure in "advent08.dat" (Pyramid of Doom)
  ' has a leading space which otherwise breaks its recognition as a treasure; due to the name not
  ' starting with a '*'.
  ' TODO: should advent.read_string$() always trim its return value ?
  ia_str$(i)=str.trim$(advent.read_string$())
  advent.obj_rm%(i)=advent.read_int%()
 Next
End Sub

Sub advent.free()
 ' If there are no objects then we assume no adventure has been loaded
 ' and there is thus nothing to clear.
 If il<=0 Then Exit Sub
 advent.file$=""
 il=0 : cl=0 : nl=0 : rl=0 : mx=0 : ar=0
 tt=0 : ln=0 : lt=0 : ml=0 : tr=0
 Erase ca,nv_str$,ia_str$,advent.obj_rm%,rs$,rm,ms$
End Sub

' ---- src/advent.inc
' src/console.inc ++++
' Copyright (c) 2019-2026 Thomas Hugo Williams
' For MMBasic 6
Const con.SCREEN%=&h01
Const con.SERIAL%=&h02
Dim con.buf$     ' console write buffer
Dim con.space    ' was the last character written to con.buf$ a space?
Dim con.lines    ' number of lines that have been output since the last prompt
Dim con.count    ' number of newlines without an intervening character being printed
Dim con.x=1    ' current horizontal cursor position, indexed from 1
Dim con.spin     ' is the spinning cursor currently displayed?
Dim con.fd_in    ' file descriptor to read input from
Dim con.fd_out   ' file descriptor to echo input to
Dim con.more=1 ' show the [MORE] prompt if more than a page of output
' (approx con.HEIGHT lines) is written without a prompt
Dim con.history%(255) ' history buffer for user input.
Const con.CR$=Chr$(13)
Const con.LF$=Chr$(10)
Dim con.HEIGHT=50
Dim con.WIDTH=100
' @param  p$  prompt
Function con.in$(p$,echo)
 Local s$
 con.print(p$)
 con.flush()
 If con.fd_in Then
  Line Input #con.fd_in,s$
  If s$<>"" Then con.history_put(con.history%(),s$)
 Else
  s$=con.readln$("",con.WIDTH-con.x-Len(p$),con.history%())
 EndIf
 ' If we read from a file then echo what we read.
 If con.fd_in Then con.println(s$)
 ' If we read from the console then clear con.lines.
 If Not con.fd_in Then con.lines=0 : con.count=1
 con.x=1
 If con.fd_in Then
  If Eof(#con.fd_in) Then Close #con.fd_in : con.fd_in=0
 EndIf
 If echo Then
  If con.fd_out Then
   If s$<>"" Then Print #con.fd_out,s$
  EndIf
 EndIf
 con.in$=s$
End Function

' Outputs s$.
'
' s$ is appended to con.buf$ one character at a time. Only when we switch from
' non-spaces to spaces or vice versa do we flush the contents of con.buf$ to the
' console. As a result calling this function will probably not print the
' entirety of s$; ' the last 'word' or part thereof may be left in con.buf$.
Sub con.print(s$)
 Local c$,i
 For i=1 To Len(s$)
  c$=Mid$(s$,i,1)
  Select Case c$
   Case con.CR$ :
    ' Ignore carriage returns
   Case con.LF$ :
    con.endl()
    con.space=0
   Case " " :
    If Not con.space Then con.flush() : con.space=1
    Cat con.buf$," "
    con.count=0
   Case "`" :
    If con.space Then con.flush() : con.space=0
    Cat con.buf$,"'"
    con.count=0
   Case Else :
    If con.space Then con.flush() : con.space=0
    Cat con.buf$,c$
    con.count=0
  End Select
 Next
End Sub

' Writes con.buf$ to the console and clears it.
'
' If con.buf$ does not fit on the current line then first write CRLF and then if
' con.buf$ contains non-spaces write con.buf$ to the console.
Sub con.flush()
 If con.spin Then Print Chr$(8);" ";Chr$(8); : con.spin=0
 ' If the buffer is wider than the console then clip the buffer.
 ' An alternative would be to insert a newline, but in reality the only time
 ' this can happen is if we try to print a very long string with no spaces,
 ' e.g. a file-path.
 con.buf$=Left$(con.buf$,con.WIDTH)
 Do
  If con.x=1 And con.lines>con.HEIGHT-2 Then
   If con.more Then
    Print "[MORE] ";
    Do While Inkey$<>"" : Loop
    Do While Inkey$="" : Pause 1 : Loop
    Print
   EndIf
   con.lines=0
  EndIf
  If con.x+Len(con.buf$)>con.WIDTH+1 Then
   Print
   con.lines=con.lines+1
   con.x=1
   If con.space Then con.buf$="" : Exit Sub
  Else
   Print con.buf$;
   con.x=con.x+Len(con.buf$)
   con.buf$=""
   Exit Sub
  EndIf
 Loop
End Sub

' Flushes con.buf$ to the console and then writes CRLF.
Sub con.endl()
 con.flush()
 If con.count<0 Then
  Exit Sub
 ElseIf con.count>=10 Then
  ' If the story outputs 10 or more empty lines then we assume it was trying
  ' to clear the screen
  Local i
  For i=0 To con.HEIGHT-con.count-1 : Print : Next i
  con.count=-999 ' to avoid any unnecessary additional empty lines
  con.lines=0
  Exit Sub
 EndIf
 Print
 Inc con.count
 Inc con.lines
 con.x=1
End Sub

Sub con.println(s$,center)
 If Len(s$)>0 Then
  If center Then
   If con.x<>1 Then Error "Cannot center text unless on a new line."
   If Len(s$)<con.WIDTH Then con.print(Space$((con.WIDTH-Len(s$))\2)+s$)
  Else
   con.print(s$)
  EndIf
 EndIf
 con.endl()
End Sub

' Echos the contents of a (hopefully) text file to the console.
Sub con.print_file(f$,center)
 Local s$,w
 If center Then
  Open f$ For Input As #1
  Do
   Line Input #1,s$
   w=Max(w,Len(s$))
  Loop While Not Eof(#1)
  Close #1
 EndIf
 Open f$ For Input As #1
 Do
  Line Input #1,s$
  If center Then
   con.println(s$+Space$(w-Len(s$)),center)
  Else
   con.println(s$)
  EndIf
 Loop While Not Eof(#1)
 Close #1
End Sub

Sub con.open_in(fd,f$)
 con.close_in()
 Open f$ For Input As #fd
 con.fd_in=fd
End Sub

Sub con.close_in()
 If con.fd_in Then Close #con.fd_in
 con.fd_in=0
End Sub

Sub con.open_out(fd,f$)
 con.close_out()
 Open f$ For Output As #fd
 con.fd_out=fd
End Sub

Sub con.close_out()
 If con.fd_out Then Close #con.fd_out
 con.fd_out=0
End Sub

Sub con.close_all()
 con.close_in()
 con.close_out()
End Sub

Sub con.foreground(c$)
 Local type%=con.get_type%()
 If type% And con.SCREEN% Then
  Local scol%
  Select Case LCase$(c$)
   Case "green" : scol%=RGB(Green)
   Case Else : scol%=RGB(White)
  End Select
  Colour scol%
 EndIf
 If type% And con.SERIAL% Then
  con.set_type(con.SERIAL%)
  Print vt100.colour$(c$);
  con.set_type(type%)
 EndIf
End Sub

Sub con.bell()
 Local type%=con.get_type%()
 If type% And con.SCREEN% Then Play Tone 329.63,329.63,100 ' Note E4
 If type% And con.SERIAL% Then
  con.set_type(con.SERIAL%)
  Print Chr$(7);
  con.set_type(type%)
 EndIf
End Sub

' Gets the console type.
' Note that in many cases you don't want to test the return value using equals
' '=' but instead using AND.
' e.g. to test whether the type supports:
'  - serial console do: IF con.get_type%() AND con.SERIAL% THEN
'  - screen console do: IF con.get_type%() AND con.SCREEN% THEN
Function con.get_type%()
 Select Case LCase$(Mm.Info(Option Console))
  Case "both" : con.get_type%=con.SCREEN% Or con.SERIAL%
  Case "screen" : con.get_type%=con.SCREEN%
  Case "serial" : con.get_type%=con.SERIAL%
  Case Else : Error "Unknown console type"
 End Select
End Function

Sub con.set_type(type%)
 Select Case type%
  Case con.SCREEN% : Option Console Screen
  Case con.SERIAL%
   ' Note MMB4W cannot call OPTION CONSOLE SERIAL if it is on the same line
   ' as a CASE clause. This is because in MMB4W this OPTION checks
   ' 'CurrentLinePtr' to make sure it is only being used from within a
   ' program. However due to a long-standing and gnarly bug in the MMBasic
   ' core 'CurrentLinePtr' is not correctly set when processing a command on
   ' the same line as a CASE clause.
   Option Console Serial
  Case &h03 : Option Console Both
  Case Else
   Error "Unknown console type"
 End Select
End Sub

' Gets a string element from the command history.
'
' @param  h%()  buffer containing the command history.
' @param  idx%  index of the element to retrieve, the first element is always
'               idx% = 0 irrespective of OPTION BASE.
' @return       string element, or empty string if idx% >= number of elements.
Function con.history_get$(h%(),idx%)
 If idx%<0 Then Error "index out of bounds: "+Str$(idx%)
 Local h_addr%=Peek(VarAddr h%())
 Local h_size%=(Bound(h%(),1)-Bound(h%(),0)+1)*8
 Local i%,p%=h_addr%
 For i%=0 To idx%
  If Peek(Byte p%)=0 Then Exit Function ' Return empty string.
  If i%<idx% Then Inc p%,Peek(Byte p%)+1
 Next
 If p%+Peek(Byte p%)<h_addr%+h_size% Then
  Memory Copy p%,Peek(VarAddr con.history_get$),Peek(Byte p%)+1
 EndIf
End Function

Function con.history_find%(h%(),needle$)
 If needle$="" Then Error "invalid argument: needle$"
 ' TODO: could be faster by not calling con.history_get()
 Local i%=-1,s$
 Do
  Inc i%
  s$=con.history_get$(h%(),i%)
 Loop Until s$="" Or s$=needle$
 con.history_find%=Choice(s$="",-1,i%)
End Function

Sub con.history_put(h%(),s$)
 If s$="" Then Error "invalid empty string"
 Local h_addr%=Peek(VarAddr h%())
 Local h_size%=(Bound(h%(),1)-Bound(h%(),0)+1)*8
 If Peek(Byte h_addr%)>0 Then
  ' Can't use MEMORY COPY because the CMM2 does not handle case where src and dst overlap.
  ' Memory Copy h_addr%, h_addr% + 1 + Len(s$), h_size% - 1 - Len(s$)
  Local dst%=h_addr%+h_size%-1
  Local src%=dst%-Len(s$)-1
  Do While src%>=h_addr%
   Poke Byte dst%,Peek(Byte src%)
   Inc dst%,-1
   Inc src%,-1
  Loop
 EndIf
 Memory Copy Peek(VarAddr s$),h_addr%,Len(s$)+1
End Sub

Function con.readln$(initial$,max_len%,history%())
 Local ch$,hidx%,p%,old$,overwrite%,s$
 Local max_len_%=Choice(max_len%<1 Or max_len%>255,255,max_len%)
 con.readln$=initial$
 p%=Len(initial$)+1
 Print initial$;
 hidx%=Choice(initial$="",-1,con.history_find%(history%(),initial$))
 Local show%=1
 Local t%=Timer+500
 Do While Inkey$<>"" : Loop ' Discard anything else in the keyboard buffer.
 Do While Not sys.break_flag%
  If Timer>t% Then show%=Not show% : t%=Timer+500
  con.show_cursor(show%)
  ch$=Inkey$
  If ch$="" Then Pause 1 : Continue Do
  con.show_cursor(0)
  Select Case Asc(ch$)
   Case 8 ' Backspace
    If p%=1 Then
     con.bell()
    Else
     ' Delete the character immediately to the left.
     s$=Mid$(con.readln$,p%)
     con.readln$=Left$(con.readln$,p%-2)+s$
     Print Chr$(&h08) s$ " " String$(Len(s$)+1,&h08);
     Inc p%,-1
    EndIf
   Case 10,13 ' Enter
    Print
    If con.readln$<>"" Then con.history_put(history%(),con.readln$)
    Exit Do
   Case 127 ' Delete
    If p%=Len(con.readln$)+1 Then
     con.bell()
    Else
     ' Delete the current character.
     s$=Mid$(con.readln$,p%+1)
     con.readln$=Left$(con.readln$,p%-1)+s$
     Print s$ " " String$(Len(s$)+1,&h08);
    EndIf
   Case 128,129 ' Up, Down
    If hidx%=-1 Then old$=con.readln$
    Inc hidx%,Choice(Asc(ch$)=128,1,-1)
    If hidx%<=-1 Then
     hidx%=-1
     s$=old$
    Else
     s$=con.history_get$(history%(),hidx%)
     If s$="" Then s$=con.readln$ : Inc hidx%,-1
    EndIf
    Print String$(p%-1,&h08) String$(p%-1," ") String$(p%-1,&h08) s$;
    con.readln$=s$
    p%=Len(s$)+1
   Case 130 ' Left
    If p%>1 Then
     Inc p%,-1
     Print Chr$(&h08);
    EndIf
   Case 131 ' Right
    If p%<=Len(con.readln$) Then
     Print Mid$(con.readln$,p%,1);
     Inc p%
    EndIf
   Case 132 ' Insert
    overwrite%=Not overwrite%
   Case 134 ' Home
    Print String$(p%-1,&h08);
    p%=1
   Case 135 ' End
    Do While p%<=Len(con.readln$)
     Print Mid$(con.readln$,p%,1);
     Inc p%
    Loop
   Case <32,>126
    ' Print "<" Str$(Asc(ch$)) ">";
    ' con.bell()
   Case Else
    If p%>Len(con.readln$) Then
     ' Append to end of line.
     If Len(con.readln$)=max_len_% Then
      con.bell()
     Else
      Cat con.readln$,ch$
      Print ch$;
      Inc p%
     EndIf
    ElseIf overwrite% Then
     ' Overwrite.
     con.readln$=Left$(con.readln$,p%-1)+ch$+Mid$(con.readln$,p%+1)
     Print ch$;
     Inc p%
    Else
     ' Insert.
     If Len(con.readln$)=max_len_% Then
      con.bell()
     Else
      s$=Mid$(con.readln$,p%)
      con.readln$=Left$(con.readln$,p%-1)+ch$+s$
      Print ch$ s$ String$(Len(s$),&h08);
      Inc p%
     EndIf
    EndIf
  End Select
 Loop
 If sys.break_flag% Then con.readln$=""
End Function

' Hide/show cursor on the VGA/LCD screen.
Sub con.show_cursor(show%)
 If con.get_type%() And con.SCREEN% Then
  Local x%=Mm.Info(HPos),y%=Mm.Info(VPos)+Mm.Info(FontHeight)-1
  Line x%,y%,x%+Mm.Info(FontWidth),y%,1,Choice(show%,RGB(White),RGB(Black))
 EndIf
End Sub

' ---- src/console.inc
' src/metadata.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
' This file contains functions for reading SAAINT metadata '.ext'
' files.
Const metadata.FD_IN%=1
Const metadata.FD_OUT%=2
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
 Local extfile$=file.trim_extension$(f$)+".ext"
 Local name$
 If file.exists%(extfile$) Then
  Open extfile$ For Input As metadata.FD_IN%
  Line Input #metadata.FD_IN%,name$
  Close metadata.FD_IN%
 Else
  name$=file.trim_extension$(file.get_name$(f$))
  name$=UCase$(Left$(name$,1))+Mid$(name$,2)
 EndIf
 metadata.read_name$=str.trim$(name$)
End Function

' Reads description from ".ext" file.
'
' @param       f$      the full file path.
' @param[out]  out%()  the description is appended to this LongString.
Sub metadata.read_description(f$,out%())
 If Not file.exists%(f$) Then
  LongString Append out%(),"No description provided."
  Exit Sub
 EndIf
 Local max_len%=(Bound(out%(),1)-Bound(out%(),0))*8
 Local cont%,s$
 Open f$ For Input As metadata.FD_IN%
 Do While Not Eof(metadata.FD_IN%)
  Line Input #metadata.FD_IN%,s$
  If metadata.find_section_header$(s$)<>"" Then Exit Do
  ' Handle line continuation.
  cont%=Right$(s$,1)="\"
  If cont% Then s$=Left$(s$,Len(s$)-1)+" "
  LongString Append out%(),Left$(s$,Min(255,max_len%-LLen(out%())))
  If Not cont% Then LongString Append out%(),Left$(sys.CRLF$,Min(255,max_len%-LLen(out%())))
 Loop
 Close metadata.FD_IN%
End Sub

Function metadata.find_section_header$(s$)
 If Not InStr(s$,"##") Then Exit Function
 Local us$=UCase$(s$)
 If InStr(us$,"##TITLE##") Then
  us$="##TITLE##"
 ElseIf InStr(us$,"##CREDITS##") Then
  us$="##CREDITS##"
 ElseIf InStr(us$,"##INSTRUCTIONS##") Then
  us$="##INSTRUCTIONS##"
 Else
  us$=""
 EndIf
 metadata.find_section_header$=us$
End Function

' Reads the '.ext' file.
' Assumes that the file has LF or CRLF line-endings, and not Mac style CR line-endings.
' Reports ERROR if encounters line > 255 characters.
Sub metadata.read_ext(f$)
 Select Case LCase$(file.get_extension$(f$))
  Case ".dat" : Local f_in$=file.trim_extension$(f$)+".ext"
  Case ".ext" : Local f_in$=f$
  Case Else : Local f_in$=f$+".ext"
 End Select
 metadata.name$=file.trim_extension$(f$)+".dat"
 metadata.title_file$=""
 metadata.credits_file$=""
 metadata.instructions_file$=""
 If Not file.exists%(f_in$) Then Exit Sub
 Open f_in$ For Input As metadata.FD_IN%
 ' Adventure name should be on the first (non-blank) line.
 Local s$
 Do While Not Eof(metadata.FD_IN%)
  Line Input #metadata.FD_IN%,s$
  s$=str.trim$(s$)
  If s$<>"" Then
   metadata.name$=s$
   Exit Do
  EndIf
 Loop
 ' Extract temporary TITLE, CREDITS and INSTRUCTIONS files.
 Local f_out$=""
 Local file_open%=0
 Local first_line%=0
 Local num_blank_lines%=0
 Local header$
 Do While Not Eof(metadata.FD_IN%)
  Line Input #metadata.FD_IN%,s$
  ' Check for section headings and if found open the appropriate output file.
  header$=metadata.find_section_header$(s$)
  Select Case header$
   Case "##TITLE##"
    metadata.title_file$=TMP_DIR$+"/title.tmp"
    f_out$=metadata.title_file$
    first_line%=-1
   Case "##CREDITS##"
    metadata.credits_file$=TMP_DIR$+"/credits.tmp"
    f_out$=metadata.credits_file$
    first_line%=-1
   Case "##INSTRUCTIONS##"
    metadata.instructions_file$=TMP_DIR$+"/instructions.tmp"
    f_out$=metadata.instructions_file$
    first_line%=-1
  End Select
  If first_line%=-1 Then
   If file_open% Then Close metadata.FD_OUT%
   Open f_out$ For Output As metadata.FD_OUT%
   file_open%=1
   first_line%=1
   num_blank_lines%=0
   Continue Do
  EndIf
  If Not file_open% Then Continue Do
  ' We don't want the file to contain any leading or trailing blank lines.
  If str.trim$(s$)="" Then
   Inc num_blank_lines%
  Else
   If Not first_line% Then
    Do While num_blank_lines%>0
     Print #metadata.FD_OUT%
     Inc num_blank_lines%,-1
    Loop
   EndIf
   Print #metadata.FD_OUT%,s$
   first_line%=0
   num_blank_lines%=0
  EndIf
 Loop
 If file_open% Then Close metadata.FD_OUT%
 Close metadata.FD_IN%
End Sub

' ---- src/metadata.inc
' src/catalogue.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
' This file contains functions for finding and listing '.dat' files.
Const catalogue.DIR$=Mm.Info$(Path)+"../adventures"
Const catalogue.FD_IN%=1
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
 Local f$=str.unquote$(str.trim$(name$))
 If LCase$(file.get_extension$(f$))<>".dat" Then Cat f$,".dat"
 ' Is f$ just a simple absolute or relative path to the file ?
 If file.exists%(f$) Then
  ' Do nothing.
  ' Is f$ a path relative to catalogue.DIR$ ?
 ElseIf file.exists%(catalogue.DIR$+"/"+f$) Then
  f$=catalogue.DIR$+"/"+f$
  ' Is f$ a path relative to a sub-directory of catalogue.DIR$ ?
 Else
  Local num_dirs%=file.count_files%(catalogue.DIR$,"*","Dir")
  Local all_dirs$(num_dirs%-1) Length 128
  Const num_files%=file.get_files%(catalogue.DIR$,"*","Dir",all_dirs$())
  Local i%
  For i%=0 To num_dirs%-1
   If file.exists%(catalogue.DIR$+"/"+all_dirs$(i%)+"/"+f$) Then
    f$=catalogue.DIR$+"/"+all_dirs$(i%)+"/"+f$
    Exit For
   EndIf
  Next
 EndIf
 If Not file.exists%(f$) Then f$=""
 catalogue.find$=f$
End Function

' Fills a map of (adventure name -> filename) for all the adventures in the
' "adventures/" directory.
Sub catalogue.get_all(m$())
 Select Case Mm.Device$
  Case "MMB4L","MMBasic for Windows"
   Local dirs$(list.new%(10))
  Case Else :
   Local dirs$(list.new%(10)) Length 64
 End Select
 list.init(dirs$())
 list.add(dirs$(),".")
 Local f$=Dir$(catalogue.DIR$+"/*",Dir)
 Do While f$<>"" And Not list.is_full%(dirs$())
  list.add(dirs$(),f$)
  f$=Dir$()
 Loop
 Local i%,lb%=0,ub%=list.size%(dirs$())-1
 Local d$
 For i%=lb% To ub%
  d$=catalogue.DIR$+"/"+dirs$(i%)+"/"
  f$=Dir$(d$+"*.dat")
  Do While f$<>"" And Not map.is_full%(m$())
   map.put(m$(),metadata.read_name$(d$+f$),f$)
   f$=Dir$()
  Loop
 Next
End Sub

' ---- src/catalogue.inc
' src/menus.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
Const RESOURCES_DIR$=Mm.Info(Path)+"../resources"
' This file contains functions to show the main, adventure selection
' and adventure specific menus as well as the credits and
' instructions.
Function menus.main$(advent$)
 Local f$=RESOURCES_DIR$+"/title.txt"
 Cls
 twm.enable_cursor(0)
 con.lines=0
 con.foreground("white")
 con.println()
 con.print_file(f$,1)
 con.foreground("green")
 con.println()
 Local play_item$=Choice(advent$="","","P  Play '"+metadata.read_name$(advent$)+"'")
 Local select_item$="S  Select a "+Choice(advent$="","new","different")+" adventure"
 Local width%=Max(Len(play_item$),Len(select_item$))
 If play_item$<>"" Then con.println(str.rpad$(play_item$,width%),1)
 con.println(str.rpad$(select_item$,width%),1)
 con.println(str.rpad$("I  Instructions",width%),1)
 con.println(str.rpad$("C  Credits & License",width%),1)
 con.println(str.rpad$("Q  Quit",width%),1)
 con.println()
 con.println("Version "+sys.format_version$(SAAINT_VERSION),1)
 Do While Inkey$<>"" : Loop
 Local k$
 Do
  k$=LCase$(Inkey$)
  If Asc(k$)=27 Then k$="escape"
  Select Case k$
   Case "p" : menus.main$="#play"
   Case "c" : menus.main$="#credits"
   Case "i" : menus.main$="#instructions"
   Case "q","escape" : menus.main$="#quit"
   Case "s" : menus.main$="#select"
   Case Else : k$="" : Pause 1
  End Select
 Loop Until k$<>""
 con.lines=0
End Function

Function menus.adventure$()
 Cls
 twm.enable_cursor(0)
 con.lines=0
 con.foreground("white")
 If metadata.title_file$<>"" Then
  con.print_file(metadata.title_file$,1)
 Else
  con.println()
  con.println(metadata.name$,1)
 EndIf
 con.foreground("green")
 con.println()
 con.println("S  Start a new game      ",1)
 con.println("R  Restore a saved game  ",1)
 con.println("I  Instructions          ",1)
 If metadata.credits_file$<>"" Then con.println("C  Credits & License      ",1)
 con.println("B  Back to adventure list",1)
 con.println("Q  Quit                  ",1)
 Do While Inkey$<>"" : Loop
 Local k$
 Do
  k$=LCase$(Inkey$)
  If Asc(k$)=27 Then k$="escape"
  Select Case k$
   Case "b","escape" : menus.adventure$="#back"
   Case "c"
    If metadata.credits_file$<>"" Then menus.adventure$="#credits" Else k$=""
   Case "i" : menus.adventure$="#instructions"
   Case "q" : menus.adventure$="#quit"
   Case "r" : menus.adventure$="#restore"
   Case "s" : menus.adventure$="#start"
   Case Else : k$="" : Pause 1
  End Select
 Loop Until k$<>""
 con.lines=0
End Function

Sub menus.credits(top%)
 Local f$=Choice(top%,"",metadata.credits_file$)
 f$=Choice(f$<>"",f$,RESOURCES_DIR$+"/credits.txt")
 Cls
 twm.enable_cursor(0)
 con.lines=0
 con.foreground("white")
 con.println()
 con.println("CREDITS & LICENSE",1)
 con.println("=================",1)
 con.println()
 con.foreground("green")
 con.print_file(f$,1)
 con.println()
 con.foreground("white")
 con.println("Press any key to continue",1)
 con.foreground("green")
 Do While Inkey$<>"" : Loop
 Do While Inkey$="" : Pause 1 : Loop
End Sub

Sub menus.instructions(top%)
 Local f$=Choice(top%,"",metadata.instructions_file$)
 f$=Choice(f$<>"",f$,RESOURCES_DIR$+"/instructions.txt")
 Cls
 twm.enable_cursor(0)
 con.lines=0
 con.foreground("white")
 con.println()
 con.println("HOW TO PLAY",1)
 con.println("===========",1)
 con.println()
 con.foreground("green")
 con.print_file(f$,1)
 con.println()
 con.foreground("white")
 con.println("Press any key to continue",1)
 con.foreground("green")
 Do While Inkey$<>"" : Loop
 Do While Inkey$="" : Pause 1 : Loop
End Sub

Function menus.choose_advent$()
 Const MENU_WIDTH%=Int(con.WIDTH/2)-4
 Const MENU_HEIGHT%=con.HEIGHT-6
 Const ORIGINAL_TYPE%=con.get_type%()
 Cls
 con.set_type(con.SERIAL%) ' Why do we only show menu on serial console?
 twm.enable_cursor(0)
 Local twm_sz%=7+2*(con.WIDTH*con.HEIGHT)
 Inc twm_sz%,7+2*(MENU_WIDTH*MENU_HEIGHT)
 Inc twm_sz%,7+2*((MENU_WIDTH+1)*MENU_HEIGHT)
 twm.init(3,twm_sz%)
 twm.console_only%=1
 Local win0%=twm.new_win%(0,0,con.WIDTH,con.HEIGHT)
 Local left%=twm.new_win%(2,4,MENU_WIDTH%,MENU_HEIGHT%)
 Local right%=twm.new_win%(con.WIDTH/2+1,4,MENU_WIDTH%+1,MENU_HEIGHT%)
 twm.switch(win0%)
 twm.box(0,2,con.WIDTH,con.HEIGHT-2)
 twm.box(0,2,con.WIDTH/2,con.HEIGHT-2)
 twm.bold(1)
 twm.print_at(0,0,str.centre$("Select adventure using [Up], [Down], [Page Up], [Page Down] and [Enter]",con.WIDTH))
 twm.switch(left%)
 twm.print_at(0,0,"Reading adventures...")
 Select Case Mm.Device$
  Case "MMB4L","MMBasic for Windows"
   Local m$(map.new%(50))
  Case Else
   Local m$(map.new%(50)) Length 64
 End Select
 map.init(m$())
 catalogue.get_all(m$())
 Local size%=map.size%(m$())
 Local first%=0
 Local last%=first%+MENU_HEIGHT%-1
 Local sel%=0
 Local new_first%=first%
 Local new_sel%=sel%
 Local requires_update%=1
 Local i%
 menus.paint_menu(left%,m$(),first%,sel%)
 Local k$=Input$(255,#0)
 Do
  k$=Inkey$
  Select Case Asc(k$)
   Case 10,13,27,32,113 ' Enter, Escape, Space or Q
    Exit Do
   Case 128 ' Up
    new_sel%=sel%-1
   Case 129 ' Down
    new_sel%=sel%+1
   Case 136 ' Page Up
    new_sel%=Choice(sel%=first%,sel%-MENU_HEIGHT%,first%)
   Case 137 ' Page Down
    new_sel%=Choice(sel%=last%,sel%+MENU_HEIGHT%,last%)
   Case Asc("A") To Asc("Z"),Asc("a") To Asc("z"),Asc("0") To Asc("9")
    ' Select adventure to first entry whose name begins with letter/digit.
    ' If current selection and next entry begin with letter/digit then select
    ' next entry.
    ' Relies on all adventure names beginning with digit or upper-case character.
    k$=UCase$(k$)
    If Left$(m$(sel%),1)=k$ Then new_sel%=sel%+1
    If Left$(m$(new_sel%),1)<>k$ Then
     For i%=0 To size%-1
      If Left$(m$(i%),1)=k$ Then
       new_sel%=i%
       Exit For
      EndIf
     Next
    EndIf
   Case 0
    If requires_update% Then
     menus.paint_description(right%,map.get$(m$(),m$(sel%)))
     requires_update%=0
    EndIf
    Pause 1
  End Select
  ' Clear the keyboard buffer without blocking when it is empty.
  If k$<>"" Then k$=Input$(255,#0)
  ' Keep selected item within bounds of list.
  new_sel%=Min(size%-1,Max(0,new_sel%))
  ' Short-circuit if new selected item = old selected item.
  If new_sel%=sel% Then Continue Do
  ' Update new_first% to keep new_sel% within display bounds.
  If new_sel%<first% Then
   new_first%=new_sel%
  ElseIf new_sel%>last% Then
   new_first%=new_sel%-MENU_HEIGHT%+1
  EndIf
  twm.switch(left%)
  twm.inverse(0)
  twm.print_at(0,sel%-first%,menus.fmt_item$(m$(sel%),MENU_WIDTH%))
  If new_first%=first%+1 Then
   twm.scroll_up(1)
  ElseIf new_first%=first%-1 Then
   twm.scroll_down(1)
  ElseIf new_first%<>first% Then
   menus.paint_menu(left%,m$(),new_first%,new_sel%)
  EndIf
  twm.inverse(1)
  twm.print_at(0,new_sel%-new_first%,menus.fmt_item$(m$(new_sel%),MENU_WIDTH%))
  first%=new_first%
  last%=first%+MENU_HEIGHT%-1
  sel%=new_sel%
  requires_update%=1
  Pause 100
 Loop
 ' Enter or Space to select.
 Select Case Asc(k$)
  Case 10,13,32 : menus.choose_advent$=map.get$(m$(),m$(sel%))
 End Select
 con.set_type(ORIGINAL_TYPE%)
 twm.free()
End Function

Sub menus.paint_menu(win%,m$(),first%,sel%)
 twm.switch(win%)
 twm.inverse(0)
 twm.cls()
 Local i%
 Local size%=map.size%(m$())
 Local last%=first%+twm.h%-1
 If last%>=size% Then last%=size%-1
 For i%=first% To last%
  twm.inverse(i%=sel%)
  twm.print_at(0,i%-first%,menus.fmt_item$(m$(i%),twm.w%))
 Next
End Sub

Function menus.fmt_item$(s$,w%)
 menus.fmt_item$=str.centre$(Mid$(s$,1,w%),w%)
End Function

Sub menus.paint_description(win%,advent$)
 Local desc%(200)
 metadata.read_description(file.trim_extension$(catalogue.find$(advent$))+".ext",desc%())
 twm.switch(win%)
 twm.cls()
 twm.print_at(0,0)
 Local ch%,i%,s$
 For i%=1 To LLen(desc%())
  ch%=Peek(Var desc%(),i%+7)
  Select Case ch%
   Case 10 ' LF
    If twm.x%+Len(s$)>=twm.w% Then twm.x%=0 : Inc twm.y%
    twm.print(s$)
    s$=""
    twm.x%=0
    Inc twm.y%
   Case 13 ' CR
    ' Do nothing.
   Case 32 ' Space
    If twm.x%+Len(s$)>twm.w% Then
     twm.x%=0
     Inc twm.y%
    EndIf
    If s$=" " Then
     If twm.x%>0 Then twm.print(" ")
    Else
     twm.print(s$)
    EndIf
    s$=" "
   Case Else
    If s$=" " Then
     If twm.x%>0 Then twm.print(" ")
     s$=""
    EndIf
    Cat s$,Chr$(ch%)
  End Select
 Next
 twm.print(s$)
End Sub

' ---- src/menus.inc
' src/script.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' Developed with the assistance of Bill McKinley
' For MMBasic 6
' Implementation of script/walkthrough record and replay.
Const script.DIR$=file.get_canonical$(Mm.Info$(Path)+"../scripts")
Const script.FD_IN%=2
Const script.FD_OUT%=3

Sub script.record_on()
 Local f$,s$
 If con.fd_out<>0 Then con.println("Already recording script.") : Exit Sub
 If con.fd_in<>0 Then con.println("Cannot record whilst replaying script.") : Exit Sub
 con.println()
 con.println("Select script to record:")
 con.println()
 Local script%=script.select_script%()
 If script%<>0 Then f$=script.script_file$(script%)
 If script%<>0 And file.exists%(f$) Then
  s$=prompt$("Overwrite script "+Str$(script%)+" [y|N]? ")
  If LCase$(s$)<>"y" Then script%=0
 EndIf
 If script%<>0 Then
  s$=prompt$("Script name ? ")
  If s$="" Then script%=0
 EndIf
 If script%=0 Then con.println("Cancelled.") : Exit Sub
 con.println("Recording to '"+f$+"' ...")
 If file.mkdir%(file.get_parent$(f$))<>sys.SUCCESS Then Error sys.err$
 Const fd_out%=script.FD_OUT%
 con.open_out(fd_out%,f$)
 Print #fd_out%,"# " Date$ " " Time$
 Print #fd_out%,"# " s$
End Sub

' Prompts the user to select a script slot.
Function script.select_script%()
 Local i,f$,s$
 Const fd%=script.FD_IN%
 For i=1 To 10
  f$=script.script_file$(i)
  con.print("  ["+Format$(i,"%2g")+"] ")
  If file.exists%(f$) Then
   Open f$ For Input As #fd%
   Line Input #fd%,s$ ' date/time
   con.print(Mid$(s$,3)+" - ")
   Line Input #fd%,s$ ' script name
   con.println(Mid$(s$,3))
   Close #fd%
  Else
   con.println("Empty")
  EndIf
 Next i
 con.println()
 s$=prompt$("Script number ? ")
 Local script%=Val(s$)
 If script%<1 Or script%>10 Then script%=0
 script.select_script%=script%
End Function

' Gets the path to the file corresponding to script slot 'i'.
Function script.script_file$(i)
 If i<1 Or i>10 Then Error "Invalid script number"
 Local name$=file.trim_extension$(file.get_name$(advent.file$))+"_"+Str$(i)+".scr"
 Local parent_name$=file.get_name$(file.get_parent$(advent.file$))
 If Right$(parent_name$,1)=":" Then
  parent_name$=Left$(parent_name$,Len(parent_name$)-1)+"-drive"
 EndIf
 script.script_file$=script.DIR$+"/"+parent_name$+"/"+name$
End Function

Sub script.record_off()
 If con.fd_out=0 Then con.println("A script is not being recorded!") : Exit Sub
 con.close_out()
 con.println("Recording stopped.")
End Sub

Sub script.replay_on()
 If con.fd_out<>0 Then con.println("Cannot replay whilst recording script.") : Exit Sub
 If con.fd_in<>0 Then con.println("Already replaying script.") : Exit Sub
 con.println()
 con.println("Select script to replay:")
 con.println()
 Local script%=script.select_script%()
 If script%<>0 Then
  Local f$=script.script_file$(script%)
  If Not file.exists%(f$) Then script%=0
 EndIf
 If script%=0 Then con.println("Cancelled.") : Exit Sub
 con.println("Replaying from '"+f$+"' ...")
 con.open_in(script.FD_IN%,f$)
End Sub

Sub script.replay_off()
 If con.fd_in=0 Then con.println("A script is not being replayed!") : Exit Sub
 con.close_in()
 con.println("Replaying stopped.")
End Sub

' Replays the walkthrough file (.wlk) for the current adventure.
Sub script.walkthrough()
 Local f_in$=file.trim_extension$(advent.file$)+".wlk"
 If Not file.exists%(f_in$) Then con.println("No walkthrough available.") : Exit Sub
 If con.fd_out<>0 Then con.println("Cannot play walkthrough whilst recording script.") : Exit Sub
 If con.fd_in<>0 Then con.println("Cannot play walkthrough whilst replaying script.") : Exit Sub
 ' Handle unencrypted walkthrough.
 If script.is_unencrypted%(f_in$) Then
  con.open_in(script.FD_IN%,f_in$)
  Exit Sub
 EndIf
 ' Prompt for and hash password.
 Local password$=prompt$("Password? ")
 If password$="" Then con.println("Cancelled.") : Exit Sub
 Local k%(array.new%(2))
 Local ok%=crypt.md5%(Peek(VarAddr password$)+1,Len(password$),k%())
 If Not ok% Then con.println("Error: "+sys.err$) : Exit Sub
 ' Decrypt walkthough to "walkthrough.tmp"
 Local f_out$=TMP_DIR$+"/walkthrough.tmp"
 Const fd_in%=script.FD_IN%
 Const fd_out%=script.FD_OUT%
 Open f_in$ For Input As fd_in%
 Open f_out$ For Output As fd_out%
 ok%=crypt.xxtea_file%("decrypt",fd_in%,fd_out%,k%(),k%())
 Close fd_out%
 Close fd_in%
 ' If successful then start replaying the walkthrough script, otherwise report the problem.
 If Not ok% Then
  con.println("Error: "+sys.err$)
 ElseIf script.is_unencrypted%(f_out$) Then
  con.open_in(script.FD_IN%,f_out$)
 Else
  con.println("Password incorrect!")
 EndIf
End Sub

' Is file 'f$' unencrypted ?
'
' @param  f$  the file in question.
' @return     1 if there are no non-printable, non-whitespace control codes in the first 255 bytes
'             of the file, otherwise 0.
Function script.is_unencrypted%(f$)
 Const fd_in%=script.FD_IN%
 Open f$ For Input As fd_in%
 Local s$=LCase$(Input$(255,#fd_in%))
 Close fd_in%
 script.is_unencrypted%=str.is_plain_ascii%(s$)
End Function

' ---- src/script.inc
' src/state.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
' Current game state.
Const state.SAVE_DIR$=file.get_canonical$(Mm.Info$(Path)+"../saves")
Const state.FD%=1
Const state.DARK_BIT%=15 ' The status flag that is set when it is dark.
Const state.LAMP_OUT_BIT%=16 ' The status flag that is set when the lamp goes out.
Dim lx               ' lamp duration
Dim r                ' current room
Dim sf               ' status flags
Dim counter          ' main counter
Dim alt_counter(7)   ' 8 alternate counters
Dim alt_room(5)      ' 6 alternate room registers
Dim state.obj_rm%(2) ' current object locations
' - initialised with a dummy size, reset by state.reset()
Sub state.reset()
 r=ar  ' current room = starting room
 lx=lt ' lamp starts full
 sf=0  ' status flags are clear
 counter=0
 Local i%
 For i%=0 To 7 : alt_counter(i%)=0 : Next
 For i%=0 To 5 : alt_room(i%)=0 : Next
 Erase state.obj_rm%
 Dim state.obj_rm%(il)
 For i%=0 To il : state.obj_rm%(i%)=advent.obj_rm%(i%) : Next
End Sub

' Saves the current game state to a file.
'
' @return 1 on success, otherwise 0.
Function state.save%()
 Local f$,i,s$
 con.println()
 con.println("Select saved game:")
 con.println()
 Local game%=state.select_game%()
 If game%<>0 Then
  f$=state.save_file$(game%)
  If file.exists%(f$) Then
   s$=prompt$("Overwrite game "+Str$(game%)+" [y|N]? ")
   If LCase$(s$)<>"y" Then game%=0
  EndIf
 EndIf
 If game%<>0 Then
  s$=prompt$("Saved game name ? ")
  If s$="" Then game%=0
 EndIf
 If game%=0 Then Exit Function
 con.println("Saving '"+f$+"' ...")
 If file.mkdir%(file.get_parent$(f$))<>sys.SUCCESS Then Error sys.err$
 Const fd%=state.FD%
 Open f$ For Output As #fd%
 ' Write file header
 Print #fd%,"SAAINT save file"
 Print #fd%,"2" ' file format version
 Print #fd%,Date$+" "+Time$
 Print #fd%,s$
 ' Write state
 Print #fd%,"&b" Bin$(sf,32)                            ' status flags
 Print #fd%,Str$(bits.get%(sf,state.DARK_BIT%))         ' dark flag, stored for historical
 ' purposes as now synonymous with
 ' status flag 15
 Print #fd%,Str$(r)                                      ' current room
 Print #fd%,Str$(lx)                                     ' lamp duration
 For i=0 To il : Print #fd%,Str$(state.obj_rm%(i)) : Next ' object locations
 Print #fd%,Str$(counter)                                ' counter
 For i=0 To 7 : Print #fd%,Str$(alt_counter(i)) : Next ' alternate counters
 For i=0 To 5 : Print #fd%,Str$(alt_room(i)) : Next    ' alternate rooms
 Close #fd%
 state.save%=1
End Function

' Gets the path to the file corresponding to saved game slot 'i'.
Function state.save_file$(i)
 If i<1 Or i>10 Then Error "Invalid saved game number"
 Local name$=file.trim_extension$(file.get_name$(advent.file$))+"_"+Str$(i)+".sav"
 Local parent_name$=file.get_name$(file.get_parent$(advent.file$))
 If Right$(parent_name$,1)=":" Then
  parent_name$=Left$(parent_name$,Len(parent_name$)-1)+"-drive"
 EndIf
 state.save_file$=state.SAVE_DIR$+"/"+parent_name$+"/"+name$
End Function

' Restores game state from a file.
'
' @return 1 on success, otherwise 0.
Function state.restore%()
 Local err$,f$,i,s$,values(19+il)
 con.println()
 con.println("Select saved game to restore:")
 con.println()
 Local game%=state.select_game%()
 If game%<>0 Then
  f$=state.save_file$(game%)
  If Not file.exists%(f$) Then game%=0
 EndIf
 If game%=0 Then con.println("Cancelled.") : Exit Function
 Const fd%=state.FD%
 Open f$ For Input As #fd%
 ' Read file header
 Line Input #fd%,s$
 Line Input #fd%,s$
 Line Input #fd%,s$
 Line Input #fd%,s$
 con.println("Restoring '"+s$+"' ...")
 For i=0 To 19+il
  Line Input #fd%,s$
  If s$="" Then err$="missing data" : Exit For
  values(i)=Val(s$)
 Next i
 If Not Eof(#fd%) And err$="" Then err$="unexpected data"
 If err$="" Then
  ' Update game state with values read from file.
  sf=values(0)
  ' Historically we saved a "dark flag" which is synonymous with status flag 15.
  If values(1) Then bits.set(sf,state.DARK_BIT%) Else bits.clear(sf,state.DARK_BIT%)
  r=values(2)
  lx=values(3)
  Erase state.obj_rm%()
  Dim state.obj_rm%(il)
  For i=4 To il+4 : state.obj_rm%(i-4)=values(i) : Next
  counter=values(il+5)
  For i=il+6 To il+13 : alt_counter(i-il-6)=values(i) : Next
  For i=il+14 To il+19 : alt_room(i-il-14)=values(i) : Next
  state.restore%=1
 Else
  con.println("Save file is invalid: "+err$)
 EndIf
 Close #fd%
End Function

' Prompts the user to select a saved game slot.
Function state.select_game%()
 Local i,f$,s$(3) Length 64
 Const fd%=state.FD%
 For i=1 To 10
  f$=state.save_file$(i)
  con.print("  ["+Format$(i,"%2g")+"] ")
  If file.exists%(f$) Then
   Open f$ For Input As fd%
   Line Input #fd%,s$(0) ' header
   Line Input #fd%,s$(1) ' version
   Line Input #fd%,s$(2) ' date/time
   Line Input #fd%,s$(3) ' game name
   Close #fd%
   ' TODO: verify header / version ?
   con.println(s$(2)+" - "+s$(3))
  Else
   con.println("Empty")
  EndIf
 Next i
 con.println()
 s$(0)=prompt$("Saved game number ? ")
 Local game%=Val(s$(0))
 If game%<1 Or game%>10 Then game%=0
 state.select_game%=game%
End Function

' ---- src/state.inc
' src/debug.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
' This file provides subroutines to output debugging information.
Const debug.NEW_LINES%=&h01  ' Put a new line before and after each table dump.
Const debug.TWO_LINES%=&h02  ' Dump each action on two lines rather than one.
Const debug.NO_STARS%=&h04  ' Use + rather than * for synonyms in the vocab table.
Dim debug.enabled%=0
Dim debug.fd%=0
Dim debug.print_flags%=0

Sub debug.print(s$)
 If debug.fd% Then
  Print #debug.fd%,s$;
 Else
  con.print(s$)
 EndIf
End Sub

Sub debug.println(s$)
 If debug.fd% Then
  Print #debug.fd%,s$
 Else
  con.println(s$)
 EndIf
End Sub

Sub debug.dump_actions(nstr$)
 Local i%
 If nstr$="" Then
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
  debug.println("ACTIONS")
  debug.println("-------")
  debug.println()
  For i%=0 To cl : debug.dump_action(i%) : Next
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
 Else
  i%=Int(Val(nstr$))
  If i%<0 Or i%>cl Then
   debug.println("Invalid action index.")
  Else
   debug.dump_action(i%)
  EndIf
 End If
End Sub

Sub debug.dump_action(idx%)
 Local cmd%(3),cond%(4,1),j%,noun%,n$,verb%,v$
 verb%=Int(ca(idx%,0)/150)
 noun%=ca(idx%,0)-verb%*150
 For j%=0 To 4
  cond(j%,1)=Int(ca(idx%,j%+1)/20)
  cond(j%,0)=ca(idx%,j%+1)-cond(j%,1)*20
 Next j
 cmd%(0)=Int(ca(idx%,6)/150)
 cmd%(1)=ca(idx%,6)-cmd%(0)*150
 cmd%(2)=Int(ca(idx%,7)/150)
 cmd%(3)=ca(idx%,7)-cmd%(2)*150
 If verb%=0 Then
  n$=Str$(noun%)
  v$=Str$(verb%)
 Else
  n$=debug.get_noun$(noun%)
  v$=debug.get_verb$(verb%)
 EndIf
 debug.print(str.rpad$(Str$(idx%)+":",6))
 debug.print(str.rpad$(v$,6))
 debug.print(str.rpad$(n$,6))
 debug.print(str.rpad$(debug.get_cond$(cond%(0,0),cond%(0,1)),9))
 debug.print(str.rpad$(debug.get_cond$(cond%(1,0),cond%(1,1)),9))
 debug.print(str.rpad$(debug.get_cond$(cond%(2,0),cond%(2,1)),9))
 debug.print(str.rpad$(debug.get_cond$(cond%(3,0),cond%(3,1)),9))
 debug.print(str.rpad$(debug.get_cond$(cond%(4,0),cond%(4,1)),9))
 If debug.print_flags% And debug.TWO_LINES% Then
  debug.println()
  debug.print("                  ")
 EndIf
 debug.print(str.rpad$(debug.get_cmd$(cmd%(0)),9))
 debug.print(str.rpad$(debug.get_cmd$(cmd%(1)),9))
 debug.print(str.rpad$(debug.get_cmd$(cmd%(2)),9))
 debug.println(debug.get_cmd$(cmd%(3)))
End Sub

Function debug.get_cond$(code%,num%)
 Local s$
 Select Case code%
  Case 0 : s$="Par"
  Case 1 : s$="HAS"
  Case 2 : s$="IN/W"
  Case 3 : s$="AVL"
  Case 4 : s$="IN"
  Case 5 : s$="-IN/W"
  Case 6 : s$="-HAVE"
  Case 7 : s$="-IN"
  Case 8 : s$="BIT"
  Case 9 : s$="-BIT"
  Case 10 : s$="ANY"
  Case 11 : s$="-ANY"
  Case 12 : s$="-AVL"
  Case 13 : s$="-RM0"
  Case 14 : s$="RM0"
  Case 15 : s$="CT<="
  Case 16 : s$="CT>"
  Case 17 : s$="ORIG"
  Case 18 : s$="-ORIG"
  Case 19 : s$="CT="
  Case Else : s$="<Unknown: "+Str$(code%)+">"
 End Select
 debug.get_cond$=s$+" "+Str$(num%)
End Function

Function debug.get_verb$(v%)
 If v%>Bound(nv_str$(),1) Then
  debug.println()
  debug.println("  WARNING: unknown verb "+Str$(v%))
  debug.get_verb$="<"+Str$(v%)+">"
 Else
  debug.get_verb$=nv_str$(v%,0)
 EndIf
End Function

Function debug.get_noun$(n%)
 If n%>Bound(nv_str$(),1) Then
  debug.println()
  debug.println("  WARNING: unknown noun"+Str$(n%))
  debug.get_noun$="<"+Str$(n%)+">"
 Else
  debug.get_noun$=nv_str$(n%,1)
 EndIf
End Function

Function debug.get_cmd$(c%)
 Local s$
 Select Case c%
  Case 0 : s$="0"
  Case 1 To 51 : s$="MSG:"+Str$(c%)
  Case 52 : s$="GETx"
  Case 53 : s$="DROPx"
  Case 54 : s$="GOTOy"
  Case 55 : s$="x->RM0"
  Case 56 : s$="NIGHT"
  Case 57 : s$="DAY"
  Case 58 : s$="SETz"
  Case 59 : s$="x->RM0" ' same as 55
  Case 60 : s$="CLRz"
  Case 61 : s$="DEAD"
  Case 62 : s$="x->y"
  Case 63 : s$="FINI"
  Case 64 : s$="DspRM"
  Case 65 : s$="SCORE"
  Case 66 : s$="INV"
  Case 67 : s$="SET0"
  Case 68 : s$="CLR0"
  Case 69 : s$="FILL"
  Case 70 : s$="CLS"
  Case 71 : s$="SAVEz"
  Case 72 : s$="EXx,x"
  Case 73 : s$="CONT"
  Case 74 : s$="AGETx"
  Case 75 : s$="BYx<-x"
  Case 76 : s$="DspRM"
  Case 77 : s$="CT-1"
  Case 78 : s$="DspCT"
  Case 79 : s$="CT<-n"
  Case 80 : s$="EXRM0"
  Case 81 : s$="EXm,CT"
  Case 82 : s$="CT+n"
  Case 83 : s$="CT-n"
  Case 84 : s$="SAYw"
  Case 85 : s$="SAYwCR"
  Case 86 : s$="SAYCR"
  Case 87 : s$="EXc,CR"
  Case 88 : s$="DELAY"
  Case 102 To 149 : s$="MSG:"+Str$(c%-50)
  Case Else : s$="<Unknown: "+Str$(c%)+">"
 End Select
 debug.get_cmd$=s$
End Function

Sub debug.dump_messages(nstr$)
 Local i%
 If nstr$="" Then
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
  debug.println("MESSAGES")
  debug.println("--------")
  debug.println()
  For i%=0 To ml : debug.dump_message(i%) : Next
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
 Else
  i%=Int(Val(nstr$))
  If i%<0 Or i%>ml Then
   debug.println("Invalid message index.")
  Else
   debug.dump_message(i%)
  EndIf
 EndIf
End Sub

Sub debug.dump_message(idx%)
 Local s$=ms$(idx%)
 If s$="" Then s$="<empty>"
 debug.println(str.rpad$(Str$(idx%)+":",6)+Chr$(34)+s$+Chr$(34))
End Sub

Sub debug.dump_objects(nstr$)
 Local i%
 If nstr$="" Then
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
  debug.println("OBJECTS")
  debug.println("-------")
  debug.println("Id    Room")
  debug.println()
  For i%=0 To il : debug.dump_object(i%) : Next
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
 Else
  i%=Int(Val(nstr$))
  If i%<0 Or i%>il Then
   debug.println("Invalid object index.")
  Else
   debug.dump_object(i%)
  EndIf
 EndIf
End Sub

Sub debug.dump_object(idx%)
 debug.print(str.rpad$(Str$(idx%),6))
 debug.print(str.rpad$(Str$(state.obj_rm%(idx%)),6))
 Local s$=Choice(ia_str$(idx%)="","<empty>",ia_str$(idx%))
 Local p%=1,q%
 Do While p%<=Len(s$)
  q%=InStr(p%,s$,sys.CRLF$)
  If q% Then
   debug.println(Mid$(s$,p%,q%-p%))
   debug.print("            ")
   p%=q%+2
  Else
   debug.println(Mid$(s$,p%))
   p%=256
  EndIf
 Loop
End Sub

Sub debug.dump_rooms(nstr$)
 Local i%
 If nstr$="" Then
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
  debug.println("ROOMS")
  debug.println("-----")
  debug.println()
  For i%=0 To rl : debug.dump_room(i%) : Next
  If debug.print_flags% And debug.NEW_LINES% Then debug.println()
 Else
  i%=Int(Val(nstr$))
  If i%<0 Or i%>rl Then
   debug.println("Invalid room index.")
  Else
   debug.dump_room(i%)
  EndIf
 EndIf
End Sub

Sub debug.dump_room(idx%)
 Local s$=rs$(idx%)
 If s$="" Then
  If idx%=0 Then s$="<storeroom>" Else s$="<empty>"
 EndIf
 debug.println(str.rpad$(Str$(idx%)+":",6)+s$)
 debug.print("      Exits: ")
 Local count%=0
 Local j%
 For j%=0 To 5
  If rm(idx%,j%)>0 Then
   Inc count%
   If count%>1 Then debug.print(", ")
   Select Case j%
    Case 0 : debug.print("North")
    Case 1 : debug.print("South")
    Case 2 : debug.print("East")
    Case 3 : debug.print("West")
    Case 4 : debug.print("Up")
    Case 5 : debug.print("Down")
   End Select
   debug.print(" ["+Str$(rm(idx%,j%))+"]")
  EndIf
 Next
 debug.println(Choice(count%=0,"None",""))
End Sub

Sub debug.dump_state()
 debug.println()
 debug.println("GAME STATE")
 debug.println("----------")
 debug.println("Current room:          "+Str$(r))
 debug.println("Dark flag:             "+Str$(bits.get%(sf,state.DARK_BIT%)))
 debug.println("Remaining light:       "+Str$(lx))
 debug.print("Set flags:             ")
 Local count%,i%
 For i%=0 To 31
  If bits.get%(sf,i%) Then
   Inc count%
   If count%>1 Then debug.print(", ")
   debug.print(Str$(i%))
  EndIf
 Next
 debug.println()
 debug.println("Counter:               "+Str$(counter))
 debug.println("                       0,   1,   2,   3,   4,   5,   6,   7")
 debug.print("Alternate counters: ")
 For i%=0 To 7
  If i%>0 Then debug.print(",")
  debug.print(Str$(alt_counter(i%),4))
 Next
 debug.println()
 debug.print("Alternate rooms:    ")
 For i%=0 To 5
  If i%>0 Then debug.print(",")
  debug.print(Str$(alt_room(i%),4))
 Next
 debug.println()
End Sub

Sub debug.dump_vocabulary()
 If debug.print_flags% And debug.NEW_LINES% Then debug.println()
 debug.println("VOCABULARY")
 debug.println("----------")
 debug.println("Id    Verb      Noun")
 debug.println()
 Local i%,j%,s$,w$
 For i%=0 To nl
  s$=str.rpad$(Str$(i%),6)
  For j%=0 To 1
   w$=Choice(nv_str$(i%,j%)="","<empty>",nv_str$(i%,j%))
   If debug.print_flags% And debug.NO_STARS% Then w$=str.replace$(w$,"*","+")
   Cat s$,Choice(j%=0,str.rpad$(w$,10),w$)
  Next
  debug.println(s$)
 Next
 If debug.print_flags% And debug.NEW_LINES% Then debug.println()
End Sub

' ---- src/debug.inc
' src/interp.inc ++++
' Copyright (c) 2020-2026 Thomas Hugo Williams
' For MMBasic 6
' This file implements the actual interpreter loop.
Const STATE_OK=0
Const STATE_QUIT=1
Const STATE_RESTART=2
Const ACTION_PERFORMED=3
Const ACTION_UNKNOWN=4
Const ACTION_NOT_YET=5
' Hardcoded Object Id's.
Const OBJ_LIT_LAMP%=9 ' The artificial light source.
' Hardcoded Room Id's.
Const ROOM_CARRIED%=255 ' Not -1 as used in original BYTE magazine version of "Pirate Adventure".
Const ROOM_STORE%=0
' Hardcoded Verb Id's.
Const VERB_GET%=10
Const VERB_DROP%=18
Const VERB_NONE%=-1
Const VERB_TOO_MANY%=-2
Const VERB_DEBUG%=-3
Const VERB_DUMP_ACTIONS%=-4
Const VERB_DUMP_MESSAGES%=-5
Const VERB_DUMP_OBJECTS%=-6
Const VERB_DUMP_ROOMS%=-7
Const VERB_DUMP_STATE%=-8
Const VERB_DUMP_VOCAB%=-9
Const VERB_LOOK%=-10
Const VERB_MORE%=-11
Const VERB_RECORD%=-12
Const VERB_REPLAY%=-13
Const VERB_SEED%=-14
Const VERB_WALKTHROUGH%=-15
' Format used for printing lists of objects.
Const OBJ_LIST_FMT_COMMA%=1  ' Comma separated.
Const OBJ_LIST_FMT_NEWLINE%=2  ' Each object on a newline.
Const MSG_OK$="OK."
Dim DIRECTIONS$(5) Length 10=("North","South","East","West","Up","Down")
' Game options persisted to .ini file.
Dim options$(map.new%(10))
map.init(options$())
Dim state
Dim continue_flag=0 ' Flag that, when set will cause the next action(s) to be
' processed if they begin with both a verb and noun = 0.
' TODO: This shouldn't be global
Dim ip ' action parameter pointer
Dim interp.room_state%(9) ' Encodes the state of the last described room:
'   bit       0  - was it light (0) or dark (1)
'   bits  8..23  - room number (though probably only bits 8..15)
'   bits 24..63  - unused
'   bits 64..639 - was object i + 64 in the room
' We use this to determine if we need to describe the current room.
Dim interp.obj_list_fmt%=OBJ_LIST_FMT_NEWLINE%
Dim message_flag%   ' If set then we are constructing a message that might be appended to
' by another message without a CRLF.
Dim describe_flag%  ' If set then when message_string() is called
' first describe the room before displaying the message.
Sub game_loop()
 Local i%,noun,nstr$,verb
 state=STATE_OK
 ' Clear the room_state to ensure first call to describe_room() describes the room.
 For i%=Bound(interp.room_state%(),0) To Bound(interp.room_state%(),1)
  interp.room_state%(i%)=0
 Next
 debug.print_flags%=debug.TWO_LINES% Or debug.NO_STARS%
 message_flag%=0
 Do
  do_automatic_actions()
  describe_room(describe_flag%)
  If state=STATE_OK Then prompt_for_command(verb,noun,nstr$)
  If state=STATE_OK Then do_player_actions(verb,noun,nstr$)
  If state=STATE_OK Then interp.update_lamp()
 Loop While state=STATE_OK
 ' Discard anything left in the console buffer.
 con.buf$=""
End Sub

' Describe the current room if it has changed.
'
' @param  always%  if not 0 then describe the room even if it has not changed.
Sub describe_room(always%)
 ' Even if always% = 1 we call interp.has_changed%() to update interp.room_state%().
 If Not interp.has_changed%() And Not always% Then Exit Sub
 describe_flag%=0
 If is_dark%() Then
  ' Desperate hack! to avoid duplicate messages in SACA #8 "Pyramid of Doom"
  If con.buf$<>"dark!" Then
   If debug.enabled% Then con.print("["+Str$(r)+"] ")
   message_string("I can't see, it's too dark!")
  EndIf
  Exit Sub
 EndIf
 flush_messages()
 ' Ensure at least one empty line before room description.
 If con.count<=1 Then con.println()
 con.foreground("white")
 If debug.enabled% Then con.print("["+Str$(r)+"] ")
 If Left$(rs$(r),1)="*" Then
  ' A leading asterisk means use the room description verbatim.
  con.println(Mid$(rs$(r),2))
 Else
  con.println("I'm in a "+rs$(r))
 EndIf
 con.print("Obvious exits: ")
 Local count,i
 For i=0 To 5
  If rm(r,i)<>0 Then
   Inc count
   If count>1 Then con.print(", ")
   con.print(DIRECTIONS$(i))
   If debug.enabled% Then con.print(" ["+Str$(rm(r,i))+"]")
  EndIf
 Next
 If count=0 Then con.print("None")
 con.println(".")
 con.print("Visible items: ")
 print_object_list(r,"None")
 con.println()
 con.println("<"+String$(con.WIDTH-2,"-")+">")
 con.println()
 con.foreground("green")
End Sub

' Has the current room changed such that is should be redescribed ?
'
' @return 1 iff:
'           - has changed from light to dark or vice-versa.
'           - has remained light but the player is in a different room.
'           - has remained light but the objects in the room have changed.
'
' As a side-effect this function updates interp.room_state%() to the NEW current room state.
Function interp.has_changed%()
 Local was_dark%=interp.room_state%(0) And &h1
 ' First 64-bits of room_state%() encodes whether it is dark and the current room.
 Local x%=is_dark%()+(r<<8)
 Local idx%=0
 If x%<>interp.room_state%(idx%) Then interp.has_changed%=1
 interp.room_state%(idx%)=x%
 Inc idx%
 ' Remaining 576-bits of room_state%() encodes objects in current room.
 Local bit%,obj%
 x%=0
 For obj%=0 To il
  Inc x%,(state.obj_rm%(obj%)=r)<<bit%
  Inc bit%
  If bit%=64 Or obj%=il Then
   If x%<>interp.room_state%(idx%) Then interp.has_changed%=1
   interp.room_state%(idx%)=x%
   bit%=0
   x%=0
   Inc idx%
  EndIf
 Next
 ' If the room was dark and is still dark then return 0/false.
 If was_dark% And (interp.room_state%(0) And &h1) Then interp.has_changed%=0
End Function

' Is the current room dark ?
Function is_dark%()
 If Not bits.get%(sf,state.DARK_BIT%) Then Exit Function
 If state.obj_rm%(OBJ_LIT_LAMP%)=ROOM_CARRIED% Then Exit Function
 If state.obj_rm%(OBJ_LIT_LAMP%)=r Then Exit Function
 is_dark%=1
End Function

' Prints a list of objects, the list does not end with CRLF.
Sub print_object_list(rm,none$)
 Local count,i,p
 For i=0 To il
  If state.obj_rm%(i)=rm Then
   Inc count
   Select Case interp.obj_list_fmt%
    Case OBJ_LIST_FMT_COMMA%
     If count>1 Then con.print(", ")
    Case OBJ_LIST_FMT_NEWLINE%
     con.println()
     con.print("  ")
    Case Else : Error
   End Select
   If debug.enabled% Then con.print("["+Str$(i)+"] ")
   p=InStr(ia_str$(i),"/")
   If p<1 Then
    con.print(ia_str$(i))
   Else
    con.print(Left$(ia_str$(i),p-1))
   EndIf
  EndIf
 Next
 If count=0 Then
  con.print(none$+".")
 ElseIf interp.obj_list_fmt%=OBJ_LIST_FMT_COMMA% Then
  con.print(".")
 EndIf
End Sub

Sub do_automatic_actions()
 Local a,av,an,process_action
 continue_flag=0
 For a=0 To cl
  ' The 'verb' of an automatic action is zero,
  ' If we reach a non-zero verb then we stop processing automatic actions.
  av=Int(ca(a,0)/150)
  If av<>0 Then Exit Sub
  ' The 'noun' of the automatic action.
  ' If this is non-zero then we clear the CONTinue flag.
  an=ca(a,0)-av*150
  If an<>0 Then continue_flag=0
  ' If the CONTinue flag is not set then 'noun' is the probability of the
  ' action occurring.
  If Not continue_flag Then
   If math.pseudo_rnd%(100)>an Then Continue For ' Did not occur, try the next action.
  EndIf
  If Not process_conditions(a) Then Continue For ' Conditions not passed, try the next action.
  do_commands(a)
 Next
End Sub

Sub do_player_actions(verb,noun,nstr$)
 continue_flag=0
 ' Handle "go <direction>"
 If verb=1 And noun<7 Then
  go_direction(noun)
  Exit Sub
 EndIf
 Local a,an,av,result=ACTION_UNKNOWN
 ' We record this so we can determine whether a user action caused any
 ' messages to be output, if it didn't then we will automatically output OK.
 Local num_lines=con.lines
 For a=0 To cl
  av=Int(ca(a,0)/150) ' action - verb
  an=ca(a,0)-av*150 ' action - noun
  If continue_flag Then
   ' If the CONTinue flag is set but the verb or noun is non-zero then the
   ' player action is complete.
   If (av<>0) Or (an<>0) Then Exit For
  ElseIf av<>verb Then
   ' Verb doesn't match, try the next action.
   Continue For
  ElseIf (an<>0) And (an<>noun) Then
   ' Noun doesn't match (or isn't 'ANY'), try the next action.
   Continue For
  EndIf
  If result=ACTION_UNKNOWN Then result=ACTION_NOT_YET
  If Not process_conditions(a) Then Continue For ' Conditions not passed, try the next action.
  do_commands(a,nstr$)
  result=ACTION_PERFORMED
  ' Stop processing player actions when an action is performed and the CONTinue
  ' flag is not set.
  If Not continue_flag Then Exit For
 Next
 ' Whilst the action table contains some specialist pickup and drop handling
 ' the general case is handled by this code.
 If result=ACTION_UNKNOWN Then
  Select Case verb
   Case VERB_GET% : do_get(noun,nstr$) : result=ACTION_PERFORMED
   Case VERB_DROP% : do_drop(noun,nstr$) : result=ACTION_PERFORMED
  End Select
 EndIf
 Select Case result
  Case ACTION_UNKNOWN : message_string("I don't understand your command.")
  Case ACTION_NOT_YET : message_string("I can't do that yet.")
  Case Else : If Not message_flag% Then message_string(MSG_OK$)
 End Select
End Sub

' @param  a  current action index
Function process_conditions(a)
 Local code,i,ok,value
 ok=1
 For i=1 To 5
  value=Int(ca(a,i)/20)
  code=ca(a,i)-value*20
  ok=ok And evaluate_condition(code,value)
  If Not ok Then Exit For
 Next
 process_conditions=ok
End Function

' @param  a  current action index
Sub do_commands(a,nstr$)
 Local cmd(3)
 ip=0 ' reset parameter pointer
 cmd(0)=Int(ca(a,6)/150)
 cmd(1)=ca(a,6)-cmd(0)*150
 cmd(2)=Int(ca(a,7)/150)
 cmd(3)=ca(a,7)-cmd(2)*150
 do_command(a,cmd(0),nstr$)
 do_command(a,cmd(1),nstr$)
 do_command(a,cmd(2),nstr$)
 do_command(a,cmd(3),nstr$)
End Sub

Sub go_direction(noun)
 Local dark%=is_dark%()
 If dark% Then message_string("Dangerous to move in the dark!")
 If noun<1 Then message_string("Give me a direction too.") : Exit Sub
 Local k=rm(r,noun-1)
 If k<1 Then
  If dark% Then
   message_string("I fell down and broke my neck.")
   k=rl
   bits.clear(sf,state.DARK_BIT%)
  Else
   message_string("I can't go in that direction.")
   Exit Sub
  EndIf
 EndIf
 r=k
 message_string(MSG_OK$)
 describe_flag%=1
End Sub

Function evaluate_condition(code,value)
 Local i,pass
 Select Case code
  Case 0
   pass=1
  Case 1
   ' Passes if the player is carrying object <value>.
   pass=(state.obj_rm%(value)=ROOM_CARRIED%)
  Case 2
   ' Passes if the player is in the same room (but not carrying) object <value>.
   pass=(state.obj_rm%(value)=r)
  Case 3
   ' Passes if object <value> is available; i.e. carried or in the current room
   pass=(state.obj_rm%(value)=ROOM_CARRIED%) Or (state.obj_rm%(value)=r)
  Case 4
   ' Passes if the player is in room <value>.
   pass=(r=value)
  Case 5
   ' Passes if the player is carrying object <value> or it is in a different room.
   pass=(state.obj_rm%(value)<>r)
  Case 6
   ' Passes if the player is not carrying object <value>.
   pass=(state.obj_rm%(value)<>ROOM_CARRIED%)
  Case 7
   ' Passes if the player is not in room <value>.
   pass=(r<>value)
  Case 8
   ' Passes if numbered flag-bit set.
   pass=bits.get%(sf,value)
  Case 9
   ' Passes if numbered flag-bit clear.
   pass=Not bits.get%(sf,value)
  Case 10
   ' Passes if the player is carrying anything.
   pass=count_carried%()>0
  Case 11
   ' Passes if the player is carrying nothing.
   pass=count_carried%()=0
  Case 12
   ' Passes if object <value> is not available; i.e. not carried or in the current room.
   pass=(state.obj_rm%(value)<>ROOM_CARRIED%) And (state.obj_rm%(value)<>r)
  Case 13
   ' Passes if object <value> is not in the store room (0)
   pass=(state.obj_rm%(value)<>ROOM_STORE%)
  Case 14
   ' Passes if object <value> is in the store room (0)
   pass=(state.obj_rm%(value)=ROOM_STORE%)
  Case 15
   ' Passes if counter <= the value.
   pass=(counter<=value)
  Case 16
   ' Passes if counter > the value.
   pass=(counter>value)
  Case 17
   ' Passes if the numbered object is is the room it started in.
   pass=(state.obj_rm%(value)=advent.obj_rm%(value))
  Case 18
   ' Passes if the numbered object is not in the room it started in.
   pass=(state.obj_rm%(value)<>advent.obj_rm%(value))
  Case 19
   ' Passes if the counter is equal to the value.
   pass=(counter=value)
  Case Else
   Error "Unknown condition: "+Str$(code)
 End Select
 evaluate_condition=pass
End Function

Function count_carried%()
 Local i%
 For i%=0 To il
  If state.obj_rm%(i)=ROOM_CARRIED% Then Inc count_carried%
 Next
End Function

' @param  a  current action index
Sub do_command(a,cmd,nstr$)
 Local i,p,x,y
 Select Case cmd
  Case 0
   ' Do nothing ? Or should it display message 0 which is null ?
  Case 1 To 51
   ' Display corresponding message.
   message_id(cmd)
  Case 52
   ' GETx
   ' Pick up the Par #1 object unless player already carrying the limit.
   ' The object may be in this room, or in any other room.
   p=get_parameter(a)
   If count_carried%()>=mx Then
    message_string("I've too much to carry. Try 'Inventory'.")
   Else
    state.obj_rm%(p)=ROOM_CARRIED%
   EndIf
  Case 53
   ' DROPx
   ' Drop the Par #1 object in the current room.
   ' The object may be carried or in any other room
   p=get_parameter(a)
   state.obj_rm%(p)=r
  Case 54
   ' GOTOy
   ' Move the player to the Par #1 room.
   ' This command should be followed by a DspRM (64) command.
   ' Also it may need to be followed by a NIGHT (56) or DAY (57) command.
   p=get_parameter(a)
   r=p
  Case 55,59
   ' x->RM0
   ' Move the Par #1 object to room 0 (the storeroom).
   p=get_parameter(a)
   state.obj_rm%(p)=0
  Case 56
   ' NIGHT
   ' Set the darkness flag-bit (15).
   ' It will be dark if the artificial light source is not available,
   ' so this should be followed by a DspRM (64) command.
   bits.set(sf,state.DARK_BIT%)
  Case 57
   ' DAY
   ' Clear the darkness flag-bit (15).
   ' This should be followed by a DspRM (64) command.
   bits.clear(sf,state.DARK_BIT%)
  Case 58
   ' SETz
   ' Set the Par #1 flag-bit.
   p=get_parameter(a)
   bits.set(sf,p)
   ' Case 59
   ' x->RM
   ' This command also moves the Par #1 object to room 0 (the storeroom), like command 55.
  Case 60
   ' CLRz
   ' Clear the Par #1 flag-bit.
   p=get_parameter(a)
   bits.clear(sf,p)
  Case 61
   ' DEAD
   ' Tell the player they are dead,
   ' Goto the last room (usually some form of limbo),
   ' make it DAY and display the room.
   message_string("I'm dead...")
   bits.clear(sf,state.DARK_BIT%)
   r=rl
   describe_flag%=1
  Case 62
   ' x->y
   ' Move the Par #1 object to the Par #2 room.
   ' This will automatically display the room if the object came from,
   ' or went to the current room.
   x=get_parameter(a)
   y=get_parameter(a)
   state.obj_rm%(x)=y
  Case 63
   ' FINI
   ' Tell the player the game is over and ask if they want to play again.
   flush_messages()
   If con.fd_out>0 Then script.record_off()
   If con.fd_in>0 Then script.replay_off()
   Local s$=prompt$("The game is now over, would you like to play again [Y|n]? ")
   If LCase$(s$)="n" Then state=STATE_QUIT Else state=STATE_RESTART
  Case 64,76
   ' DspRM
   ' Display the current room.
   ' This checks if the darkness flag-bit (15) is set and the artificial
   ' light (object 9) is not available.
   ' If there is light, it displays the room description, the objects in
   ' the room and any obvious exits.
   describe_flag%=1
  Case 65
   ' SCORE
   ' Tells the player how many treasures they have collected by getting
   ' them to the treasure room and what their percentage of the total is.
   x=0
   For i=1 To il
    If state.obj_rm%(i)=tr And Left$(ia_str$(i),1)="*" Then Inc x
   Next
   message_string("I've stored "+Str$(x)+" of "+Str$(tt)+" treasures.")
   If tt>0 Then
    message_string("On a scale of 0 to 100 that rates a "+Str$(Int(x/tt*100))+".")
    If x=tt Then
     message_string("WELL DONE !!!")
     do_command(a,63,nstr$)
    EndIf
   EndIf
  Case 66
   ' INV
   ' Tells the player what objects they are carrying.
   message_string("I'm carrying: ")
   print_object_list(ROOM_CARRIED%,"Nothing")
  Case 67
   ' SET0
   ' Sets the flag-bit numbered 0 (this may be convenient because no parameter is used).
   bits.set(sf,0)
  Case 68
   ' CLR0
   ' Clears the flag-bit numbered 0 (this may be convenient because no parameter is used).
   bits.clear(sf,0)
  Case 69
   ' FILL
   ' Re-fill the artifical light source and clear flag-bit 16 which
   ' indicates that it was empty. This also picks up the artifical light
   ' source (object 9). This command should be followed by a x->RM0 to store
   ' the unlighted light source (these are two different objects).
   lx=lt
   state.obj_rm%(OBJ_LIT_LAMP%)=ROOM_CARRIED%
   bits.clear(sf,state.LAMP_OUT_BIT%)
  Case 70
   ' CLS
   ' As far as I can tell a CLS is always followed by a DspRM thus making it superfluous.
  Case 71
   ' SAVEz
   ' This command saves the current game state to a file.
   x=state.save%()
   If Not x Then message_string("Cancelled.")
  Case 72
   ' EXx,x
   ' This command exchanges the room locations of the Par #1 object and the
   ' Par #2 object. If the objects in the current room change, the new
   ' description will be displayed.
   x=get_parameter(a)  ' x = object 1
   y=get_parameter(a)  ' y = object 2
   p=state.obj_rm%(x)  ' p = location of object 1
   state.obj_rm%(x)=state.obj_rm%(y)
   state.obj_rm%(y)=p
  Case 73
   ' CONT
   ' This command sets a flag to allow more than four commands to be executed. When all the
   ' commands in this action entry have been performed, the commands in the next action entry
   ' will also be executed if the verb and noun are both zero. The condition fields of the new
   ' action entry will contain the parameters for the commands in the new action entry. When an
   ' action entry with a non-zero verb or noun is encountered, the continue flag is cleared.
   continue_flag=1
  Case 74
   ' AGETx
   ' Always pick up the Par #1 object, even if that would cause the carry limit to be exceeded.
   ' Otherwise, this is like command 52, GETx.
   p=get_parameter(a)
   state.obj_rm%(p)=ROOM_CARRIED%
  Case 75
   ' BYx<-x
   ' Put the Par #1 object in the same place as the Par #2 object. If the Par #2 object is being
   ' carried, this will pick up the Par #1 object too, regardless of the carry limit.
   ' If this changes the objects in the current room, the room will be displayed again.
   x=get_parameter(a) ' x = object 1
   y=get_parameter(a) ' y = object 2
   state.obj_rm%(x)=state.obj_rm%(y)
   '  Case 76
   ' DspRM
   ' This displays the current room, just like command 64.
  Case 77
   ' CT-1
   ' This subtracts 1 from the counter value.
   Inc counter,-1
  Case 78
   ' DspCT
   ' This displays the current value of the counter.
   message_string(Str$(counter))
  Case 79
   ' CT<-n
   ' This sets the counter to the Par #1 value.
   p=get_parameter(a)
   counter=p
  Case 80
   ' EXRM0
   ' This exchanges the values of the current room register with the alternate room register 0.
   ' This may be used to save the room a player came from in order to put him back there later.
   ' This should be followed by a GOTOy command if the alternate room register 0 had not already
   ' been set.
   x=r
   r=alt_room(0)
   alt_room(0)=x
  Case 81
   ' EXm,CT
   ' This command exchanges the values of the counter and the Par #1 alternate counter. There
   ' are eight alternate counters numbered from 0 to 7. Also, the time limit may be accessed as
   ' alternate counter 8.
   p=get_parameter(a)
   x=counter
   Select Case p
    Case 0 To 7
     counter=alt_counter(p)
     alt_counter(p)=x
    Case 8  ' lamp duration.
     counter=lx
     lx=x
    Case Else
     Error "illegal counter: "+Str$(p)
   End Select
  Case 82
   ' CT+n
   ' This adds the Par #1 value to the counter.
   p=get_parameter(a)
   Inc counter,p
  Case 83
   ' CT-n
   ' This subtracts the Par #1 value from the counter.
   p=get_parameter(a)
   Inc counter,-p
  Case 84
   ' SAYw
   ' This says the noun (second word) input by the player.
   message_string("'"+nstr$+"'")
  Case 85
   ' SAYwCR
   ' This says the noun (second word) input by the player and starts a new line.
   message_string("'"+nstr$+"'"+sys.CRLF$)
  Case 86
   ' SAYCR
   ' This just starts a new line on the display.
   message_string(sys.CRLF$)
  Case 87
   ' EXc,CR
   ' This exchanges the values of the current room register with the Par #1 alternate room
   ' register. This may be used to remember more than one room. There are six alternate room
   ' registers numbered from 0 to 5.
   p=get_parameter(a)
   x=r
   r=alt_room(p)
   alt_room(p)=x
  Case 88
   ' DELAY
   ' This command delays about 1 second before going on to the next command.
   con.flush()
   Pause 1000
  Case 102 To 149
   ' Display messages 52-99.
   message_id(cmd-50)
  Case Else
   Error "Unknown command: "+Str$(cmd)
 End Select
End Sub

' @param   a   current action index
' @global  ip  parameter pointer
Function get_parameter(a)
 Local code,value
 Do
  Inc ip
  value=Int(ca(a,ip)/20)
  code=ca(a,ip)-value*20
 Loop While code<>0
 get_parameter=value
End Function

Sub prompt_for_command(verb,noun,nstr$)
 Local s$
 Do
  flush_messages()
  ' Ensure at least one empty line before prompt.
  If con.count<=1 Then con.println()
  s$=prompt$("What shall I do ? ",1)
  parse(s$,verb,noun,nstr$)
  Select Case verb
   Case 0 : message_string("You use word(s) I don't know!")
   Case VERB_NONE% : ' Do nothing, user will be prompted for command again.
   Case VERB_TOO_MANY% : message_string("I only understand two word commands!")
   Case VERB_DEBUG% : message_string(MSG_OK$) : debug.enabled%=(nstr$="on")
   Case VERB_DUMP_ACTIONS% : debug.dump_actions(nstr$)
   Case VERB_DUMP_MESSAGES% : debug.dump_messages(nstr$)
   Case VERB_DUMP_OBJECTS% : debug.dump_objects(nstr$)
   Case VERB_DUMP_ROOMS% : debug.dump_rooms(nstr$)
   Case VERB_DUMP_STATE% : debug.dump_state()
   Case VERB_DUMP_VOCAB% : debug.dump_vocabulary()
   Case VERB_LOOK% : describe_room(1)
   Case VERB_MORE% : message_string(MSG_OK$) : con.more=(nstr$="on")
   Case VERB_RECORD%
    flush_messages()
    If nstr$="on" Then
     seed_random_number_generator("record")
     script.record_on()
    Else
     script.record_off()
    EndIf
   Case VERB_REPLAY%
    flush_messages()
    If nstr$="on" Then
     seed_random_number_generator("record")
     script.replay_on()
    Else
     script.replay_off()
    EndIf
   Case VERB_SEED% : seed_random_number_generator(nstr$)
   Case VERB_WALKTHROUGH% : seed_random_number_generator("record") : script.walkthrough()
   Case Else : Exit Do ' Handle 'verb' in calling code.
  End Select
 Loop
End Sub

Sub message_id(id%)
 Local msg$=ms$(id%)
 If msg$="OK" Then msg$=MSG_OK$
 If debug.enabled% Then
  message_string("["+Str$(id%)+"] "+msg$)
 Else
  message_string(msg$)
 EndIf
End Sub

' Outputs a message string.
'
' It's a bit of a crap-shoot to work with various idiosyncracies mostly
' surrounding when a room needs to be redescribed.
'
' 1) if the current room is dark or the message is "OK." output the message.
' 2) then if the describe_flag% is set and the message is not "OK."
'    redescribe the current room.
' 3) then output the message if it wasn't output at (1).
'
' @param  id%   message id to lookup, if -1 then ...
' @param  msg$  ... use this string for the message.
Sub message_string(msg$)
 If msg$="" Then Error "Unexpected empty message"
 Local msg_first%=is_dark%() Or (msg$=MSG_OK$)
 If msg_first% Then message_internal(msg$)
 If describe_flag% And Not(msg$=MSG_OK$) Then describe_room(1)
 If Not msg_first% Then message_internal(msg$)
End Sub

Sub message_internal(msg$)
 ' Handle appending this message to a previous one.
 If message_flag% Then
  If Left$(msg$,2)=sys.CRLF$ Then
   ' If new message starts CRLF then do nothing, it will be appended verbatim.
  Else
   Select Case Asc(Left$(msg$,1))
    Case Asc("'"),Asc("`")    ' New message starts with single quote.
     con.print(" ")
    Case Asc("a") To Asc("z")  ' New message starts lower-case.
     con.print(" ")
    Case Asc("0") To Asc("9") ' New message starts number.
     con.print(" ")
    Case Else
     con.println()
   End Select
  EndIf
 EndIf
 con.print(msg$)
 message_flag%=1
End Sub

Sub flush_messages()
 If message_flag% Then
  con.println()
  message_flag%=0
 EndIf
End Sub

Function prompt$(s$,echo)
 message_string(s$)
 message_flag%=0
 con.foreground("white")
 prompt$=con.in$("",echo)
 con.foreground("green")
End Function

Sub parse(s$,verb,noun,nstr$)
 Local vstr$
 vstr$=LCase$(str.next_token$(s$," ",1))
 vstr$=Choice(vstr$=sys.NO_DATA$,"",vstr$)
 nstr$=LCase$(str.next_token$())
 nstr$=Choice(nstr$=sys.NO_DATA$,"",nstr$)
 ' Handle empty input.
 If vstr$="" Then verb=VERB_NONE : Exit Sub
 ' Ignore input beginning with '#', used for comments in script files.
 If Left$(vstr$,1)="#" Then verb=VERB_NONE : Exit Sub
 ' Reject commands of more than two words.
 If str.next_token$()<>sys.NO_DATA$ Then verb=VERB_TOO_MANY : Exit Sub
 verb=lookup_meta_command(vstr$,nstr$)
 If verb<>0 Then Exit Sub
 ' Hack to allow use of common abbreviations, and avoid typing 'go'.
 If nstr$="" Then
  Select Case vstr$
   Case "n","nor","nort","north" : vstr$="go" : nstr$="north"
   Case "s","sou","sout","south" : vstr$="go" : nstr$="south"
   Case "e","eas","east" : vstr$="go" : nstr$="east"
   Case "w","wes","west" : vstr$="go" : nstr$="west"
   Case "u","up" : vstr$="go" : nstr$="up"
   Case "d","dow","down" : vstr$="go" : nstr$="down"
   Case "i","inv" : vstr$="inventory"
   Case "q" : vstr$="quit"
   Case "save" : vstr$="save" : nstr$="game"
  End Select
 EndIf
 If Left$(vstr$,ln)=Left$("quit",ln) Then
  Local pr$=prompt$("Are you sure you want to quit [y|N]? ")
  If LCase$(pr$)<>"y" Then verb=VERB_NONE : Exit Sub
 EndIf
 verb=lookup_word(Left$(vstr$,ln),0)
 noun=lookup_word(Left$(nstr$,ln),1)
 ' If TAKE is not in the vocabulary then treat it as a synonym for GET.
 If verb=0 Then
  If Left$(vstr$,ln)=Left$("take",ln) Then verb=VERB_GET%
 EndIf
End Sub

Function lookup_meta_command(vstr$,nstr$)
 Const TYPE_BOOLEAN%=1,TYPE_OTHER%=2
 Local verb%,type%
 Select Case Left$(vstr$,4)
  Case "*act" : verb%=VERB_DUMP_ACTIONS% : type%=TYPE_OTHER%
  Case "*deb" : verb%=VERB_DEBUG% : type%=TYPE_BOOLEAN%
  Case "*loo" : verb%=VERB_LOOK%
  Case "*mes" : verb%=VERB_DUMP_MESSAGES% : type%=TYPE_OTHER%
  Case "*mor" : verb%=VERB_MORE% : type%=TYPE_BOOLEAN%
  Case "*msg" : verb%=VERB_DUMP_MESSAGES% : type%=TYPE_OTHER%
  Case "*obj" : verb%=VERB_DUMP_OBJECTS% : type%=TYPE_OTHER%
  Case "*rec" : verb%=VERB_RECORD% : type%=TYPE_BOOLEAN%
  Case "*rep" : verb%=VERB_REPLAY% : type%=TYPE_BOOLEAN%
  Case "*roo" : verb%=VERB_DUMP_ROOMS% : type%=TYPE_OTHER%
  Case "*see" : verb%=VERB_SEED% : type%=TYPE_OTHER%
  Case "*sta" : verb%=VERB_DUMP_STATE%
  Case "*voc" : verb%=VERB_DUMP_VOCAB%
  Case "*wal" : verb%=VERB_WALKTHROUGH%
 End Select
 If verb%=0 Then Exit Function
 Select Case type%
  Case 0
   If nstr$<>"" Then Exit Function ' Unexpected noun.
  Case TYPE_BOOLEAN%
   If nstr$="" Then nstr$="on"
   If nstr$<>"on" And nstr$<>"off" Then Exit Function ' Invalid noun.
 End Select
 lookup_meta_command=verb%
End Function

' @param  word$  word to lookup
' @param  dict   dictionary to look in, 0 for verbs and 1 for nouns
Function lookup_word(word$,dict)
 Local i,s$
 lookup_word=0
 If word$="" Then Exit Function
 For i=0 To nl
  s$=nv_str$(i,dict)
  If Left$(s$,1)="*" Then s$=Mid$(s$,2)
  s$=Left$(s$,ln) ' Trim to the vocabulary word length which the
  ' adventure files don't always respect.
  If word$=LCase$(s$) Then
   ' Word found, if it's a synonym then use previous word.
   lookup_word=i
   Do While Left$(nv_str$(lookup_word,dict),1)="*"
    Inc lookup_word,-1
   Loop
   Exit For
  EndIf
 Next
End Function

' Seeds the random number generator.
'
' @param  s$  the seed, either:
'              - "option" to use the value stored in options$(), or the TIMER value if that is 0.
'              - "record" to use the hardcoded seed value 7.
'              - an integer > 0.
Sub seed_random_number_generator(s$)
 Local seed%=0
 If s$="option" Then
  seed%=Val(map.get$(options$(),"seed"))
  If seed%=0 Then seed%=Timer
 ElseIf s$="record" Then
  seed%=7
 ElseIf s$=Str$(Int(Val(s$)))) Then
  seed%=Val(s$)
 EndIf
 If seed%>0 Then
  Local _=math.pseudo_rnd%(-seed%)
  If s$=Str$(seed%) Then message_string(MSG_OK$)
 Else
  message_string("Invalid seed, should be integer > 0.")
 EndIf
End Sub

' Picks up the object identified by 'nstr$'
Sub do_get(noun,nstr$)
 Local i,k,obj$=obj_name$(noun,nstr$)
 If nstr$="" Then message_string("What?") : Exit Sub
 If count_carried%()>=mx Then
  message_string("I've too much to carry!")
  Exit Sub
 EndIf
 For i=0 To il
  If obj_noun$(i)=obj$ Then
   If state.obj_rm%(i)=r Then
    state.obj_rm%(i)=ROOM_CARRIED%
    k=3
    Exit For
   Else
    k=2
   EndIf
  EndIf
 Next
 Select Case k
  Case 0 : message_string("It's beyond my power to do that.")
  Case 2 : message_string("I don't see it here.")
  Case 3 : message_string(MSG_OK$)
  Case Else : Error "Unknown GET state, k = "+Str$(k)
 End Select
End Sub

' Gets an object name corresponding to a 'noun' and/or 'nstr$' supplied by the player.
Function obj_name$(noun,nstr$)
 obj_name$=Choice(noun=0,nstr$,nv_str$(noun,1)) ' Use correct synonym.
 obj_name$=Left$(obj_name$,ln)                      ' Trim to vocabulary word length.
 obj_name$=LCase$(obj_name$)                         ' Lower-case.
End Function

' Gets the (lower-case) noun for referring to the given object.
Function obj_noun$(i)
 Local en,st
 st=InStr(ia_str$(i),"/")
 If st>1 Then
  en=InStr(st+1,ia_str$(i),"/")
  If en<st+1 Then Error "Missing trailing '/'"
  obj_noun$=LCase$(Mid$(ia_str$(i),st+1,en-st-1))
 EndIf
 If Len(obj_noun$)>ln Then Error "Object noun too long: "+obj_noun$
End Function

' Drops the object identified by 'noun' and/or 'nstr$'
Sub do_drop(noun,nstr$)
 Local i,k=0,obj$=obj_name$(noun,nstr$)
 For i=0 To il
  If obj_noun$(i)=obj$ Then
   If state.obj_rm%(i)=ROOM_CARRIED% Then
    state.obj_rm%(i)=r
    k=3
    Exit For
   Else
    k=1
   EndIf
  EndIf
 Next
 Select Case k
  Case 0 : message_string("It's beyond my power to do that.")
  Case 1 : message_string("I'm not carrying it!")
  Case 3 : message_string(MSG_OK$)
  Case Else : Error "Unknown DROP state, k = "+Str$(k)
 End Select
End Sub

Sub interp.update_lamp()
 ' Don't update the lamp duration if it is in the store.
 If state.obj_rm%(OBJ_LIT_LAMP%)=ROOM_STORE% Then Exit Sub
 ' Don't update the lamp duration if <= -1;
 ' the value of -1 is used by Brian Howarth's games to indicate infinite duration.
 If lx<=-1 Then Exit Sub
 ' Decrement the duration but don't go below 0.
 If lx>0 Then Inc lx,-1
 If lx>=25 Then Exit Sub
 ' Only display messages about the lamp if the player is carrying or in the same room as it.
 Local lamp_room%=state.obj_rm%(OBJ_LIT_LAMP%)
 If lamp_room%=ROOM_CARRIED% Or lamp_room%=r Then
  If lx=0 Then
   message_string("Light has run out!")
  Else
   message_string("Light runs out in "+Str$(lx)+" turns!")
  EndIf
 EndIf
 If lx=0 Then
  bits.set(sf,state.LAMP_OUT_BIT%)
  ' Apparently only older adventures automatically return the lamp to the store.
  If map.get$(options$(),"prehistoric_lamp")="1" Then
   state.obj_rm%(OBJ_LIT_LAMP%)=ROOM_STORE%
  EndIf
 EndIf
End Sub

' ---- src/interp.inc
Const ROOT_DIR$=file.get_canonical$(Mm.Info$(Path)+"..")
Const TMP_DIR$=ROOT_DIR$+"/tmp"
Const INI_FILE$=ROOT_DIR$+"/saaint.ini"
Option Break 4
On Key 3,end_game()
configure_console()
main()
End

Sub configure_console()
 If Mm.VRes=320 And Mm.HRes=320 Then
  ' PicoCalc
  con.HEIGHT%=Mm.VRes/Mm.Info(FontHeight)
  con.WIDTH%=Mm.HRes/Mm.Info(FontWidth)
 Else
  con.HEIGHT%=33
  con.WIDTH%=80
 EndIf
 Select Case Mm.Device$
  Case "Colour Maximite 2","Colour Maximite 2 G2"
   Mode 2
  Case "MMB4L"
   Option CodePage "MMB4L"
   On Error Skip 1 ' CONSOLE SETSIZE can fail, but keep going if it does.
   Console SetSize con.WIDTH%,con.HEIGHT%
   Console SetTitle "SAAINT v"+sys.format_version$(SAAINT_VERSION)
  Case "MMBasic for Windows"
   ' Use the current mode/font and scale the console appropriately.
   Local h%=Mm.VRes\Mm.Info(FontHeight)
   Local w%=Mm.HRes\Mm.Info(FontWidth)
   If h%<con.HEIGHT% Or w%<con.WIDTH% Then
    Local errmsg$="Invalid mode/font SAAINT requires at least "
    Cat errmsg$,Str$(con.WIDTH%)+"x"+Str$(con.HEIGHT%)+" characters."
    Error errmsg$
   EndIf
   con.HEIGHT%=h%
   con.WIDTH%=w%
 End Select
End Sub

Sub main()
 If file.mkdir%(TMP_DIR$)<>sys.SUCCESS Then Error sys.err$
 read_inifile()
 ' Allow an adventure file to be specified at the command line.
 Local f$
 If str.trim$(Mm.CmdLine$)<>"" Then
  If Left$(str.trim$(Mm.CmdLine$),7)="--shell" Then Goto main_menu
  f$=catalogue.find$(str.trim$(Mm.CmdLine$))
  If f$="" Then
   Print "File not found: "+str.trim$(Mm.CmdLine$)
   End
  Else
   Goto read_adventure
  EndIf
 EndIf
main_menu:
 f$=map.get$(options$(),"current")
 If f$<>"" Then f$=catalogue.find$(str.trim$(f$))
 advent.free()
 Do
  Select Case menus.main$(f$)
   Case "#play" : Goto read_adventure
   Case "#select" : Goto select_adventure
   Case "#credits" : menus.credits(1)
   Case "#instructions" : menus.instructions(1)
   Case "#quit" : Goto quit_game
  End Select
 Loop
select_adventure:
 f$=menus.choose_advent$()
 If f$="" Then Goto main_menu
 f$=catalogue.find$(f$)
read_adventure:
 Cls
 con.foreground("white")
 con.println("Loading "+file.get_canonical$(f$)+" ...")
 advent.read_dat(f$)
 metadata.read_ext(f$)
adventure_menu:
 Do
  Select Case menus.adventure$()
   Case "#start" : Goto new_game
   Case "#restore" : Goto restore_game
   Case "#credits" : menus.credits()
   Case "#instructions" : menus.instructions()
   Case "#back" : Goto select_adventure
   Case "#quit" : Goto quit_game
  End Select
 Loop
new_game:
 state.reset()
 Goto play_game
restore_game:
 If state.restore%() Then Goto play_game
 Pause 2000
 Goto adventure_menu
play_game:
 con.more=map.get$(options$(),"more")<>"0"
 seed_random_number_generator("option")
 write_inifile() ' Updates .ini file with the selected adventure.
 twm.enable_cursor(1)
 Cls
 game_loop()
 con.close_all()
 write_inifile() ' Updates .ini file with any options changed during play.
 If state<>STATE_QUIT Then Goto adventure_menu
quit_game:
 end_game()
End Sub

' Reads contents of options$() map from .ini file.
Sub read_inifile()
 ' Backward compatibility: if the .ini file isn't present in "<saaint-root>"
 ' but it is present in "<saaint-root>/src" then move the latter to the former.
 If Not file.exists%(INI_FILE$) Then
  If file.exists%(ROOT_DIR$+"/src/saaint.ini") Then
   Rename ROOT_DIR$+"/src/saaint.ini" As INI_FILE$
  EndIf
 EndIf
 If file.exists%(INI_FILE$) Then
  Open INI_FILE$ For Input As #1
  Local ok%=inifile.read%(1,options$())
  Close #1
  If Not ok% Then Error "read_inifile: "+sys.err$
 EndIf
 Local s$
 s$=map.get$(options$(),"current")
 If s$=sys.NO_DATA$ Then map.put(options$(),"current","")
 s$=map.get$(options$(),"more")
 Select Case s$
  Case "0","1" : ' the value is valid so do nothing.
  Case Else : map.put(options$(),"more","1")
 End Select
 s$=map.get$(options$(),"prehistoric_lamp")
 Select Case s$
  Case "0","1" : ' the value is valid so do nothing.
  Case Else : map.put(options$(),"prehistoric_lamp","1")
 End Select
 s$=map.get$(options$(),"seed")
 ' If the value isn't a +ve integer then make it 0.
 If Str$(Int(Val(s$)))<>s$ Or Val(s$)<0 Then map.put(options$(),"seed","0")
End Sub

' Writes contents of options$() map to .ini file.
Sub write_inifile()
 map.put(options$(),"current",advent.file$)
 map.put(options$(),"more",Str$(con.more))
 ' We do not need to update the value of "seed" since the program never changes it.
 Open INI_FILE$ For Output As #1
 Local ok%=inifile.write%(1,options$())
 Close #1
 If Not ok% Then Error "write_inifile: "+sys.err$
End Sub

Sub end_game()
 con.endl()
 con.println("Goodbye!",1)
 con.close_all()
 Pause 2000
 If InStr(Mm.CmdLine$,"--shell") Then sys.run_shell()
 End
End Sub

