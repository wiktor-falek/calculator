import gleam/int
import types as t

pub fn invalid_register(reason: String) {
  t.InvalidRegisterException("InvalidRegisterException: " <> reason)
}

pub fn invalid_value(reason: String) {
  t.InvalidValueException("InvalidValueException: " <> reason)
}

pub fn invalid_parity(expected: Int, found: Int) {
  t.InvalidParityException(
    "InvalidParityException: expected "
    <> int.to_string(expected)
    <> " arguments, found "
    <> int.to_string(found),
  )
}

pub fn invalid_arguments() {
  t.InvalidArgumentsException("InvalidArgumentsException")
}
