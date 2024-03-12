import gleam/io
import gleam/list
import gleam/int
import gleam/string
import gleam/result

pub type Token {
  Evaluate
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
  Register(Int)
  Integer(Int)
}

pub type RegisterValue {
  Some(Int)
  None
}

pub fn create_registers(amount: Int) -> List(RegisterValue) {
  list.range(0, amount - 1)
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
            let register_number = result.unwrap(int.parse(xs), 69_420)
            Register(register_number)
          }
          _ -> {
            let integer = result.unwrap(int.parse(x <> xs), 0)
            Integer(integer)
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
  let input = "1\na x1 + 1 2\n"
  let processed_input =
    input
    |> string.slice(0, string.length(input) - 1)
    |> string.split("\n")

  let #(_line_count, lines) = case processed_input {
    [] -> #(0, [])
    [_] -> #(0, [])
    [x, ..xs] -> {
      let line_count = result.unwrap(int.parse(x), 0)
      #(line_count, xs)
    }
  }

  let _registers = create_registers(10)

  let line_tokens = list.map(lines, parse_line)

  list.each(line_tokens, eval)
}
