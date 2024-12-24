import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day24_input.txt")
  // let assert Ok(content) = simplifile.read("data/day24_input_toy.txt")

  let assert [init_str, op_str] = content |> string.trim |> string.split("\n\n")

  let cache: Dict(String, Bool) =
    init_str
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [cable, val] = line |> string.split(": ")
      let val = case val {
        "1" -> True
        _ -> False
      }
      #(cable, val)
    })
    |> dict.from_list

  let eqs: Dict(String, String) =
    op_str
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [eq, wire] = line |> string.split(" -> ")
      #(wire, eq)
    })
    |> dict.from_list

  io.print("Part 1: ")
  let cache =
    eqs
    |> dict.keys
    |> list.fold(cache, fn(memo, wire) {
      compute(wire, eqs, memo) |> pair.first
    })
  eqs
  |> dict.keys
  |> list.filter(fn(wire) { wire |> string.starts_with("z") })
  |> list.sort(string.compare)
  |> list.reverse
  |> list.map(fn(wire) { cache |> get(wire) |> bool.to_int |> int.to_string })
  |> string.join("")
  |> int.base_parse(2)
  |> result.unwrap(-1)
  |> io.debug

  io.print("Part 2: ")
  eqs
  |> dict.keys
  |> list.filter(fn(wire) { is_faulty(wire, eqs) })
  |> list.sort(string.compare)
  |> string.join(",")
  |> io.debug
}

fn is_faulty(wire: String, eqs: Dict(String, String)) -> Bool {
  let assert [lhs, op, rhs] = eqs |> get(wire) |> string.split(" ")

  use <- bool.guard(
    string.starts_with(wire, "z") && wire != "z45" && op != "XOR",
    True,
  )

  use <- bool.guard(
    op == "XOR"
      && !string.starts_with(wire, "z")
      && !{ string.starts_with(lhs, "x") || string.starts_with(lhs, "y") }
      && !{ string.starts_with(rhs, "x") || string.starts_with(rhs, "y") },
    True,
  )

  let is_input_of_or =
    0
    < {
      eqs
      |> dict.filter(fn(_, v) {
        let assert [lhs, op, rhs] = v |> string.split(" ")
        op == "OR" && { lhs == wire || rhs == wire }
      })
      |> dict.size
    }
  use <- bool.guard(is_input_of_or && op != "AND", True)
  use <- bool.guard(
    !is_input_of_or
      && op == "AND"
      && !{
      { lhs == "x00" && rhs == "y00" } || { lhs == "y00" && rhs == "x00" }
    },
    True,
  )

  False
}

fn compute(
  wire: String,
  eqs: Dict(String, String),
  cache: Dict(String, Bool),
) -> #(Dict(String, Bool), Bool) {
  use <- bool.lazy_guard(cache |> dict.has_key(wire), fn() {
    #(cache, cache |> get(wire))
  })

  let assert [lhs, op, rhs] = eqs |> get(wire) |> string.split(" ")

  let #(cache, lhs) = compute(lhs, eqs, cache)
  let #(cache, rhs) = compute(rhs, eqs, cache)
  let res = case op {
    "AND" -> lhs |> bool.and(rhs)
    "OR" -> lhs |> bool.or(rhs)
    _ -> lhs |> bool.exclusive_or(rhs)
  }
  let cache = cache |> dict.insert(wire, res)

  #(cache, res)
}

fn get(tab: Dict(a, b), key: a) -> b {
  let assert Ok(val) = tab |> dict.get(key)
  val
}
