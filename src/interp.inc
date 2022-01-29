' Copyright (c) 2020-2022 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.07

' This file implements the actual interpreter loop.

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("advent", "bits", "console", "debug", "map", "math", "script", "state", "string")
sys.provides("interp")
If sys.err$ <> "" Then Error sys.err$

Const STATE_OK      = 0
Const STATE_QUIT    = 1
Const STATE_RESTART = 2

Const ACTION_PERFORMED = 3
Const ACTION_UNKNOWN   = 4
Const ACTION_NOT_YET   = 5

' Hardcoded Object Id's.
Const OBJ_LIT_LAMP% = 9 ' The artificial light source.

' Hardcoded Room Id's.
Const ROOM_CARRIED% = 255 ' Not -1 as used in original BYTE magazine version of "Pirate Adventure".
Const ROOM_STORE% = 0

' Hardcoded Verb Id's.
Const VERB_GET%           = 10
Const VERB_DROP%          = 18
Const VERB_NONE%          = -1
Const VERB_TOO_MANY%      = -2
Const VERB_DEBUG%         = -3
Const VERB_DUMP_ACTIONS%  = -4
Const VERB_DUMP_MESSAGES% = -5
Const VERB_DUMP_OBJECTS%  = -6
Const VERB_DUMP_ROOMS%    = -7
Const VERB_DUMP_STATE%    = -8
Const VERB_DUMP_VOCAB%    = -9
Const VERB_LOOK%          = -10
Const VERB_MORE%          = -11
Const VERB_RECORD%        = -12
Const VERB_REPLAY%        = -13
Const VERB_SEED%          = -14
Const VERB_WALKTHROUGH%   = -15

' Format used for printing lists of objects.
Const OBJ_LIST_FMT_COMMA%   = 1  ' Comma separated.
Const OBJ_LIST_FMT_NEWLINE% = 2  ' Each object on a newline.

Const MSG_OK$ = "OK."

Dim DIRECTIONS$(5) Length 10 = ("North", "South", "East", "West", "Up", "Down")

' Game options persisted to .ini file.
Dim options$(map.new%(10))
map.init(options$())

Dim state
Dim continue_flag = 0 ' Flag that, when set will cause the next action(s) to be
                      ' processed if they begin with both a verb and noun = 0.

' TODO: This shouldn't be global
Dim ip ' action parameter pointer

Dim interp.room_state%(9) ' Encodes the state of the last described room:
                          '   bit       0  - was it light (0) or dark (1)
                          '   bits  8..23  - room number (though probably only bits 8..15)
                          '   bits 24..63  - unused
                          '   bits 64..639 - was object i + 64 in the room
                          ' We use this to determine if we need to describe the current room.

Dim interp.obj_list_fmt% = OBJ_LIST_FMT_NEWLINE%

Dim message_flag%   ' If set then we are constructing a message that might be appended to
                    ' by another message without a CRLF.
Dim describe_flag%  ' If set then when message_string() is called
                    ' first describe the room before displaying the message.

Sub game_loop()
  Local i%, noun, nstr$, verb

  state = STATE_OK

  ' Clear the room_state to ensure first call to describe_room() describes the room.
  For i% = Bound(interp.room_state%(), 0) To Bound(interp.room_state%(), 1)
    interp.room_state%(i%) = 0
  Next

  debug.print_flags% = debug.TWO_LINES% Or debug.NO_STARS%
  message_flag% = 0

  Do
    do_automatic_actions()
    describe_room(describe_flag%)
    If state = STATE_OK Then prompt_for_command(verb, noun, nstr$)
    If state = STATE_OK Then do_player_actions(verb, noun, nstr$)
    If state = STATE_OK Then interp.update_lamp()
  Loop While state = STATE_OK

  ' Discard anything left in the console buffer.
  con.buf$ = ""
End Sub

