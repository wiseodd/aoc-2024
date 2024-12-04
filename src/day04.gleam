import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Direction {
  E
  SE
  S
  SW
  W
  NW
  N
  NE
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day04_input.txt")
  // let assert Ok(content) = simplifile.read("data/day04_input_toy1.txt")
  let word_search: List(List(String)) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(line: String) -> List(String) { line |> string.to_graphemes })

  let flat_matrix: Dict(#(Int, Int), String) =
    word_search
    |> list.index_map(fn(line: List(String), i: Int) {
      line
      |> list.index_map(fn(char: String, j: Int) -> #(Int, String) {
        #(j, char)
      })
      |> list.map(fn(v) { #(#(i, v.0), v.1) })
    })
    |> list.flatten
    |> dict.from_list

  io.debug(flat_matrix |> count_xmas)
}

fn count_xmas(flat_matrix: Dict(#(Int, Int), String)) -> Int {
  let xs =
    flat_matrix
    |> dict.filter(fn(_, val) { val == "X" })
    |> dict.to_list

  xs
  |> list.map(fn(x) {
    let #(#(i, j), _) = x

    [E, SE, S, SW, W, NW, N, NE]
    |> list.map(fn(dir) { get_string(flat_matrix, i, j, dir, "") })
    |> list.filter(fn(str) { str == "XMAS" })
    |> list.length
  })
  |> list.fold(0, int.add)
}

fn get_string(
  flat_matrix: Dict(#(Int, Int), String),
  i: Int,
  j: Int,
  dir: Direction,
  res: String,
) -> String {
  // "@" is just a dummy
  let new_res =
    res <> { flat_matrix |> dict.get(#(i, j)) |> result.unwrap("@") }
  let len = new_res |> string.length
  case dir {
    _ if len >= 4 -> new_res
    E -> get_string(flat_matrix, i, j + 1, dir, new_res)
    SE -> get_string(flat_matrix, i + 1, j + 1, dir, new_res)
    S -> get_string(flat_matrix, i + 1, j, dir, new_res)
    SW -> get_string(flat_matrix, i + 1, j - 1, dir, new_res)
    W -> get_string(flat_matrix, i, j - 1, dir, new_res)
    NW -> get_string(flat_matrix, i - 1, j - 1, dir, new_res)
    N -> get_string(flat_matrix, i - 1, j, dir, new_res)
    NE -> get_string(flat_matrix, i - 1, j + 1, dir, new_res)
  }
}
