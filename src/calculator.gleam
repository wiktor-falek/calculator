import gleam/io
import gleam/list
import gleam/int
import gleam/string
import gleam/result

const min_register = 1

const max_register = 10

pub type Token {
  Evaluate
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
  Register(Int)
  Integer(Int)
  InvalidRegisterException(String)
  InvalidValueException(String)
}

pub type RegisterValue {
  Some(Int)
  None
}

pub fn invalid_register_exception(reason: String) {
  InvalidRegisterException("InvalidRegisterException: " <> reason)
}

pub fn invalid_value_exception(reason: String) {
  InvalidValueException("InvalidValueException: " <> reason)
}

pub fn create_registers(amount: Int) -> List(RegisterValue) {
  list.range(1, amount)
  |> list.map(fn(_) { None })
}

pub fn update_register(
  registers: List(RegisterValue),
  register_number: Int,
  val: Int,
) -> List(RegisterValue) {
  list.index_map(registers, fn(v, i) {
    case i == register_number {
      True -> Some(val)
      False -> v
    }
  })
}

pub fn parse_line(line: String) -> List(Token) {
  string.split(line, " ")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(token) {
    case token {
      "e" -> Evaluate
      "a" -> Assign
      "+" -> OpAdd
      "-" -> OpSub
      "*" -> OpMul
      "/" -> OpDiv
      reg_or_int -> {
        let x = result.unwrap(string.first(reg_or_int), "")
        let xs = string.slice(reg_or_int, 1, string.length(reg_or_int))
        case x {
          "x" -> {
            case int.parse(xs) {
              Ok(num) ->
                case num {
                  num if num > max_register ->
                    invalid_register_exception("x" <> xs <> " does not exist")
                  num if num < min_register ->
                    invalid_register_exception(
                      "x" <> xs <> " is not a valid register",
                    )
                  num -> Register(num)
                }
              Error(_) ->
                invalid_register_exception(
                  "x" <> xs <> " is not a valid register",
                )
            }
          }
          _ -> {
            case int.parse(reg_or_int) {
              Ok(integer) -> Integer(integer)
              _ ->
                invalid_value_exception(
                  "Expected Integer, found " <> reg_or_int,
                )
            }
          }
        }
      }
    }
  })
}

pub fn eval(tokens: List(Token)) {
  io.debug(tokens)
}

pub fn main() {
  let input = "a x1 3\na x2 5\na + x1 x2 x3\n e x3"

  let lines =
    input
    |> string.split("\n")

  let _registers = create_registers(max_register + 1 - min_register)

  let line_tokens = list.map(lines, parse_line)

  list.each(line_tokens, eval)
}
