import gleam/io
import gleam/list
import gleam/int
import gleam/string
import gleam/result
import utils

const min_register = 1

const max_register = 10

pub type RegisterValue {
  Some(Int)
  None
}

pub type Token {
  Evaluate
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
  Register(Int)
  Integer(Int)
  InvalidValueException(String)
  InvalidRegisterException(String)
}

pub type Operand {
  RegisterOperand(Int)
  IntegerOperand(Int)
  InvalidArgumentsException(String)
  InvalidParityException(String)
  Nil
}

pub fn invalid_register_exception(reason: String) {
  InvalidRegisterException("InvalidRegisterException: " <> reason)
}

pub fn invalid_value_exception(reason: String) {
  InvalidValueException("InvalidValueException: " <> reason)
}

pub fn invalid_parity_exception(expected: Int, found: Int) {
  InvalidParityException(
    "InvalidParityException: expected "
    <> int.to_string(expected)
    <> " arguments, found "
    <> int.to_string(found),
  )
}

pub fn invalid_arguments_exception() {
  InvalidArgumentsException("InvalidArgumentsException")
}

pub fn create_registers(
  min_register: Int,
  max_register: Int,
) -> List(RegisterValue) {
  list.range(min_register, max_register)
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

pub fn read_register(registers: List(RegisterValue), register_number: Int) {
  case list.at(registers, register_number) {
    Ok(register_value) -> register_value
    Error(_) -> None
  }
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

pub fn process_tokens(tokens: List(Token), stack: List(Operand)) {
  case tokens {
    [x, ..] -> {
      case x {
        Register(integer) ->
          process_tokens(
            list.drop(tokens, 1),
            list.append(stack, [RegisterOperand(integer)]),
          )
        Integer(integer) ->
          process_tokens(
            list.drop(tokens, 1),
            list.append(stack, [IntegerOperand(integer)]),
          )
        Evaluate -> {
          case list.last(stack) {
            Ok(value) -> {
              // TODO: print operand as a string
              io.debug(value)
            }
            Error(_) -> invalid_parity_exception(1, 0)
          }
        }
        Assign -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [RegisterOperand(register), IntegerOperand(integer)] -> {
              // TODO: assign integer to the register
              io.debug(
                "Assigning "
                <> int.to_string(integer)
                <> " to register"
                <> int.to_string(register),
              )
              process_tokens(list.drop(tokens, 1), stack)
            }
            [_, _] -> invalid_arguments_exception()
            rest -> invalid_parity_exception(2, list.length(rest))
          }
        }
        OpAdd -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          let get_operand_value = fn(a: Operand) {
            case a {
              IntegerOperand(value) -> Ok(value)
              RegisterOperand(register) -> {
                // TODO: take in registers as arg, return updated regtisters
                // case read_register([], register) {}
                // read_register([], register)
                Error("")
              }
              _ -> Error("")
            }
          }

          case operands {
            [a, b] -> {
              let left = get_operand_value(a)
              let right = get_operand_value(b)

              // if either left or right is an Error return 
              // list.any([left, right], fn(a) { a == Error("") })

              let value = IntegerOperand(1)
              process_tokens(list.drop(tokens, 1), list.append(stack, [value]))
            }
            rest -> invalid_parity_exception(2, list.length(rest))
          }
        }
        OpSub -> Nil
        OpMul -> Nil
        OpDiv -> Nil
        _ ->
          case list.last(stack) {
            Ok(value) -> value
            Error(_) -> Nil
          }
      }
    }
    _ -> Nil
  }
}

pub fn eval(tokens: List(Token)) {
  io.debug(tokens)
  // io.debug(stack)
}

pub fn main() {
  let input = "x1 3 a\n x2 2 3 + a\n x1 x2 + e"

  let lines =
    input
    |> string.split("\n")

  let line_tokens = list.map(lines, parse_line)

  let _registers = create_registers(min_register, max_register)

  list.each(line_tokens, eval)
}
