import gleam/bool
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

  io.print("Num \"XMAS\": ")
  io.debug(flat_matrix |> count_xmas)

  io.print("Num \"X-MAS\": ")
  io.debug(flat_matrix |> count_x_mas)
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
    |> list.map(fn(dir) { get_string(flat_matrix, i, j, dir, 4, "") })
    |> list.filter(fn(str) { str == "XMAS" })
    |> list.length
  })
  |> list.fold(0, int.add)
}

fn count_x_mas(flat_matrix: Dict(#(Int, Int), String)) -> Int {
  let a_list =
    flat_matrix
    |> dict.filter(fn(_, val) { val == "A" })
    |> dict.to_list

  a_list
  |> list.map(fn(a) {
    let #(#(i, j), _) = a

    let first_cross: String =
      [SE, NW]
      |> list.map(fn(dir) {
        get_string(flat_matrix, i, j, dir, 2, "") |> string.drop_start(1)
      })
      |> string.concat

    let second_cross: String =
      [SW, NE]
      |> list.map(fn(dir) {
        get_string(flat_matrix, i, j, dir, 2, "") |> string.drop_start(1)
      })
      |> string.concat

    {
      { first_cross == "MS" || first_cross == "SM" }
      && { second_cross == "MS" || second_cross == "SM" }
    }
    |> bool.to_int
  })
  |> list.fold(0, int.add)
}

fn get_string(
  flat_matrix: Dict(#(Int, Int), String),
  i: Int,
  j: Int,
  dir: Direction,
  len: Int,
  res: String,
) -> String {
  // "@" is just a dummy
  let new_res =
    res <> { flat_matrix |> dict.get(#(i, j)) |> result.unwrap("@") }
  let new_res_len = new_res |> string.length
  case dir {
    _ if new_res_len == len -> new_res
    E -> get_string(flat_matrix, i, j + 1, dir, len, new_res)
    SE -> get_string(flat_matrix, i + 1, j + 1, dir, len, new_res)
    S -> get_string(flat_matrix, i + 1, j, dir, len, new_res)
    SW -> get_string(flat_matrix, i + 1, j - 1, dir, len, new_res)
    W -> get_string(flat_matrix, i, j - 1, dir, len, new_res)
    NW -> get_string(flat_matrix, i - 1, j - 1, dir, len, new_res)
    N -> get_string(flat_matrix, i - 1, j, dir, len, new_res)
    NE -> get_string(flat_matrix, i - 1, j + 1, dir, len, new_res)
  }
}
