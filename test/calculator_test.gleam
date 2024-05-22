import calculator.{eval}
import gleam/list
import gleeunit
import gleeunit/should
import registers.{create_registers}
import types as t

pub fn main() {
  gleeunit.main()
}

pub fn eval_test() {
  let tokens = []
  let registers = create_registers(1, 10)
  eval(tokens, registers)
  |> should.equal(#(t.Nil, list.repeat(t.None, 10)))
}
