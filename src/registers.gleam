import gleam/list
import types as t

pub fn create_registers(amount: Int) -> List(t.RegisterValue) {
  list.range(1, amount)
  |> list.map(fn(_) { t.None })
}

pub fn read_register(
  registers: List(t.RegisterValue),
  register_number: Int,
) -> t.RegisterValue {
  case list.at(registers, register_number - 1) {
    Ok(register_value) -> register_value
    Error(_) -> t.None
  }
}

pub fn update_register(
  registers: List(t.RegisterValue),
  index: Int,
  val: Int,
) -> List(t.RegisterValue) {
  list.index_map(registers, fn(v, i) {
    case i == index - 1 {
      True -> t.Some(val)
      False -> v
    }
  })
}
