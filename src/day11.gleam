import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day11_input.txt")
  let stones: List(Int) =
    content
    |> string.trim
    |> string.split(" ")
    |> list.map(fn(x) {
      let assert Ok(v) = x |> int.parse
      v
    })

  stones |> count(25) |> io.debug
  stones |> count(75) |> io.debug
}

fn count(initial_stones: List(Int), n_blinks: Int) -> Int {
  let memo: Dict(#(Int, Int), Int) = dict.from_list([])
  initial_stones
  |> list.map_fold(#(0, memo), fn(acc, stone) {
    let #(curr_sum, memo) = acc
    let #(res, memo) = stone |> blink(n_blinks, memo)
    #(#(curr_sum, memo), curr_sum + res)
  })
  |> pair.second
  |> list.fold(0, int.add)
}

fn blink(
  stone: Int,
  n: Int,
  memo: Dict(#(Int, Int), Int),
) -> #(Int, Dict(#(Int, Int), Int)) {
  case memo |> dict.get(#(stone, n)) {
    _ if n == 0 -> #(1, memo)
    Ok(val) -> #(val, memo)
    Error(_) -> {
      let len = stone |> int.to_string |> string.length
      let #(res, memo) = case stone {
        0 -> blink(1, n - 1, memo)
        _ if len % 2 == 0 -> {
          let #(digits_l, digits_r) =
            stone
            |> int.to_string
            |> string.to_graphemes
            |> list.split(len / 2)
          let assert Ok(stone_l) = digits_l |> string.join("") |> int.parse
          let assert Ok(stone_r) = digits_r |> string.join("") |> int.parse
          let #(res_l, memo) = blink(stone_l, n - 1, memo)
          let #(res_r, memo) = blink(stone_r, n - 1, memo)
          #(res_l + res_r, memo)
        }
        _ -> blink(stone * 2024, n - 1, memo)
      }
      #(res, memo |> dict.insert(#(stone, n), res))
    }
  }
}
