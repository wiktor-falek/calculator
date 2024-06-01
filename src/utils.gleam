import gleam/float
import gleam/int
import gleam/list

/// Takes up to the given number of elements from the end of the list, and moves them to a new list.
/// 
/// Returns the modified list and the list of taken elements.
/// 
/// ### Examples
/// ```
/// take_and_split([1, 2, 3, 4], 1)
/// // -> #([1, 2, 3], [4])
/// take_and_split([1, 2, 3, 4], 5)
/// // -> #([], [1, 2, 3, 4])
/// ```
pub fn take_and_split(a, amount) {
  list.split(a, int.max(0, list.length(a) - amount))
}

pub fn float_modulo(a: Float, b: Float) -> Float {
  // TODO:
  // > 1000000000000001 2 %
  // 1
  // > 10000000000000001 2 %
  // 0

  a -. { b *. float.floor(a /. b) }
}
