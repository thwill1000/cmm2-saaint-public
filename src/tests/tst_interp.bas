' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../splib/system.inc"
#Include "../splib/array.inc"
#Include "../splib/list.inc"
#Include "../splib/string.inc"
#Include "../splib/file.inc"
#Include "../splib/map.inc"
#Include "../splib/math.inc"
#Include "../splib/set.inc"
#Include "../splib/vt100.inc"
#Include "/sptools/src/sptest/unittest.inc"
#Include "../advent.inc"

sys.provides("console") ' Stub dependency on "console.inc".
sys.provides("script") ' Stub dependency on "script.inc".

#Include "../state.inc"
#Include "../interp.inc"

Dim con.buf$

Sub con.println(s$)
  Cat con.buf$, s$ + sys.CRLF$
End Sub

add_test("test_has_changed")
add_test("test_is_dark")
add_test("test_do_command_56 (NIGHT)", "test_do_command_56")
add_test("test_do_command_57 (DAY)", "test_do_command_57")
add_test("test_do_command_61 (DEAD)", "test_do_command_61")
add_test("test_do_command_69 (FILL)", "test_do_command_69")
add_test("test_do_command_81 (EXm,CT)", "test_do_command_81")
add_test("test_go_direction_given_dark")
add_test("test_update_light")

run_tests()

End

Sub setup_test()
  Local i%
  For i% = 0 To 9 : interp.room_state%(i%) = 0 : Next
  r = 1

  ' Allocate 100 objects.
  il = 100
  Erase state.obj_rm%
  Dim state.obj_rm%(il)

  ' Allocate 10 rooms.
  rl = 10
  On Error Skip
  Erase rm
  Dim rm(rl, 5)

  On Error Skip
  Erase ca
  Dim ca(100, 7)

  con.buf$ = ""
End Sub

Sub teardown_test()
End Sub

Sub test_has_changed()
  Local i%

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

  ' Change the dark flag.
  df = 1
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
  ' Given dark flag unset.
  df = 0
  assert_int_equals(0, is_dark%())

  ' Given carrying light source.
  df = 1
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = ROOM_CARRIED%
  assert_int_equals(0, is_dark%())

  ' Given light source in room.
  r = 1
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = r
  assert_int_equals(0, is_dark%())

  ' Given light source is elsewhere.
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = ROOM_STORE%
  assert_int_equals(1, is_dark%())
End Sub

Sub test_do_command_56() ' NIGHT
  ' Given currently light.
  df = 0
  do_command(0, 56, "")
  assert_int_equals(1, df)

  ' Given currently dark.
  do_command(0, 56, "")
  assert_int_equals(1, df)
End Sub

Sub test_do_command_57() ' DAY
  ' Given currently dark.
  df = 1
  do_command(0, 57, "")
  assert_int_equals(0, df)

  ' Given currently light.
  do_command(0, 57, "")
  assert_int_equals(0, df)
End Sub

Sub test_do_command_61() ' DEAD
  df = 1
  r = 1
  rl = 10

  do_command(0, 61, "")

  assert_int_equals(0, df)
  assert_int_equals(10, r)
  assert_string_equals("I'm dead..." + sys.CRLF$, con.buf$)
End Sub

Sub test_do_command_69() ' FILL
  lx = 10
  lt = 70
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = 5

  do_command(0, 69, "")

  assert_int_equals(70, lx)
  assert_int_equals(-1, state.obj_rm%(OBJ_LIGHT_SOURCE%))
End Sub

Sub test_do_command_81() ' EXm,CT
  lx = 10
  counter = 25
  ip = 0 : ca(0, 1) = 160 ' Gives a 1st parameter value of 8.

  do_command(0, 81, "")

  ' Expect counter and lx to have been swapped.
  assert_int_equals(10, counter)
  assert_int_equals(25, lx)
End Sub

Sub test_go_direction_given_dark()
  df = 1
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = 0
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
  Local expected$ = "Dangerous to move in the dark!" + sys.CRLF$
  Cat expected$, "I fell down and broke my neck." + sys.CRLF$
  assert_string_equals(expected$, con.buf$)
End Sub

Sub test_update_light()
  ' Given light source plentiful.
  state.obj_rm%(OBJ_LIGHT_SOURCE%) = ROOM_CARRIED%
  lx = 26
  update_light()
  assert_int_equals(25, lx)
  assert_string_equals("", con.buf$)

  ' Given light source running out.
  con.buf$ = ""
  lx = 25
  update_light()
  assert_int_equals(24, lx)
  assert_string_equals("Light runs out in 24 turns!" + sys.CRLF$, con.buf$)

  ' Given light source exhausted.
  con.buf$ = ""
  lx = 0
  update_light()
  assert_int_equals(-1, lx)
  assert_string_equals("Light has run out!" + sys.CRLF$, con.buf$)

  ' Given light source not being carried.
  con.buf$ = ""
  lx = 25
  update_light()
  assert_int_equals(25, lx)
  assert_string_equals("", con.buf$)
End Sub
