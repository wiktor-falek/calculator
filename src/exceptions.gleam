import gleam/int
import types as t

pub fn invalid_register(reason: String) {
  t.InvalidRegisterException(reason)
}

pub fn invalid_value(reason: String) {
  t.InvalidValueException(reason)
}

pub fn invalid_parity(expected: Int, found: Int) {
  t.InvalidParityException(
    "Expected "
    <> int.to_string(expected)
    <> " arguments, found "
    <> int.to_string(found),
  )
}

pub fn invalid_arguments(info: String) {
  t.InvalidArgumentsException(info)
}

pub fn division_by_zero_exception() {
  t.DivisionByZeroException("Cannot divide by 0")
}

pub fn invalid_fractional_exponent_exception() {
  t.InvalidFractionalExponentException(
    "Raising a negative number to a fractional power results in a complex number",
  )
}
