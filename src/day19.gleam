import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day19_input.txt")

  let assert [pattern_str, design_str] =
    content |> string.trim |> string.split("\n\n")
  let patterns = pattern_str |> string.trim |> string.split(", ")
  let designs = design_str |> string.trim |> string.split("\n")

  let #(_, results) =
    designs
    |> list.map_fold(dict.from_list([]), fn(memo, design) {
      count(design, design, patterns, memo)
    })

  io.print("Part 1: ")
  results
  |> list.fold(0, fn(acc, x) { acc + bool.to_int(x > 0) })
  |> io.debug

  io.print("Part 2: ")
  results
  |> list.fold(0, int.add)
  |> io.debug
}

fn count(
  design: String,
  original_design: String,
  patterns: List(String),
  memo: Dict(String, Int),
) -> #(Dict(String, Int), Int) {
  use <- bool.guard(design == "", #(memo, 1))
  use <- bool.guard(memo |> dict.has_key(design), #(
    memo,
    memo |> dict.get(design) |> result.unwrap(0),
  ))

  let #(memo, results) =
    patterns
    |> list.map_fold(memo, fn(memo, pattern) {
      use <- bool.guard(!string.starts_with(design, pattern), #(memo, 0))
      count(
        design |> string.drop_start(pattern |> string.length),
        original_design,
        patterns,
        memo,
      )
    })

  let res = results |> list.fold(0, int.add)
  let memo = memo |> dict.insert(design, res)
  #(memo, res)
}
