' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/bits.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"
#Include "../splib/map.inc"
#Include "../splib/math.inc"
#Include "../splib/set.inc"
#Include "../splib/vt100.inc"
#Include "/sptools/src/sptest/unittest.inc"
'#Include "../advent.inc"

' Stub dependencies on "advent.inc" ----------------------------------------------------------------
sys.provides("advent")
Dim cl = 100, il = 100, lt, rl = 10, tr, tt
Dim ca(cl, 7)
Dim ia_str$(il) Length 64
Dim rm(rl, 5)

' Stub dependencies on "console.inc" ---------------------------------------------------------------
sys.provides("console")

Dim con.buf$, con.fd_in, con.fd_out, con.in_buf$

Sub con.foreground(s$)
End Sub

Function con.in$(p$, echo%)
  con.in$ = con.in_buf$
End Function

Sub con.print(s$)
  Cat con.buf$, s$
End Sub

Sub con.println(s$)
  con.print(s$ + sys.CRLF$)
End Sub

' Stub dependencies on "script.inc" ----------------------------------------------------------------
sys.provides("script")

Dim script.buf$

Sub script.record_off()
  If script.buf$ <> "" Then Cat script.buf$, ", "
  Cat script.buf$, "record_off"
End Sub

Sub script.replay_off()
  If script.buf$ <> "" Then Cat script.buf$, ", "
  Cat script.buf$, "replay_off"
End Sub

' End of stubs -------------------------------------------------------------------------------------

#Include "../state.inc"
Erase state.obj_rm%
Dim state.obj_rm%(il)

#Include "../interp.inc"

add_test("test_has_changed")
add_test("test_is_dark")
add_test("test_do_command_56 (NIGHT)", "test_do_command_56")
add_test("test_do_command_57 (DAY)", "test_do_command_57")
add_test("test_do_command_58 (SETz)", "test_do_command_58")
add_test("test_do_command_60 (CLRz)", "test_do_command_60")
add_test("test_do_command_61 (DEAD)", "test_do_command_61")
add_test("test_do_command_63 (FINI)", "test_do_command_63")
add_test("test_do_command_65 (SCORE)", "test_do_command_65")
add_test("test_do_command_67 (SET0)", "test_do_command_67")
add_test("test_do_command_68 (CLR0)", "test_do_command_68")
add_test("test_do_command_69 (FILL)", "test_do_command_69")
add_test("test_do_command_81 (EXm,CT)", "test_do_command_81")
add_test("test_evaluate_condition_8 (is flag set)", "test_evaluate_condition_8")
add_test("test_evaluate_condition_9 (is flag clear)", "test_evaluate_condition_9")
add_test("test_go_direction_given_dark")
add_test("test_update_lamp (if carrying)", "test_update_lamp_carrying")
add_test("test_update_lamp (if stored)", "test_update_lamp_stored")
add_test("test_update_lamp (if in same room)", "test_update_lamp_same")
add_test("test_update_lamp (if in different room)", "test_update_lamp_different"))
add_test("test_update_lamp (non-prehistoric lamp)", "test_update_lamp_modern"))

run_tests()

End

Sub setup_test()
  Local i%, j%
  r = 1

  ' Initialise 'sf' with a pattern so we have a chance of
  ' detecting flags being accidentally cleared/set.
  sf = &b11110000111100001111000011110000

  For i% = 0 To 9 : interp.room_state%(i%) = 0 : Next

  For i% = 0 To cl
    For j% = 0 To 7 : ca(i%, j%) = 0 : Next
  Next

  For i% = 0 To il : ia_str$(i%) = "" : state.obj_rm%(i%) = 0 : Next

  For i% = 0 To rl
    For j% = 0 To 5 : rm(i%, j%) = 0 : Next
  Next

  con.buf$ = ""
  con.in_buf$ = ""
  script.buf$ = ""
End Sub

Sub teardown_test()
End Sub

