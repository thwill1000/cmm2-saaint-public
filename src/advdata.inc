' Scott Adams Adventure Game Interpreter for Colour Maximite 2
' Original TRS-80 Level II BASIC code (c) Scott Adams 1978
' MMBasic port for CMM2 by Thomas Hugo Williams 2020
' Modified to suit some found .dat files. Bill McKinley
' Each item of data is on a separate line so each one needs its own INPUT statement

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

dim as string temp, temp1, temp2, temp3
dim flag as integer
dim string crlf$ = chr$(10) + chr$(13)

Sub adv.read(f$)
  Open f$ For Input AS 1
  Input #1, il ' read the first bit of data and disregard it.
  Input #1, il
  Input #1, cl
  Input #1, nl
  Input #1, rl
  Input #1, mx
  Input #1, ar
  Input #1, tt
  Input #1, ln
  Input #1, lt
  Input #1, ml
  Input #1, tr

  Dim ca(cl, 7)      ' action table
  Dim nv_str$(nl, 1) ' vocabulary table - verbs at index 0, nouns at index 1
  Dim ia_str$(il)    ' object descriptions
  Dim ia(il)         ' object locations
  Dim i2(il)         ' backup copy of object locations
  Dim rs$(rl)        ' room descriptions
  Dim rm(rl, 5)      ' room exits: N, S, E, W, U, D
  Dim ms$(ml)        ' messages table

  Local i, j
  ' Read action table.
  For i = 0 To cl
    for j = 0 to 7
      Input #1,ca(i,j)
    next j
  Next i

  ' Read vocabulary table -Bill
  ' Revised because not all files have the vocab list in multiples of 2
  For i = 0 To nl
    For j = 0 TO 1
      Input #1,nv_str$(i,j)
    next j
  next i

  ' Read rooms.
  For i = 0 TO rl
    Input #1, rm(i,0)
    Input #1, rm(i,1)
    Input #1, rm(i,2)
    Input #1, rm(i,3)
    Input #1, rm(i,4)
    Input #1, rm(i,5)
    ' Room descriptions sometimes span multiple lines
    ' Need to remove leading and trailing quotes
    line input #1, rs$(i)
    if left$(rs$(i),1) = chr$(34) then rs$(i) = right$(rs$(i),len(rs$(i))-1)
    if right$(rs$(i),1) = chr$(34) then
      rs$(i) = left$(rs$(i),len(rs$(i))-1)
    else
      temp = rs$(i)
      line input #1, rs$(i)
      temp = temp + crlf$ + rs$(i)
      if right$(temp,1) = chr$(34) then
        temp = left$(temp,len(temp)-1) ' strip off the leading quote
      else
        line input #1, rs$(i)
        temp = temp + crlf$ + rs$(i) ' concatenate the next line
        if right$(temp,1) = chr$(34) then
          temp = left$(temp,len(temp)-1) ' sttip off the trailing quote
        else
          print "Error reading room data!"
          print temp
          end
        endif
      endif
    rs$(i) = temp
    endif
  Next i

  ' Read messages and trim off any leading and trailing quotes
  ' some messages are spanning multiple lines so need to concatenate them
  flag = 0
  For i = 0 TO ml : Line Input #1, ms$(i)
    if left$(ms$(i),1) = chr$(34) then ms$(i) = right$(ms$(i),len(ms$(i))-1)
    if right$(ms$(i),1) = chr$(34) then
      ms$(i) = left$(ms$(i),len(ms$(i))-1)
    else
      temp = ms$(i)
      line input #1, ms$(i)
      if temp = "" then ' some lines just contain a quote
        temp = temp + crlf$ + ms$(i)
      else
        temp = temp + ms$(i)
      endif
      if right$(temp,1) = chr$(34) then
        temp = left$(temp,len(temp)-1)
      else
        line input #1, ms$(i)
        temp = temp + crlf$ + ms$(i)
        if right$(temp,1) = chr$(34) then
          temp = left$(temp,len(temp)-1)
          else
          j = 0
          DO
            line input #1, ms$(i)
            temp = temp + crlf$ + ms$(i)
            if right$(temp,1) = chr$(34) then
              temp = left$(temp,len(temp)-1)
              flag = 1
            ELSE
              j = j + 1
            endif
          loop until flag = 1 or j = 6
          if j = 6 then print " Error reading messages" : end
        endif
      endif
      ms$(i) = temp
    endif
  Next i

' Read objects, remove quotes and separate the location
For i = 0 TO il : line Input #1, ia_str$(i)
  temp = ia_str$(i)
  flag = 0
  for j = len(temp) to 2 step -1
    if mid$(temp,j,1) = chr$(34) then
      flag = 1
      exit for
    endif
  next j
  if flag = 0 then ' no quote
    line Input #1, ia_str$(i)
    temp = temp + " " + ia_str$(i)
  endif

  for j= len(temp)-1 to 1 step -1
    temp3 = mid$(temp,j,1)
  if temp3 = " " then
    temp1 = left$(temp, j-1)
    temp2 = right$(temp, len(temp) - j)
    exit for
  end if
  next j
  if left$(temp1,1) = chr$(34) then temp1 = right$(temp1,len(temp1)-1):
  if right$(temp1,1) = chr$(34) then temp1 = left$(temp1,len(temp1)-1):
  if temp1 = " " then temp1 = ""
  ia_str$(i) = temp1
  ia(i) = val(temp2)
  if ia(i) = 255 then ia(i) = -1 ' Some files use 255 as -1 - Bill
  i2(i)=ia(i)
Next i
Close #1
End Sub