' Describe the current room if it has changed.
'
' @param  always%  if not 0 then describe the room even if it has not changed.
Sub describe_room(always%)
  ' Even if always% = 1 we call interp.has_changed%() to update interp.room_state%().
  If Not interp.has_changed%() And Not always% Then Exit Sub

  describe_flag% = 0

  If is_dark%() Then
    ' Desperate hack! to avoid duplicate messages in SACA #8 "Pyramid of Doom"
    If con.buf$ <> "dark!" Then
      If debug.enabled% Then con.print("[" + Str$(r) + "] ")
      message_string("I can't see, it's too dark!")
    EndIf
    Exit Sub
  EndIf

  flush_messages()

  ' Ensure at least one empty line before room description.
  If con.count <= 1 Then con.println()

  con.foreground("white")

  If debug.enabled% Then con.print("[" + Str$(r) + "] ")
  If Left$(rs$(r), 1) = "*" Then
    ' A leading asterisk means use the room description verbatim.
    con.println(Mid$(rs$(r), 2))
  Else
    con.println("I'm in a " + rs$(r))
  EndIf

  con.print("Obvious exits: ")
  Local count, i
  For i = 0 To 5
    If rm(r, i) <> 0 Then
      Inc count
      If count > 1 Then con.print(", ")
      con.print(DIRECTIONS$(i))
      If debug.enabled% Then con.print(" [" + Str$(rm(r, i)) + "]")
    EndIf
  Next
  If count = 0 Then con.print("None")
  con.println(".")

  con.print("Visible items: ")
  print_object_list(r, "None")
  con.println()

  con.println("<" + String$(con.WIDTH - 2, "-") + ">")
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

  Local was_dark% = interp.room_state%(0) And &h1

  ' First 64-bits of room_state%() encodes whether it is dark and the current room.
  Local x% = is_dark%() + (r << 8)
  Local idx% = 0
  If x% <> interp.room_state%(idx%) Then interp.has_changed% = 1
  interp.room_state%(idx%) = x%
  Inc idx%

  ' Remaining 576-bits of room_state%() encodes objects in current room.
  Local bit%, obj%
  x% = 0
  For obj% = 0 To il
    Inc x%, (state.obj_rm%(obj%) = r) << bit%
    Inc bit%
    If bit% = 64 Or obj% = il Then
      If x% <> interp.room_state%(idx%) Then interp.has_changed% = 1
      interp.room_state%(idx%) = x%
      bit% = 0
      x% = 0
      Inc idx%
    EndIf
  Next

  ' If the room was dark and is still dark then return 0/false.
  If was_dark% And (interp.room_state%(0) And &h1) Then interp.has_changed% = 0
End Function

' Is the current room dark ?
Function is_dark%()
  If Not bits.get%(sf, state.DARK_BIT%) Then Exit Function
  If state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_CARRIED% Then Exit Function
  If state.obj_rm%(OBJ_LIT_LAMP%) = r Then Exit Function
  is_dark% = 1
End Function

' Prints a list of objects, the list does not end with CRLF.
Sub print_object_list(rm, none$)
  Local count, i, p

  For i = 0 To il
    If state.obj_rm%(i) = rm Then
      Inc count
      Select Case interp.obj_list_fmt%
        Case OBJ_LIST_FMT_COMMA%
          If count > 1 Then con.print(", ")
        Case OBJ_LIST_FMT_NEWLINE%
          con.println()
          con.print("  ")
        Case Else : Error
      End Select
      If debug.enabled% Then con.print("[" + Str$(i) + "] ")
      p = InStr(ia_str$(i), "/")
      If p < 1 Then
        con.print(ia_str$(i))
      Else
        con.print(Left$(ia_str$(i), p - 1))
      EndIf
    EndIf
  Next

  If count = 0 Then
    con.print(none$ + ".")
  ElseIf interp.obj_list_fmt% = OBJ_LIST_FMT_COMMA% Then
    con.print(".")
  EndIf
End Sub

Sub do_automatic_actions()
  Local a, av, an, process_action

  continue_flag = 0

  For a = 0 To cl
    ' The 'verb' of an automatic action is zero,
    ' If we reach a non-zero verb then we stop processing automatic actions.
    av = Int(ca(a, 0) / 150)
    If av <> 0 Then Exit Sub

    ' The 'noun' of the automatic action.
    ' If this is non-zero then we clear the CONTinue flag.
    an = ca(a, 0) - av * 150
    If an <> 0 Then continue_flag = 0

    ' If the CONTinue flag is not set then 'noun' is the probability of the
    ' action occurring.
    If Not continue_flag Then
      If math.pseudo_rnd%(100) > an Then Continue For ' Did not occur, try the next action.
    EndIf

    If Not process_conditions(a) Then Continue For ' Conditions not passed, try the next action.

    do_commands(a)
  Next

End Sub

