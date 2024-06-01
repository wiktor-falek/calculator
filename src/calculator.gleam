import exceptions
import gleam/erlang
import gleam/float
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
      str_number -> {
        case int.parse(str_number) {
          Ok(integer) -> t.Number(t.Integer(integer))
          Error(_) ->
            case float.parse(str_number) {
              Ok(float) -> t.Number(t.Float(float))
              Error(_) -> t.Nil
            }
        }
      }
    }
  })
}

fn get_operand_value(
  operand: t.Operand,
  registers: List(t.RegisterValue),
) -> Result(t.Number, String) {
  case operand {
    t.NumberOperand(number) ->
      case number {
        t.IntegerOperand(integer) -> Ok(t.Integer(integer))
        t.FloatOperand(float) -> Ok(t.Float(float))
      }
    t.RegisterOperand(register) -> {
      case read_register(registers, register) {
        t.Some(value) -> Ok(value)
        _ -> Error("")
      }
    }
    _ -> Error("")
  }
}

fn number_to_float(n: t.Number) -> Float {
  case n {
    t.Float(float) -> float
    t.Integer(integer) -> int.to_float(integer)
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
        t.Number(number) ->
          case number {
            t.Integer(integer) -> {
              process_tokens(
                rest_tokens,
                list.append(stack, [t.NumberOperand(t.IntegerOperand(integer))]),
                registers,
              )
            }
            t.Float(float) -> {
              process_tokens(
                rest_tokens,
                list.append(stack, [t.NumberOperand(t.FloatOperand(float))]),
                registers,
              )
            }
          }
        t.Assign -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [t.RegisterOperand(register), t.NumberOperand(number)] -> {
              let registers =
                update_register(registers, register, case number {
                  t.IntegerOperand(integer) -> t.Integer(integer)
                  t.FloatOperand(float) -> t.Float(float)
                })
              let stack = list.append(stack, [t.NumberOperand(number)])
              process_tokens(rest_tokens, stack, registers)
            }
            [_, _] -> #(
              exceptions.invalid_arguments("Expected (Register, Number, =)"),
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
                Ok(a), Ok(b) ->
                  case a, b {
                    t.Integer(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.IntegerOperand(a + b)))
                    t.Float(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a +. int.to_float(b))))
                    t.Integer(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(int.to_float(a) +. b)))
                    t.Float(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a +. b)))
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, +)",
                  ))
                }
              }

              case add_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
                Ok(a), Ok(b) ->
                  case a, b {
                    t.Integer(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.IntegerOperand(a - b)))
                    t.Float(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a -. int.to_float(b))))
                    t.Integer(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(int.to_float(a) -. b)))
                    t.Float(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a -. b)))
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, -)",
                  ))
                }
              }

              case sub_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
                Ok(a), Ok(b) ->
                  case a, b {
                    t.Integer(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.IntegerOperand(a * b)))
                    t.Float(a), t.Integer(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a *. int.to_float(b))))
                    t.Integer(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(int.to_float(a) *. b)))
                    t.Float(a), t.Float(b) ->
                      Ok(t.NumberOperand(t.FloatOperand(a *. b)))
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, *)",
                  ))
                }
              }

              case mul_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
                Ok(a), Ok(b) ->
                  case b {
                    t.Integer(0) | t.Float(0.0) ->
                      Error(exceptions.division_by_zero_exception())
                    _ ->
                      case a, b {
                        t.Integer(a), t.Integer(b) -> {
                          Ok(
                            t.NumberOperand(t.FloatOperand(
                              int.to_float(a) /. int.to_float(b),
                            )),
                          )
                        }
                        t.Float(a), t.Integer(b) ->
                          Ok(
                            t.NumberOperand(t.FloatOperand(a /. int.to_float(b))),
                          )
                        t.Integer(a), t.Float(b) ->
                          Ok(
                            t.NumberOperand(t.FloatOperand(int.to_float(a) /. b)),
                          )
                        t.Float(a), t.Float(b) ->
                          Ok(t.NumberOperand(t.FloatOperand(a /. b)))
                      }
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, /)",
                  ))
                }
              }

              case div_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
              let mod_result = case left, right {
                Ok(a), Ok(b) ->
                  case b {
                    t.Integer(0) | t.Float(0.0) ->
                      Error(exceptions.division_by_zero_exception())
                    _ -> {
                      let float_a = number_to_float(a)
                      let float_b = number_to_float(b)

                      Ok(
                        t.NumberOperand(
                          t.FloatOperand(utils.float_modulo(float_a, float_b)),
                        ),
                      )
                    }
                  }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, %)",
                  ))
                }
              }

              case mod_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
        t.OpPow -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let a =
                result.try(get_operand_value(a, registers), fn(a) {
                  Ok(number_to_float(a))
                })
              let b =
                result.try(get_operand_value(b, registers), fn(b) {
                  Ok(number_to_float(b))
                })
              let mul_result = case a, b {
                Ok(a), Ok(b) -> {
                  case float.power(a, b) {
                    Ok(float) -> Ok(t.NumberOperand(t.FloatOperand(float)))
                    Error(_) ->
                      Error(exceptions.invalid_fractional_exponent_exception())
                  }
                }
                _, _ -> {
                  Error(exceptions.invalid_arguments(
                    "Expected (Number, Number, *)",
                  ))
                }
              }

              case mul_result {
                Ok(value) -> {
                  process_tokens(
                    rest_tokens,
                    list.append(stack, [value]),
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
        t.OpSqrt -> {
          let #(stack, operands) = utils.take_and_split(stack, 1)

          let sqrt_result = case operands {
            [t.NumberOperand(number)] -> {
              let float_a =
                number_to_float(case number {
                  t.FloatOperand(float) -> t.Float(float)
                  t.IntegerOperand(integer) -> t.Integer(integer)
                })

              case float.square_root(float_a) {
                Ok(value) -> Ok(t.NumberOperand(t.FloatOperand(value)))
                Error(_) ->
                  Error(exceptions.invalid_fractional_exponent_exception())
              }
            }
            [_] -> Error(exceptions.invalid_arguments("Expected (Number, ^)"))
            xs -> Error(exceptions.invalid_parity(1, list.length(xs)))
          }

          case sqrt_result {
            Ok(value) -> {
              process_tokens(
                rest_tokens,
                list.append(stack, [value]),
                registers,
              )
            }
            Error(exception) -> #(exception, registers)
          }
        }
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

pub fn round_format_number(number: t.Number) -> String {
  case number {
    t.Integer(integer) -> {
      int.to_string(integer)
    }
    t.Float(float) -> {
      let is_whole = float == int.to_float(float.truncate(float))
      case is_whole {
        True -> int.to_string(float.truncate(float))
        False -> float.to_string(float)
      }
    }
  }
}

pub fn format_value(
  value: t.Operand,
  registers: List(t.RegisterValue),
) -> String {
  case value {
    t.RegisterOperand(register) -> {
      case read_register(registers, register) {
        t.Some(number) -> round_format_number(number)
        t.None -> "nil"
      }
    }
    t.NumberOperand(number) -> {
      round_format_number(case number {
        t.IntegerOperand(integer) -> t.Integer(integer)
        t.FloatOperand(float) -> t.Float(float)
      })
    }
    t.NilOperand -> "nil"
    t.InvalidArgumentsException(e) -> "InvalidArgumentsException: " <> e
    t.InvalidParityException(e) -> "InvalidParityException: " <> e
    t.DivisionByZeroException(e) -> "DivisionByZeroException: " <> e
    t.InvalidFractionalExponentException(e) ->
      "InvalidFractionalExponentException: " <> e
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
