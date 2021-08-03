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
#Include "../console.inc"

sys.provides("script") ' Stub dependency on "script.inc".

#Include "../state.inc"
#Include "../interp.inc"

add_test("test_has_changed")

run_tests()

End

Sub setup_test()
  Local i%
  For i% = 0 To 9 : interp.room_state%(i%) = 0 : Next
  r = 1

  ' Allocate room for 100 objects.
  il = 100
  Erase state.obj_rm%
  Dim state.obj_rm%(100)
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