Sub do_player_actions(verb, noun, nstr$)

  continue_flag = 0

  ' Handle "go <direction>"
  If verb = 1 And noun < 7 Then
    go_direction(noun)
    Exit Sub
  EndIf

  Local a, an, av, result = ACTION_UNKNOWN

  ' We record this so we can determine whether a user action caused any
  ' messages to be output, if it didn't then we will automatically output OK.
  Local num_lines = con.lines

  For a = 0 To cl
    av = Int(ca(a, 0) / 150) ' action - verb
    an = ca(a, 0) - av * 150 ' action - noun

    If continue_flag Then
      ' If the CONTinue flag is set but the verb or noun is non-zero then the
      ' player action is complete.
      If (av <> 0) Or (an <> 0) Then Exit For

    ElseIf av <> verb Then
      ' Verb doesn't match, try the next action.
      Continue For

    ElseIf (an <> 0) And (an <> noun) Then
      ' Noun doesn't match (or isn't 'ANY'), try the next action.
      Continue For

    EndIf

    If result = ACTION_UNKNOWN Then result = ACTION_NOT_YET
    If Not process_conditions(a) Then Continue For ' Conditions not passed, try the next action.

    do_commands(a, nstr$)
    result = ACTION_PERFORMED

    ' Stop processing player actions when an action is performed and the CONTinue
    ' flag is not set.
    If Not continue_flag Then Exit For
  Next

  ' Whilst the action table contains some specialist pickup and drop handling
  ' the general case is handled by this code.
  If result = ACTION_UNKNOWN Then
    Select Case verb
      Case VERB_GET%  : do_get(noun, nstr$)  : result = ACTION_PERFORMED
      Case VERB_DROP% : do_drop(noun, nstr$) : result = ACTION_PERFORMED
    End Select
  EndIf

  Select Case result
    Case ACTION_UNKNOWN : message_string("I don't understand your command.")
    Case ACTION_NOT_YET : message_string("I can't do that yet.")
    Case Else           : If Not message_flag% Then message_string(MSG_OK$)
  End Select

End Sub

' @param  a  current action index
Function process_conditions(a)
  Local code, i, ok, value

  ok = 1
  For i = 1 To 5
    value = Int(ca(a, i) / 20)
    code = ca(a, i) - value * 20
    ok = ok And evaluate_condition(code, value)
    If Not ok Then Exit For
  Next

  process_conditions = ok
End Function

' @param  a  current action index
Sub do_commands(a, nstr$)
  Local cmd(3)

  ip = 0 ' reset parameter pointer
  cmd(0) = Int(ca(a, 6) / 150)
  cmd(1) = ca(a, 6) - cmd(0) * 150
  cmd(2) = Int(ca(a, 7) / 150)
  cmd(3) = ca(a, 7) - cmd(2) * 150

  do_command(a, cmd(0), nstr$)
  do_command(a, cmd(1), nstr$)
  do_command(a, cmd(2), nstr$)
  do_command(a, cmd(3), nstr$)
End Sub

Sub go_direction(noun)
  Local dark% = is_dark%()
  If dark% Then message_string("Dangerous to move in the dark!")
  If noun < 1 Then message_string("Give me a direction too.") : Exit Sub
  Local k = rm(r, noun - 1)
  If k < 1 Then
    If dark% Then
      message_string("I fell down and broke my neck.")
      k = rl
      bits.clear(sf, state.DARK_BIT%)
    Else
      message_string("I can't go in that direction.")
      Exit Sub
    EndIf
  EndIf
  r = k
  message_string(MSG_OK$)
  describe_flag% = 1
End Sub

Function evaluate_condition(code, value)
  Local i, pass
  Select Case code
    Case 0
      pass = 1
    Case 1
      ' Passes if the player is carrying object <value>.
      pass = (state.obj_rm%(value) = ROOM_CARRIED%)
    Case 2
      ' Passes if the player is in the same room (but not carrying) object <value>.
      pass = (state.obj_rm%(value) = r)
    Case 3
      ' Passes if object <value> is available; i.e. carried or in the current room
      pass = (state.obj_rm%(value) = ROOM_CARRIED%) Or (state.obj_rm%(value) = r)
    Case 4
      ' Passes if the player is in room <value>.
      pass = (r = value)
    Case 5
      ' Passes if the player is carrying object <value> or it is in a different room.
      pass = (state.obj_rm%(value) <> r)
    Case 6
      ' Passes if the player is not carrying object <value>.
      pass = (state.obj_rm%(value) <> ROOM_CARRIED%)
    Case 7
      ' Passes if the player is not in room <value>.
      pass = (r <> value)
    Case 8
      ' Passes if numbered flag-bit set.
      pass = bits.get%(sf, value)
    Case 9
      ' Passes if numbered flag-bit clear.
      pass = Not bits.get%(sf, value)
    Case 10
      ' Passes if the player is carrying anything.
      pass = count_carried%() > 0
    Case 11
      ' Passes if the player is carrying nothing.
      pass = count_carried%() = 0
    Case 12
      ' Passes if object <value> is not available; i.e. not carried or in the current room.
      pass = (state.obj_rm%(value) <> ROOM_CARRIED%) And (state.obj_rm%(value) <> r)
    Case 13
      ' Passes if object <value> is not in the store room (0)
      pass = (state.obj_rm%(value) <> ROOM_STORE%)
    Case 14
      ' Passes if object <value> is in the store room (0)
      pass = (state.obj_rm%(value) = ROOM_STORE%)
    Case 15
      ' Passes if counter <= the value.
      pass = (counter <= value)
    Case 16
      ' Passes if counter > the value.
      pass = (counter > value)
    Case 17
      ' Passes if the numbered object is is the room it started in.
      pass = (state.obj_rm%(value) = advent.obj_rm%(value))
    Case 18
      ' Passes if the numbered object is not in the room it started in.
      pass = (state.obj_rm%(value) <> advent.obj_rm%(value))
    Case 19
      ' Passes if the counter is equal to the value.
      pass = (counter = value)
    Case Else
      Error "Unknown condition: " + Str$(code)
  End Select

  evaluate_condition = pass
End Function

Function count_carried%()
  Local i%
  For i% = 0 To il
    If state.obj_rm%(i) = ROOM_CARRIED% Then Inc count_carried%
  Next
End Function

' @param  a  current action index
Sub do_command(a, cmd, nstr$)
  Local i, p, x, y

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
      p = get_parameter(a)
      If count_carried%() >= mx Then
        message_string("I've too much to carry. Try 'Inventory'.")
      Else
        state.obj_rm%(p) = ROOM_CARRIED%
      EndIf

    Case 53
      ' DROPx
      ' Drop the Par #1 object in the current room.
      ' The object may be carried or in any other room
      p = get_parameter(a)
      state.obj_rm%(p) = r

    Case 54
      ' GOTOy
      ' Move the player to the Par #1 room.
      ' This command should be followed by a DspRM (64) command.
      ' Also it may need to be followed by a NIGHT (56) or DAY (57) command.
      p = get_parameter(a)
      r = p

    Case 55, 59
      ' x->RM0
      ' Move the Par #1 object to room 0 (the storeroom).
      p = get_parameter(a)
      state.obj_rm%(p) = 0

    Case 56
      ' NIGHT
      ' Set the darkness flag-bit (15).
      ' It will be dark if the artificial light source is not available,
      ' so this should be followed by a DspRM (64) command.
      bits.set(sf, state.DARK_BIT%)

    Case 57
      ' DAY
      ' Clear the darkness flag-bit (15).
      ' This should be followed by a DspRM (64) command.
      bits.clear(sf, state.DARK_BIT%)

    Case 58
      ' SETz
      ' Set the Par #1 flag-bit.
      p = get_parameter(a)
      bits.set(sf, p)

  ' Case 59
      ' x->RM
      ' This command also moves the Par #1 object to room 0 (the storeroom), like command 55.

    Case 60
      ' CLRz
      ' Clear the Par #1 flag-bit.
      p = get_parameter(a)
      bits.clear(sf, p)

    Case 61
      ' DEAD
      ' Tell the player they are dead,
      ' Goto the last room (usually some form of limbo),
      ' make it DAY and display the room.
      message_string("I'm dead...")
      bits.clear(sf, state.DARK_BIT%)
      r = rl
      describe_flag% = 1

    Case 62
      ' x->y
      ' Move the Par #1 object to the Par #2 room.
      ' This will automatically display the room if the object came from,
      ' or went to the current room.
      x = get_parameter(a)
      y = get_parameter(a)
      state.obj_rm%(x) = y

    Case 63
      ' FINI
      ' Tell the player the game is over and ask if they want to play again.
      flush_messages()
      If con.fd_out > 0 Then script.record_off()
      If con.fd_in > 0 Then script.replay_off()
      Local s$ = prompt$("The game is now over, would you like to play again [Y|n]? ")
      If LCase$(s$) = "n" Then state = STATE_QUIT Else state = STATE_RESTART

    Case 64, 76
      ' DspRM
      ' Display the current room.
      ' This checks if the darkness flag-bit (15) is set and the artificial
      ' light (object 9) is not available.
      ' If there is light, it displays the room description, the objects in
      ' the room and any obvious exits.
      describe_flag% = 1

    Case 65
      ' SCORE
      ' Tells the player how many treasures they have collected by getting
      ' them to the treasure room and what their percentage of the total is.
      x = 0
      For i = 1 To il
        If state.obj_rm%(i) = tr And Left$(ia_str$(i), 1) = "*" Then Inc x
      Next
      message_string("I've stored " + Str$(x) + " of " + Str$(tt) + " treasures.")
      If tt > 0 Then
        message_string("On a scale of 0 to 100 that rates a " + Str$(Int(x / tt * 100)) + ".")
        If x = tt Then
          message_string("WELL DONE !!!")
          do_command(a, 63, nstr$)
        EndIf
      EndIf

    Case 66
      ' INV
      ' Tells the player what objects they are carrying.
      message_string("I'm carrying: ")
      print_object_list(ROOM_CARRIED%, "Nothing")

    Case 67
      ' SET0
      ' Sets the flag-bit numbered 0 (this may be convenient because no parameter is used).
      bits.set(sf, 0)

    Case 68
      ' CLR0
      ' Clears the flag-bit numbered 0 (this may be convenient because no parameter is used).
      bits.clear(sf, 0)

    Case 69
      ' FILL
      ' Re-fill the artifical light source and clear flag-bit 16 which
      ' indicates that it was empty. This also picks up the artifical light
      ' source (object 9). This command should be followed by a x->RM0 to store
      ' the unlighted light source (these are two different objects).
      lx = lt
      state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_CARRIED%
      bits.clear(sf, state.LAMP_OUT_BIT%)

    Case 70
      ' CLS
      ' As far as I can tell a CLS is always followed by a DspRM thus making it superfluous.

    Case 71
      ' SAVEz
      ' This command saves the current game state to a file.
      x = state.save%()
      If Not x Then message_string("Cancelled.")

    Case 72
      ' EXx,x
      ' This command exchanges the room locations of the Par #1 object and the
      ' Par #2 object. If the objects in the current room change, the new
      ' description will be displayed.
      x = get_parameter(a)  ' x = object 1
      y = get_parameter(a)  ' y = object 2
      p = state.obj_rm%(x)  ' p = location of object 1
      state.obj_rm%(x) = state.obj_rm%(y)
      state.obj_rm%(y) = p

    Case 73
      ' CONT
      ' This command sets a flag to allow more than four commands to be executed. When all the
      ' commands in this action entry have been performed, the commands in the next action entry
      ' will also be executed if the verb and noun are both zero. The condition fields of the new
      ' action entry will contain the parameters for the commands in the new action entry. When an
      ' action entry with a non-zero verb or noun is encountered, the continue flag is cleared.
      continue_flag = 1

    Case 74
      ' AGETx
      ' Always pick up the Par #1 object, even if that would cause the carry limit to be exceeded.
      ' Otherwise, this is like command 52, GETx.
      p = get_parameter(a)
      state.obj_rm%(p) = ROOM_CARRIED%

    Case 75
      ' BYx<-x
      ' Put the Par #1 object in the same place as the Par #2 object. If the Par #2 object is being
      ' carried, this will pick up the Par #1 object too, regardless of the carry limit.
      ' If this changes the objects in the current room, the room will be displayed again.
      x = get_parameter(a) ' x = object 1
      y = get_parameter(a) ' y = object 2
      state.obj_rm%(x) = state.obj_rm%(y)

  '  Case 76
      ' DspRM
      ' This displays the current room, just like command 64.

    Case 77
      ' CT-1
      ' This subtracts 1 from the counter value.
      Inc counter, -1

    Case 78
      ' DspCT
      ' This displays the current value of the counter.
      message_string(Str$(counter))

    Case 79
      ' CT<-n
      ' This sets the counter to the Par #1 value.
      p = get_parameter(a)
      counter = p

    Case 80
      ' EXRM0
      ' This exchanges the values of the current room register with the alternate room register 0.
      ' This may be used to save the room a player came from in order to put him back there later.
      ' This should be followed by a GOTOy command if the alternate room register 0 had not already
      ' been set.
      x = r
      r = alt_room(0)
      alt_room(0) = x

    Case 81
      ' EXm,CT
      ' This command exchanges the values of the counter and the Par #1 alternate counter. There
      ' are eight alternate counters numbered from 0 to 7. Also, the time limit may be accessed as
      ' alternate counter 8.
      p = get_parameter(a)
      x = counter
      Select Case p
        Case 0 To 7
          counter = alt_counter(p)
          alt_counter(p) = x
        Case 8  ' lamp duration.
          counter = lx
          lx = x
        Case Else
          Error "illegal counter: " + Str$(p)
      End Select

    Case 82
      ' CT+n
      ' This adds the Par #1 value to the counter.
      p = get_parameter(a)
      Inc counter, p

    Case 83
      ' CT-n
      ' This subtracts the Par #1 value from the counter.
      p = get_parameter(a)
      Inc counter, -p

    Case 84
      ' SAYw
      ' This says the noun (second word) input by the player.
      message_string("'" + nstr$ + "'")

    Case 85
      ' SAYwCR
      ' This says the noun (second word) input by the player and starts a new line.
      message_string("'" + nstr$ + "'" + sys.CRLF$)

    Case 86
      ' SAYCR
      ' This just starts a new line on the display.
      message_string(sys.CRLF$)

    Case 87
      ' EXc,CR
      ' This exchanges the values of the current room register with the Par #1 alternate room
      ' register. This may be used to remember more than one room. There are six alternate room
      ' registers numbered from 0 to 5.
      p = get_parameter(a)
      x = r
      r = alt_room(p)
      alt_room(p) = x

    Case 88
      ' DELAY
      ' This command delays about 1 second before going on to the next command.
      Pause 1000

    Case 102 To 149
      ' Display messages 52-99.
      message_id(cmd - 50)

    Case Else
      Error "Unknown command: " + Str$(cmd)

  End Select

End Sub

' @param   a   current action index
' @global  ip  parameter pointer
Function get_parameter(a)
  Local code, value

  Do
    Inc ip
    value = Int(ca(a, ip) / 20)
    code = ca(a, ip) - value * 20
  Loop While code <> 0

  get_parameter = value
End Function

Sub prompt_for_command(verb, noun, nstr$)
  Local s$

  Do
    flush_messages()

    ' Ensure at least one empty line before prompt.
    If con.count <= 1 Then con.println()

    s$ = prompt$("What shall I do ? ", 1)
    parse(s$, verb, noun, nstr$)

    Select Case verb
      Case 0                   : message_string("You use word(s) I don't know!")
      Case VERB_NONE%          : ' Do nothing, user will be prompted for command again.
      Case VERB_TOO_MANY%      : message_string("I only understand two word commands!")
      Case VERB_DEBUG%         : message_string(MSG_OK$) : debug.enabled% = (nstr$ = "on")
      Case VERB_DUMP_ACTIONS%  : debug.dump_actions(nstr$)
      Case VERB_DUMP_MESSAGES% : debug.dump_messages(nstr$)
      Case VERB_DUMP_OBJECTS%  : debug.dump_objects(nstr$)
      Case VERB_DUMP_ROOMS%    : debug.dump_rooms(nstr$)
      Case VERB_DUMP_STATE%    : debug.dump_state()
      Case VERB_DUMP_VOCAB%    : debug.dump_vocabulary()
      Case VERB_LOOK%          : describe_room(1)
      Case VERB_MORE%          : message_string(MSG_OK$) : con.more = (nstr$ = "on")
      Case VERB_RECORD%
        flush_messages()
        If nstr$ = "on" Then
          seed_random_number_generator("record")
          script.record_on()
        Else
          script.record_off()
        EndIf
      Case VERB_REPLAY%
        flush_messages()
        If nstr$ = "on" Then
          seed_random_number_generator("record")
          script.replay_on()
        Else
          script.replay_off()
        EndIf
      Case VERB_SEED%          : seed_random_number_generator(nstr$)
      Case VERB_WALKTHROUGH%   : seed_random_number_generator("record") : script.walkthrough()
      Case Else                : Exit Do ' Handle 'verb' in calling code.
    End Select

  Loop

End Sub

Sub message_id(id%)
  Local msg$ = ms$(id%)
  If msg$ = "OK" Then msg$ = MSG_OK$
  If debug.enabled% Then
    message_string("[" + Str$(id%) + "] " + msg$)
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
  If msg$ = "" Then Error "Unexpected empty message"

  Local msg_first% = is_dark%() Or (msg$ = MSG_OK$)
  If msg_first% Then message_internal(msg$)
  If describe_flag% And Not (msg$ = MSG_OK$) Then describe_room(1)
  If Not msg_first% Then message_internal(msg$)
End Sub

Sub message_internal(msg$)
  ' Handle appending this message to a previous one.
  If message_flag% Then
    If Left$(msg$, 2) = sys.CRLF$ Then
      ' If new message starts CRLF then do nothing, it will be appended verbatim.
    Else
      Select Case Asc(Left$(msg$, 1))
        Case Asc("'"), Asc("`")    ' New message starts with single quote.
          con.print(" ")
        Case Asc("a") To Asc("z")  ' New message starts lower-case.
          con.print(" ")
        Case Asc ("0") To Asc("9") ' New message starts number.
          con.print(" ")
        Case Else
          con.println()
      End Select
    EndIf
  EndIf

  con.print(msg$)
  message_flag% = 1
End Sub

Sub flush_messages()
  If message_flag% Then
    con.println()
    message_flag% = 0
  EndIf
End Sub

Function prompt$(s$, echo)
  message_string(s$)
  message_flag% = 0

  con.foreground("white")
  prompt$ = con.in$("", echo)
  con.foreground("green")
End Function

Sub parse(s$, verb, noun, nstr$)
  Local vstr$

  vstr$ = LCase$(str.next_token$(s$, " ", 1))
  vstr$ = Choice(vstr$ = sys.NO_DATA$, "", vstr$)
  nstr$ = LCase$(str.next_token$())
  nstr$ = Choice(nstr$ = sys.NO_DATA$, "", nstr$)

  ' Handle empty input.
  If vstr$ = "" Then verb = VERB_NONE : Exit Sub

  ' Ignore input beginning with '#', used for comments in script files.
  If Left$(vstr$, 1) = "#" Then verb = VERB_NONE : Exit Sub

  ' Reject commands of more than two words.
  If str.next_token$() <> sys.NO_DATA$ Then verb = VERB_TOO_MANY : Exit Sub

  verb = lookup_meta_command(vstr$, nstr$)
  If verb <> 0 Then Exit Sub

  ' Hack to allow use of common abbreviations, and avoid typing 'go'.
  If nstr$ = "" Then
    Select Case vstr$
      Case "n", "nor", "nort", "north" : vstr$ = "go" : nstr$ = "north"
      Case "s", "sou", "sout", "south" : vstr$ = "go" : nstr$ = "south"
      Case "e", "eas", "east"          : vstr$ = "go" : nstr$ = "east"
      Case "w", "wes", "west"          : vstr$ = "go" : nstr$ = "west"
      Case "u", "up"                   : vstr$ = "go" : nstr$ = "up"
      Case "d", "dow", "down"          : vstr$ = "go" : nstr$ = "down"
      Case "i", "inv"                  : vstr$ = "inventory"
      Case "q"                         : vstr$ = "quit"
      Case "save"                      : vstr$ = "save" : nstr$ = "game"
    End Select
  EndIf

  If Left$(vstr$, ln) = Left$("quit", ln) Then
    Local pr$ = prompt$("Are you sure you want to quit [y|N]? ")
    If LCase$(pr$) <> "y" Then verb = VERB_NONE : Exit Sub
  EndIf

  verb = lookup_word(Left$(vstr$, ln), 0)
  noun = lookup_word(Left$(nstr$, ln), 1)

  ' If TAKE is not in the vocabulary then treat it as a synonym for GET.
  If verb = 0 Then
    If Left$(vstr$, ln) = Left$("take", ln) Then verb = VERB_GET%
  EndIf
End Sub

Function lookup_meta_command(vstr$, nstr$)
  Const TYPE_BOOLEAN% = 1, TYPE_OTHER% = 2
  Local verb%, type%

  Select Case Left$(vstr$, 4)
    Case "*act" : verb% = VERB_DUMP_ACTIONS%  : type% = TYPE_OTHER%
    Case "*deb" : verb% = VERB_DEBUG%         : type% = TYPE_BOOLEAN%
    Case "*loo" : verb% = VERB_LOOK%
    Case "*mes" : verb% = VERB_DUMP_MESSAGES% : type% = TYPE_OTHER%
    Case "*mor" : verb% = VERB_MORE%          : type% = TYPE_BOOLEAN%
    Case "*msg" : verb% = VERB_DUMP_MESSAGES% : type% = TYPE_OTHER%
    Case "*obj" : verb% = VERB_DUMP_OBJECTS%  : type% = TYPE_OTHER%
    Case "*rec" : verb% = VERB_RECORD%        : type% = TYPE_BOOLEAN%
    Case "*rep" : verb% = VERB_REPLAY%        : type% = TYPE_BOOLEAN%
    Case "*roo" : verb% = VERB_DUMP_ROOMS%    : type% = TYPE_OTHER%
    Case "*see" : verb% = VERB_SEED%          : type% = TYPE_OTHER%
    Case "*sta" : verb% = VERB_DUMP_STATE%
    Case "*voc" : verb% = VERB_DUMP_VOCAB%
    Case "*wal" : verb% = VERB_WALKTHROUGH%
  End Select

  If verb% = 0 Then Exit Function

  Select Case type%
    Case 0
      If nstr$ <> "" Then Exit Function ' Unexpected noun.
    Case TYPE_BOOLEAN%
      If nstr$ = "" Then nstr$ = "on"
      If nstr$ <> "on" And nstr$ <> "off" Then Exit Function ' Invalid noun.
  End Select

  lookup_meta_command = verb%
End Function

' @param  word$  word to lookup
' @param  dict   dictionary to look in, 0 for verbs and 1 for nouns
Function lookup_word(word$, dict)
  Local i, s$

  lookup_word = 0

  If word$ = "" Then Exit Function

  For i = 0 To nl
    s$ = nv_str$(i, dict)
    If Left$(s$, 1) = "*" Then s$ = Mid$(s$, 2)
    s$ = Left$(s$, ln) ' Trim to the vocabulary word length which the
                       ' adventure files don't always respect.
    If word$ = LCase$(s$) Then
      ' Word found, if it's a synonym then use previous word.
      lookup_word = i
      Do While Left$(nv_str$(lookup_word, dict), 1) = "*"
        Inc lookup_word, -1
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
  Local seed% = 0
  If s$ = "option" Then
    seed% = Val(map.get$(options$(), "seed"))
    If seed% = 0 Then seed% = Timer
  ElseIf s$ = "record" Then
    seed% = 7
  ElseIf s$ = Str$(Int(Val(s$)))) Then
    seed% = Val(s$)
  EndIf

  If seed% > 0 Then
    Local _ = math.pseudo_rnd%(-seed%)
    If s$ = Str$(seed%) Then message_string(MSG_OK$)
  Else
    message_string("Invalid seed, should be integer > 0.")
  EndIf