Sub test_has_changed()
  Local i%

  bits.clear(sf, state.DARK_BIT%)
  r% = 5
  state.obj_rm%(10) = 5
  state.obj_rm%(12) = 5
  state.obj_rm%(20) = 5
  state.obj_rm%(72) = 5
  state.obj_rm%(74) = 5
  state.obj_rm%(100) = 10
  assert_int_equals(1, interp.has_changed%())
  Local expected%(9) = (5, &b100000001010000000000, &b10100000000, 0, 0, 0, 0, 0, 0, 0)
  assert_int_array_equals(expected%(), interp.room_state%())

  ' A subsequent call without changing any of the room state returns 0.
  assert_int_equals(0, interp.has_changed%())
  assert_int_array_equals(expected%(), interp.room_state%())

  ' Set the dark status bit.
  bits.set(sf, state.DARK_BIT%)
  assert_int_equals(1, interp.has_changed%())
  expected%(0) = 5 + 65536
  assert_int_array_equals(expected%(), interp.room_state%())

  ' Change the current room.
  r = 10
  assert_int_equals(1, interp.has_changed%())
  expected%(0) = 10 + 65536
  expected%(1) = 0
  expected%(2) = &b1000000000000000000000000000000000000
  assert_int_array_equals(expected%(), interp.room_state%())

  ' Change the current room back.
  r = 5
  assert_int_equals(1, interp.has_changed%())
  expected%(0) = 5 + 65536
  expected%(1) = &b100000001010000000000
  expected%(2) = &b10100000000
  assert_int_array_equals(expected%(), interp.room_state%())
End Sub

Sub test_is_dark()
  ' Given dark status bit unset.
  bits.clear(sf, state.DARK_BIT%)
  assert_int_equals(0, is_dark%())

  ' Given carrying artificial light source.
  bits.set(sf, state.DARK_BIT%)
  state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_CARRIED%
  assert_int_equals(0, is_dark%())

  ' Given artificial light source in room.
  r = 1
  state.obj_rm%(OBJ_LIT_LAMP%) = r
  assert_int_equals(0, is_dark%())

  ' Given artificial light source is elsewhere.
  state.obj_rm%(OBJ_LIT_LAMP%) = ROOM_STORE%
  assert_int_equals(1, is_dark%())
End Sub

Sub test_do_command_56() ' NIGHT
  ' Given currently light.
  bits.clear(sf, state.DARK_BIT%)
  do_command(0, 56, "")
  assert_true(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100001111000011110000, sf)

  ' Given currently dark.
  do_command(0, 56, "")
  assert_true(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100001111000011110000, sf)
End Sub

Sub test_do_command_57() ' DAY
  ' Given currently dark.
  bits.set(sf, state.DARK_BIT%)
  do_command(0, 57, "")
  assert_false(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100000111000011110000, sf)

  ' Given currently light.
  do_command(0, 57, "")
  assert_false(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100000111000011110000, sf)
End Sub

Sub test_do_command_58() ' SETz
  bits.clear(sf, 8)
  ip = 0
  given_parameter_value(0, 1, 8)

  do_command(0, 58, "")

  assert_true(bits.get%(sf, 8))
  assert_hex_equals(&b11110000111100001111000111110000, sf)
End Sub

Sub given_parameter_value(a%, p%, value%)
  ca(a%, p%) = 20 * value%
End Sub

Sub test_do_command_60() 'CLRz
  bits.set(sf, 7)
  ip = 0
  given_parameter_value(0, 1, 7)

  do_command(0, 60, "")

  assert_false(bits.get%(sf, 7))
  assert_hex_equals(&b11110000111100001111000001110000, sf)
End Sub

Sub test_do_command_61() ' DEAD
  bits.set(sf, state.DARK_BIT%)
  r = 1
  rl = 10

  do_command(0, 61, "")

  assert_false(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100000111000011110000, sf)
  assert_int_equals(10, r)
  assert_string_equals("I'm dead..." + sys.CRLF$, con.buf$)
End Sub

Sub test_do_command_63() ' FINI
  ' Given player answers "y" to play again.
  con.buf$ = ""
  con.in_buf$ = "y"
  state = STATE_OK
  do_command(0, 63, "")
  assert_string_equals("", script.buf$)
  assert_string_equals("The game is now over, would you like to play again [Y|n]? ", con.buf$)
  assert_int_equals(STATE_RESTART, state)

  ' Given player answers "n" to play again.
  con.buf$ = ""
  con.in_buf$ = "n"
  state = STATE_OK
  do_command(0, 63, "")
  assert_string_equals("", script.buf$)
  assert_string_equals("The game is now over, would you like to play again [Y|n]? ", con.buf$)
  assert_int_equals(STATE_QUIT, state)

  ' Given currently replaying.
  script.buf$ = ""
  con.fd_in = 1
  con.fd_out = 0
  do_command(0, 63, "")
  assert_string_equals("replay_off", script.buf$)

  ' Given currently recording.
  script.buf$ = ""
  con.fd_in = 0
  con.fd_out = 1
  do_command(0, 63, "")
  assert_string_equals("record_off", script.buf$)
End Sub

