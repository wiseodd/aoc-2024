import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  // let assert Ok(content) = simplifile.read("data/day19_input.txt")
  let assert Ok(content) = simplifile.read("data/day19_input_toy.txt")

  let assert [pattern_str, design_str] =
    content |> string.trim |> string.split("\n\n")
  let patterns = pattern_str |> string.trim |> string.split(", ")
  let designs = design_str |> string.trim |> string.split("\n")

  let #(#(_, memo2), results) =
    designs
    |> list.map_fold(
      #(dict.from_list([]), dict.from_list([])),
      fn(memos, design) {
        let #(memo, memo2) = memos
        let #(memo, memo2, possible) =
          is_possible(design, design, patterns, memo, memo2)
        #(#(memo, memo2), possible)
      },
    )

  io.print("Part 1: ")
  results
  |> list.map(bool.to_int)
  |> list.fold(0, int.add)
  |> io.debug

  io.print("Part 2: ")
  list.zip(designs, results)
  |> list.fold(0, fn(acc, tup) {
    let #(design, possible) = tup
    use <- bool.guard(!possible, acc)
    let n = memo2 |> dict.get(design) |> result.unwrap(0)
    acc + n
  })
  |> io.debug
}

fn is_possible(
  design: String,
  original_design: String,
  patterns: List(String),
  memo: Dict(#(String, String), Bool),
  memo2: Dict(String, Int),
) -> #(Dict(#(String, String), Bool), Dict(String, Int), Bool) {
  use <- bool.lazy_guard(string.length(design) == 0, fn() {
    let memo2 =
      memo2
      |> dict.upsert(original_design, fn(mv) {
        case mv {
          Some(v) -> v + 1
          None -> 1
        }
      })
    #(memo, memo2, True)
  })

  let #(#(memo, memo2), results) =
    patterns
    |> list.map_fold(#(memo, memo2), fn(memos, pattern) {
      let #(memo, memo2) = memos

      use <- bool.guard(!string.starts_with(design, pattern), #(
        #(memo, memo2),
        False,
      ))

      case memo |> dict.get(#(design, pattern)) {
        Ok(val) -> #(#(memo, memo2), val)
        Error(Nil) -> {
          let #(memo, memo2, res) =
            is_possible(
              design |> string.drop_start(pattern |> string.length),
              original_design,
              patterns,
              memo,
              memo2,
            )
          let memo = memo |> dict.upsert(#(design, pattern), fn(_) { res })
          #(#(memo, memo2), res)
        }
      }
    })

  #(memo, memo2, results |> list.fold(False, bool.or))
}