End Sub

' Picks up the object identified by 'nstr$'
Sub do_get(noun, nstr$)
  Local i, k, obj$ = obj_name$(noun, nstr$)

  If nstr$ = "" Then message_string("What?") : Exit Sub

  If count_carried%() >= mx Then
    message_string("I've too much to carry!")
    Exit Sub
  EndIf

  For i = 0 To il
    If obj_noun$(i) = obj$ Then
      If state.obj_rm%(i) = r Then
        state.obj_rm%(i) = ROOM_CARRIED%
        k = 3
        Exit For
      Else
        k = 2
      EndIf
    EndIf
  Next

  Select Case k
    Case 0 : message_string("It's beyond my power to do that.")
    Case 2 : message_string("I don't see it here.")
    Case 3 : message_string(MSG_OK$)
    Case Else : Error "Unknown GET state, k = " + Str$(k)
  End Select

End Sub

' Gets an object name corresponding to a 'noun' and/or 'nstr$' supplied by the player.
Function obj_name$(noun, nstr$)
  obj_name$ = Choice(noun = 0, nstr$, nv_str$(noun, 1)) ' Use correct synonym.
  obj_name$ = Left$(obj_name$, ln)                      ' Trim to vocabulary word length.
  obj_name$ = LCase$(obj_name$)                         ' Lower-case.