Sub test_do_command_65() ' SCORE
  Local expected$

  tr = 5
  tt = 3
  ia_str$(1) = "*gold"         : state.obj_rm%(1) = tr
  ia_str$(2) = "*frankincense" : state.obj_rm%(2) = tr
  ia_str$(3) = "*myrrh"        : state.obj_rm%(3) = 1
  ia_str$(4) = "rock"          : state.obj_rm%(4) = tr
  ia_str$(5) = "paper"         : state.obj_rm%(5) = tr

  ' Given not all treasures stored.
  do_command(0, 65, "")
  Cat expected$, "I've stored 2 of 3 treasures." + sys.CRLF$
  Cat expected$, "On a scale of 0 to 100 that rates a 66." + sys.CRLF$
  assert_string_equals(expected$, con.buf$)

  ' Given all treasures stored.
  state.obj_rm%(3) = tr
  con.buf$ = ""
  do_command(0, 65, "")
  expected$ = "I've stored 3 of 3 treasures." + sys.CRLF$
  Cat expected$, "On a scale of 0 to 100 that rates a 100." + sys.CRLF$
  Cat expected$, "WELL DONE !!!" + sys.CRLF$
  Cat expected$, "The game is now over, would you like to play again [Y|n]? "
  assert_string_equals(expected$, con.buf$)

  ' Given adventure has 0 treasures.
  tt = 0
  ia_str$(1) = "tom"
  ia_str$(2) = "dick"
  ia_str$(3) = "harry"
  con.buf$ = ""
  do_command(0, 65, "")
  expected$ = "I've stored 0 of 0 treasures." + sys.CRLF$
  assert_string_equals(expected$, con.buf$)
End Sub

Sub test_do_command_67() ' SET0
  bits.clear(sf, 0)

  do_command(0, 67, "")

  assert_true(bits.get%(sf, 0))
  assert_hex_equals(&b11110000111100001111000011110001, sf)
End Sub

Sub test_do_command_68() ' CLR0
  bits.set(sf, 0)

  do_command(0, 68, "")

  assert_false(bits.get%(sf, 0))
  assert_hex_equals(&b11110000111100001111000011110000, sf)
End Sub

Sub test_do_command_69() ' FILL
  lx = 10
  lt = 70
  state.obj_rm%(OBJ_LIT_LAMP%) = 5
  bits.set(sf, state.LAMP_OUT_BIT%)

  do_command(0, 69, "")

  assert_int_equals(70, lx)
  assert_int_equals(-1, state.obj_rm%(OBJ_LIT_LAMP%))
  assert_false(bits.get%(sf, state.LAMP_OUT_BIT%))
End Sub

Sub test_do_command_81() ' EXm,CT
  lx = 10
  counter = 25
  ip = 0
  given_parameter_value(0, 1, 8)

  do_command(0, 81, "")

  ' Expect counter and lx to have been swapped.
  assert_int_equals(10, counter)
  assert_int_equals(25, lx)
End Sub

Sub test_evaluate_condition_8() 'is flag set
  Local i%
  For i% =  0 To  3 : assert_false(evaluate_condition(8, i%)) : Next
  For i% =  4 To  7 : assert_true (evaluate_condition(8, i%)) : Next
  For i% =  8 To 11 : assert_false(evaluate_condition(8, i%)) : Next
  For i% = 12 To 15 : assert_true (evaluate_condition(8, i%)) : Next
  For i% = 16 To 19 : assert_false(evaluate_condition(8, i%)) : Next
  For i% = 20 To 23 : assert_true (evaluate_condition(8, i%)) : Next
  For i% = 24 To 27 : assert_false(evaluate_condition(8, i%)) : Next
  For i% = 28 To 31 : assert_true (evaluate_condition(8, i%)) : Next
End Sub

Sub test_evaluate_condition_9() 'is flag clear
  Local i%
  For i% =  0 To  3 : assert_true (evaluate_condition(9, i%)) : Next
  For i% =  4 To  7 : assert_false(evaluate_condition(9, i%)) : Next
  For i% =  8 To 11 : assert_true (evaluate_condition(9, i%)) : Next
  For i% = 12 To 15 : assert_false(evaluate_condition(9, i%)) : Next
  For i% = 16 To 19 : assert_true (evaluate_condition(9, i%)) : Next
  For i% = 20 To 23 : assert_false(evaluate_condition(9, i%)) : Next
  For i% = 24 To 27 : assert_true (evaluate_condition(9, i%)) : Next
  For i% = 28 To 31 : assert_false(evaluate_condition(9, i%)) : Next
End Sub

