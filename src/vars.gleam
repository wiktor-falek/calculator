import gleam/dict
import types as t

pub fn create_vars() -> dict.Dict(String, t.Number) {
  dict.new()
}

pub fn read_var(
  dict: dict.Dict(String, t.Number),
  var: String,
) -> Result(t.Number, Nil) {
  dict
  |> dict.get(var)
}

pub fn update_vars(
  dict: dict.Dict(String, t.Number),
  var: String,
  val: t.Number,
) -> dict.Dict(String, t.Number) {
  dict
  |> dict.insert(var, val)
}
