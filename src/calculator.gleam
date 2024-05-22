import exceptions
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import registers.{create_registers, read_register, update_register}
import types as t
import utils

const min_register = 1

const max_register = 10

pub fn parse_line(line: String) -> List(t.Token) {
  line
  |> string.replace("\n", "")
  |> string.split(" ")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(token) {
    // TODO: Result(Token, Exception)
    case token {
      "e" -> t.Evaluate
      "a" -> t.Assign
      "+" -> t.OpAdd
      "-" -> t.OpSub
      "*" -> t.OpMul
      "/" -> t.OpDiv
      "x" <> xs -> {
        case int.parse(xs) {
          Ok(num) ->
            case num {
              num if num > max_register ->
                exceptions.invalid_register("x" <> xs <> " does not exist")
              num if num < min_register ->
                exceptions.invalid_register("x" <> xs <> " does not exist")
              num -> t.Register(num)
            }
          Error(_) -> {
            exceptions.invalid_register("x" <> xs <> " is not a valid register")
          }
        }
      }
      str_integer -> {
        case int.parse(str_integer) {
          Ok(integer) -> t.Integer(integer)
          Error(_) ->
            exceptions.invalid_value("Expected Integer, found " <> str_integer)
        }
      }
    }
  })
}

fn process_tokens(
  tokens: List(t.Token),
  stack: List(t.Operand),
  registers: List(t.RegisterValue),
) -> #(t.Operand, List(t.RegisterValue)) {
  case tokens {
    [token, ..rest_tokens] -> {
      case token {
        t.Register(integer) ->
          process_tokens(
            rest_tokens,
            list.append(stack, [t.RegisterOperand(integer)]),
            registers,
          )
        t.Integer(integer) ->
          process_tokens(
            rest_tokens,
            list.append(stack, [t.IntegerOperand(integer)]),
            registers,
          )
        t.Evaluate -> {
          let operand = case list.last(stack) {
            Ok(value) -> {
              let output = case value {
                t.RegisterOperand(register) -> {
                  case read_register(registers, register) {
                    t.Some(integer) -> int.to_string(integer)
                    t.None -> "nil"
                  }
                }
                t.IntegerOperand(integer) -> int.to_string(integer)
                t.InvalidArgumentsException(exception) -> exception
                t.InvalidParityException(exception) -> exception
                t.Nil -> "nil"
              }

              io.print("> " <> output <> "\n")
              value
            }
            Error(_) -> exceptions.invalid_parity(1, 0)
          }
          #(operand, registers)
        }
        t.Assign -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [t.RegisterOperand(register), t.IntegerOperand(integer)] -> {
              let registers = update_register(registers, register, integer)
              process_tokens(rest_tokens, stack, registers)
            }
            [_, _] -> #(exceptions.invalid_arguments(), registers)
            rest -> #(
              exceptions.invalid_parity(2, list.length(rest)),
              registers,
            )
          }
        }
        t.OpAdd -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          let get_operand_value = fn(a: t.Operand) {
            case a {
              t.IntegerOperand(value) -> Ok(value)
              t.RegisterOperand(register) -> {
                case read_register(registers, register) {
                  t.Some(value) -> Ok(value)
                  _ -> Error("")
                }
              }
              _ -> Error("")
            }
          }

          case operands {
            [a, b] -> {
              let sum_result = case
                [get_operand_value(a), get_operand_value(b)]
              {
                [Ok(a), Ok(b)] -> Ok(a + b)
                _ -> {
                  Error(exceptions.invalid_arguments())
                }
              }

              case sum_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [t.IntegerOperand(value)]),
                    registers,
                  )
                }
                Error(exception) -> #(exception, registers)
              }
            }
            rest -> #(
              exceptions.invalid_parity(2, list.length(rest)),
              registers,
            )
          }
        }
        t.OpSub -> #(t.Nil, registers)
        t.OpMul -> #(t.Nil, registers)
        t.OpDiv -> #(t.Nil, registers)
        _ -> {
          let operand = case list.last(stack) {
            Ok(value) -> value
            Error(_) -> t.Nil
          }
          #(operand, registers)
        }
      }
    }
    _ -> #(t.Nil, registers)
  }
}

pub fn eval(
  tokens: List(t.Token),
  registers: List(t.RegisterValue),
) -> #(t.Operand, List(t.RegisterValue)) {
  process_tokens(tokens, [], registers)
}

pub fn read_forever(registers: List(t.RegisterValue)) {
  let input = result.unwrap(erlang.get_line(""), "")
  let tokens = parse_line(input)

  let #(_, registers) = eval(tokens, registers)

  case input {
    ".exit\n" -> Nil
    _ -> read_forever(registers)
  }
}

pub fn main() {
  let registers = create_registers(min_register, max_register)
  read_forever(registers)
}