Sub test_go_direction_given_dark()
  bits.set(sf, state.DARK_BIT%)
  state.obj_rm%(OBJ_LIT_LAMP%) = 0
  rm(1, 0) = 2
  rl = 10

  ' Given exit exists.
  r = 1
  go_direction(1)
  assert_int_equals(2, r)
  assert_string_equals("Dangerous to move in the dark!" + sys.CRLF$, con.buf$)

  ' Given exit does not exist.
  con.buf$ = ""
  r = 1
  go_direction(2)
  assert_int_equals(10, r)
  assert_false(bits.get%(sf, state.DARK_BIT%))
  assert_hex_equals(&b11110000111100000111000011110000, sf)
  Local expected$ = "Dangerous to move in the dark!" + sys.CRLF$
  Cat expected$, "I fell down and broke my neck." + sys.CRLF$
  assert_string_equals(expected$, con.buf$)
End Sub

Sub test_update_lamp_carrying()
  Const lamp_room% = ROOM_CARRIED%
  r = 2
  map.put(options$(), "prehistoric_lamp", "1")

  ' Given duration > 25
  setup_update_lamp(26, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(25, lamp_room%, 0)

  ' Given duration <= 25
  setup_update_lamp(25, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(24, lamp_room%, 0, "Light runs out in 24 turns!")

  ' Given duration = 1
  setup_update_lamp(1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1, "Light has run out!")

  ' Given duration = 0
  setup_update_lamp(0, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1, "Light has run out!")

  ' Given duration = -1
  setup_update_lamp(-1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(-1, lamp_room%, 0)
End Sub

Sub setup_update_lamp(duration%, lamp_room%)
  lx = duration%
  state.obj_rm%(OBJ_LIT_LAMP%) = lamp_room%
  bits.clear(sf, state.LAMP_OUT_BIT%)
  con.buf$ = ""
End Sub

Sub assert_lamp_state(duration%, lamp_room%, lamp_out%, msg$)
  assert_int_equals(duration%, lx)
  assert_int_equals(lamp_room%, state.obj_rm%(OBJ_LIT_LAMP%))
  assert_int_equals(lamp_out%, bits.get%(sf, state.LAMP_OUT_BIT%))
  assert_string_equals(Choice(msg$ = "", "", msg$ + sys.CRLF$), con.buf$)
End Sub

' The light duration is not decreased if it is in the 'store'.
Sub test_update_lamp_stored()
  Const lamp_room% = ROOM_STORE%
  r = 2
  map.put(options$(), "prehistoric_lamp", "1")

  ' Given duration > 25
  setup_update_lamp(26, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(26, lamp_room%, 0)

  ' Given duration <= 25
  setup_update_lamp(25, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(25, lamp_room%, 0)

  ' Given duration = 1
  setup_update_lamp(1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(1, lamp_room%, 0)

  ' Given duration = 0
  setup_update_lamp(0, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, lamp_room%, 0)

  ' Given duration = -1
  setup_update_lamp(-1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(-1, lamp_room%, 0)
End Sub

Sub test_update_lamp_same()
  Const lamp_room% = 2
  r = 2
  map.put(options$(), "prehistoric_lamp", "1")

  ' Given duration > 25
  setup_update_lamp(26, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(25, lamp_room%, 0)

  ' Given duration <= 25
  setup_update_lamp(25, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(24, lamp_room%, 0, "Light runs out in 24 turns!")

  ' Given duration = 1
  setup_update_lamp(1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1, "Light has run out!")

  ' Given duration = 0
  setup_update_lamp(0, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1, "Light has run out!")

  ' Given duration = -1
  setup_update_lamp(-1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(-1, lamp_room%, 0)
End Sub

' No light messages if player is not carrying or in same room as light.
Sub test_update_lamp_different()
  Const lamp_room% = 3
  r = 2
  map.put(options$(), "prehistoric_lamp", "1")

  ' Given duration > 25
  setup_update_lamp(26, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(25, lamp_room%, 0)

  ' Given duration <= 25
  setup_update_lamp(25, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(24, lamp_room%, 0)

  ' Given duration = 1
  setup_update_lamp(1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1)

  ' Given duration = 0
  setup_update_lamp(0, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, ROOM_STORE%, 1)

  ' Given duration = -1
  setup_update_lamp(-1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(-1, lamp_room%, 0)
End Sub

' With the non-prehistoric lamp the artificial light source is not moved to
' ROOM_STORE% when it is exhausted.
Sub test_update_lamp_modern()
  Const lamp_room% = ROOM_CARRIED%
  r = 2
  map.put(options$(), "prehistoric_lamp", "0")

  ' Given duration = 1
  setup_update_lamp(1, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, lamp_room%, 1, "Light has run out!")

  ' Given duration = 0
  setup_update_lamp(0, lamp_room%)
  interp.update_lamp()
  assert_lamp_state(0, lamp_room%, 1, "Light has run out!")
End Sub
