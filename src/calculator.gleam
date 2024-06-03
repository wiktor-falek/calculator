import exceptions
import gleam/dict
import gleam/erlang
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import types as t
import utils
import vars.{create_vars, read_var, update_vars}

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
      var_or_number -> {
        case int.parse(var_or_number) {
          Ok(integer) -> t.Number(t.Integer(integer))
          Error(_) ->
            case float.parse(var_or_number) {
              Ok(float) -> t.Number(t.Float(float))
              Error(_) -> {
                t.Variable(var_or_number)
              }
            }
        }
      }
    }
  })
}

pub fn get_operand_value(
  operand: t.Operand,
  vars: dict.Dict(String, t.Number),
) -> Result(t.Number, Nil) {
  case operand {
    t.NumberOperand(number) ->
      case number {
        t.IntegerOperand(integer) -> Ok(t.Integer(integer))
        t.FloatOperand(float) -> Ok(t.Float(float))
      }
    t.VariableOperand(var) -> {
      vars
      |> read_var(var)
    }
    _ -> Error(Nil)
  }
}

pub fn number_to_float(n: t.Number) -> Float {
  case n {
    t.Float(float) -> float
    t.Integer(integer) -> int.to_float(integer)
  }
}

pub fn process_tokens(
  tokens: List(t.Token),
  stack: List(t.Operand),
  vars: dict.Dict(String, t.Number),
) -> #(t.Operand, dict.Dict(String, t.Number)) {
  case tokens {
    [] -> {
      let value = case list.last(stack) {
        Ok(op) -> op
        Error(_) -> t.NilOperand
      }
      #(value, vars)
    }
    [token, ..rest_tokens] -> {
      case token {
        t.Nil ->
          process_tokens(rest_tokens, list.append(stack, [t.NilOperand]), vars)
        t.Variable(var) ->
          process_tokens(
            rest_tokens,
            list.append(stack, [t.VariableOperand(var)]),
            vars,
          )
        t.Number(number) ->
          case number {
            t.Integer(integer) -> {
              process_tokens(
                rest_tokens,
                list.append(stack, [t.NumberOperand(t.IntegerOperand(integer))]),
                vars,
              )
            }
            t.Float(float) -> {
              process_tokens(
                rest_tokens,
                list.append(stack, [t.NumberOperand(t.FloatOperand(float))]),
                vars,
              )
            }
          }
        t.Assign -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [t.VariableOperand(var), b] -> {
              case b {
                t.NumberOperand(number) -> {
                  let vars =
                    update_vars(vars, var, case number {
                      t.IntegerOperand(integer) -> t.Integer(integer)
                      t.FloatOperand(float) -> t.Float(float)
                    })
                  let stack = list.append(stack, [t.NumberOperand(number)])
                  process_tokens(rest_tokens, stack, vars)
                }
                t.VariableOperand(existing_var) -> {
                  case vars.read_var(vars, existing_var) {
                    Ok(number) -> {
                      let vars = update_vars(vars, var, number)
                      let stack =
                        list.append(stack, [
                          case number {
                            t.Float(float) ->
                              t.NumberOperand(t.FloatOperand(float))
                            t.Integer(integer) ->
                              t.NumberOperand(t.IntegerOperand(integer))
                          },
                        ])
                      process_tokens(rest_tokens, stack, vars)
                    }
                    Error(_) -> #(
                      exceptions.invalid_arguments(
                        "Expected (Variable, Number, =)",
                      ),
                      vars,
                    )
                  }
                }
                _ -> #(
                  exceptions.invalid_arguments("Expected (Variable, Number, =)"),
                  vars,
                )
              }
            }
            [_, _] -> #(
              exceptions.invalid_arguments("Expected (Variable, Number, =)"),
              vars,
            )
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpAdd -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, vars)
              let right = get_operand_value(b, vars)
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpSub -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, vars)
              let right = get_operand_value(b, vars)
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpMul -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, vars)
              let right = get_operand_value(b, vars)
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpDiv -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, vars)
              let right = get_operand_value(b, vars)
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpMod -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let left = get_operand_value(a, vars)
              let right = get_operand_value(b, vars)
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
          }
        }
        t.OpPow -> {
          let #(stack, operands) = utils.take_and_split(stack, 2)

          case operands {
            [a, b] -> {
              let a =
                result.try(get_operand_value(a, vars), fn(a) {
                  Ok(number_to_float(a))
                })
              let b =
                result.try(get_operand_value(b, vars), fn(b) {
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
                  process_tokens(rest_tokens, list.append(stack, [value]), vars)
                }
                Error(exception) -> #(exception, vars)
              }
            }
            rest -> #(exceptions.invalid_parity(2, list.length(rest)), vars)
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
              process_tokens(rest_tokens, list.append(stack, [value]), vars)
            }
            Error(exception) -> #(exception, vars)
          }
        }
      }
    }
    // 
  }
}

pub fn read() -> String {
  erlang.get_line("> ")
  |> result.unwrap("")
  |> string.replace("\n", "")
}

pub fn eval(
  tokens: List(t.Token),
  vars: dict.Dict(String, t.Number),
) -> #(t.Operand, dict.Dict(String, t.Number)) {
  process_tokens(tokens, [], vars)
}

pub fn round_format_number(number: t.Number) -> String {
  case number {
    t.Integer(integer) -> {
      int.to_string(integer)
    }
    t.Float(float) -> {
      // TODO: round things like 0.30000000000000004 to 0.3
      let is_whole = float == int.to_float(float.truncate(float))
      case is_whole {
        True -> int.to_string(float.truncate(float))
        False -> float.to_string(float)
      }
    }
  }
}

pub fn print_help() {
  io.println(
    "
Commands:
  .help
  .exit

Operations:
  Assignment     ( Var, Num, =)
  Addition       ( Num, Num, + )
  Subtraction    ( Num, Num, - )
  Multiplication ( Num, Num, * )
  Division       ( Num, Num, / )
  Modulo         ( Num, Num, % )
  Power          ( Num, Num, ** )
  Square Root    ( Num, ^ )
",
  )
}

pub fn format_value(
  value: t.Operand,
  vars: dict.Dict(String, t.Number),
) -> String {
  case value {
    t.VariableOperand(var) -> {
      case read_var(vars, var) {
        Ok(number) -> round_format_number(number)
        Error(_) -> "nil"
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

pub fn repl(vars: dict.Dict(String, t.Number)) {
  let line = read()
  let tokens = tokenize(line)
  let #(value, vars) = eval(tokens, vars)
  let output = format_value(value, vars)

  case line {
    ".exit" | ".e" -> Nil
    ".help" | ".h" -> {
      print_help()
      repl(vars)
    }
    "" -> repl(vars)
    _ -> {
      io.println(output)
      repl(vars)
    }
  }
}

pub fn main() {
  io.println("Welcome to Reverse Polish Notation Calculator v1.0.0")
  io.println("Type \".help\" for more information")

  let vars = create_vars()
  repl(vars)
}
