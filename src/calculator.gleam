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

const register_count = 10

pub fn tokenize(line: String) -> List(t.Token) {
  line
  |> string.replace("\n", "")
  |> string.split(" ")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(token) {
    case token {
      "=" -> t.Assign
      "+" -> t.OpAdd
      "-" -> t.OpSub
      "*" -> t.OpMul
      "/" -> t.OpDiv
      "%" -> t.OpMod
      "^" -> t.OpSqrt
      "**" -> t.OpPow
      "x" <> xs -> {
        case int.parse(xs) {
          Ok(num) ->
            case num {
              num if num > register_count ->
                exceptions.invalid_register("x" <> xs <> " does not exist")
              num if num < 1 ->
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
          Error(_) -> t.Nil
        }
      }
    }
  })
}

fn get_operand_value(
  a: t.Operand,
  registers: List(t.RegisterValue),
) -> Result(Int, String) {
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

fn process_tokens(
  tokens: List(t.Token),
  stack: List(t.Operand),
  registers: List(t.RegisterValue),
) -> #(t.Operand, List(t.RegisterValue)) {
  case tokens {
    [token, ..rest_tokens] -> {
      case token {
        t.Nil ->
          process_tokens(
            rest_tokens,
            list.append(stack, [t.NilOperand]),
            registers,
          )
        t.Register(integer) ->
          process_tokens(
            rest_tokens,
            list.append(stack, [t.RegisterOperand(integer)]),
            registers,
          )
        t.Integer(integer) -> {
          process_tokens(
            rest_tokens,
            list.append(stack, [t.IntegerOperand(integer)]),
            registers,
          )
        }
        t.Assign -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [t.RegisterOperand(register), t.IntegerOperand(integer)] -> {
              let registers = update_register(registers, register, integer)
              let stack = list.append(stack, [t.IntegerOperand(integer)])
              process_tokens(rest_tokens, stack, registers)
            }
            [_, _] -> #(
              exceptions.invalid_arguments("Expected (Register, Int, =)"),
              registers,
            )
            rest -> #(
              exceptions.invalid_parity(2, list.length(rest)),
              registers,
            )
          }
        }
        t.OpAdd -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, registers)
              let right = get_operand_value(b, registers)
              let add_result = case left, right {
                Ok(a), Ok(b) -> Ok(a + b)
                _, _ -> {
                  Error(exceptions.invalid_arguments("Expected (Int, Int, +)"))
                }
              }

              case add_result {
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
        t.OpSub -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, registers)
              let right = get_operand_value(b, registers)
              let sub_result = case left, right {
                Ok(a), Ok(b) -> Ok(a - b)
                _, _ -> {
                  Error(exceptions.invalid_arguments("Expected (Int, Int, -)"))
                }
              }

              case sub_result {
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
        t.OpMul -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, registers)
              let right = get_operand_value(b, registers)
              let mul_result = case left, right {
                Ok(a), Ok(b) -> {
                  Ok(a * b)
                }
                _, _ -> {
                  Error(exceptions.invalid_arguments("Expected (Int, Int, *)"))
                }
              }

              case mul_result {
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
        t.OpDiv -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, registers)
              let right = get_operand_value(b, registers)
              let div_result = case left, right {
                Ok(a), Ok(b) -> Ok(a / b)
                _, _ -> {
                  Error(exceptions.invalid_arguments("Expected (Int, Int, /)"))
                }
              }

              case div_result {
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
        t.OpMod -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, registers)
              let right = get_operand_value(b, registers)
              let div_result = case left, right {
                Ok(a), Ok(b) ->
                  case int.modulo(a, b) {
                    Ok(result) -> Ok(result)
                    Error(_) -> Error(exceptions.division_by_zero_exception())
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments("Expected (Int, Int, %)"))
                }
              }

              case div_result {
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

        // t.OpSqrt -> {
        // }
        // t.OpPow -> {
        // }
        _ -> {
          let operand = case list.last(stack) {
            Ok(value) -> value
            Error(_) -> t.NilOperand
          }
          #(operand, registers)
        }
      }
    }
    _ -> {
      let value = case list.last(stack) {
        Ok(op) -> op
        Error(_) -> t.NilOperand
      }
      #(value, registers)
    }
  }
}

pub fn read() -> String {
  let input = result.unwrap(erlang.get_line("> "), "")
  input
}

pub fn eval(
  tokens: List(t.Token),
  registers: List(t.RegisterValue),
) -> #(t.Operand, List(t.RegisterValue)) {
  process_tokens(tokens, [], registers)
}

pub fn format_value(
  value: t.Operand,
  registers: List(t.RegisterValue),
) -> String {
  case value {
    t.RegisterOperand(register) -> {
      case read_register(registers, register) {
        t.Some(integer) -> {
          int.to_string(integer)
        }
        t.None -> "nil"
      }
    }
    t.IntegerOperand(integer) -> {
      int.to_string(integer)
    }
    t.NilOperand -> "nil"
    t.InvalidArgumentsException(e) -> "InvalidArgumentsException: " <> e
    t.InvalidParityException(e) -> "InvalidParityException: " <> e
    t.DivisionByZeroException(e) -> "DivisionByZeroException: " <> e
  }
}

pub fn repl(registers: List(t.RegisterValue)) {
  let line = read()
  let tokens = tokenize(line)

  let #(value, registers) = eval(tokens, registers)

  let output = format_value(value, registers)

  io.println(output)

  case line {
    ".exit\n" -> Nil
    _ -> repl(registers)
  }
}

pub fn main() {
  io.println("Reverse Polish Notation Calculator v0.x.x")

  let registers = create_registers(register_count)
  repl(registers)
}
