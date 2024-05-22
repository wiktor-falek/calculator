import gleam/list
import types as t

pub fn create_registers(
  min_register: Int,
  max_register: Int,
) -> List(t.RegisterValue) {
  list.range(min_register, max_register)
  |> list.map(fn(_) { t.None })
}

pub fn read_register(
  registers: List(t.RegisterValue),
  register_number: Int,
) -> t.RegisterValue {
  case list.at(registers, register_number) {
    Ok(register_value) -> register_value
    Error(_) -> t.None
  }
}

pub fn update_register(
  registers: List(t.RegisterValue),
  register_number: Int,
  val: Int,
) -> List(t.RegisterValue) {
  list.index_map(registers, fn(v, i) {
    case i == register_number {
      True -> t.Some(val)
      False -> v
    }
  })
}