End Function

' Gets the (lower-case) noun for referring to the given object.
Function obj_noun$(i)
  Local en, st

  st = InStr(ia_str$(i), "/")
  If st > 1 Then
    en = InStr(st + 1, ia_str$(i), "/")
    If en < st + 1 Then Error "Missing trailing '/'"
    obj_noun$ = LCase$(Mid$(ia_str$(i), st + 1, en - st - 1))
  EndIf

  If Len(obj_noun$) > ln Then Error "Object noun too long: " + obj_noun$
End Function

' Drops the object identified by 'noun' and/or 'nstr$'
Sub do_drop(noun, nstr$)
  Local i, k = 0, obj$ = obj_name$(noun, nstr$)

  For i = 0 To il
    If obj_noun$(i) = obj$ Then
      If state.obj_rm%(i) = ROOM_CARRIED% Then
        state.obj_rm%(i) = r
        k = 3
        Exit For
      Else
        k = 1
      EndIf
    EndIf
  Next

  Select Case k
    Case 0 : message_string("It's beyond my power to do that.")
    Case 1 : message_string("I'm not carrying it!")
    Case 3 : message_string(MSG_OK$)
    Case Else : Error "Unknown DROP state, k = " + Str$(k)
  End Select

End Sub

Sub interp.update_lamp()
  ' Don't update the lamp duration if it is in the store.
  If state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_STORE% Then Exit Sub

  ' Don't update the lamp duration if <= -1;
  ' the value of -1 is used by Brian Howarth's games to indicate infinite duration.
  If lx <= -1 Then Exit Sub

  ' Decrement the duration but don't go below 0.
  If lx > 0 Then Inc lx, -1

  If lx >= 25 Then Exit Sub

  ' Only display messages about the lamp if the player is carrying or in the same room as it.
  Local lamp_room% = state.obj_rm%(OBJ_LIT_LAMP%)
  If lamp_room% = ROOM_CARRIED% Or lamp_room% = r Then
    If lx = 0 Then
      message_string("Light has run out!")
    Else
      message_string("Light runs out in " + Str$(lx) + " turns!")
    EndIf
  EndIf

  If lx = 0 Then
    bits.set(sf, state.LAMP_OUT_BIT%)

    ' Apparently only older adventures automatically return the lamp to the store.
    If map.get$(options$(), "prehistoric_lamp") = "1" Then
      state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_STORE%
    EndIf
  EndIf
End Sub
