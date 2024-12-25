import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

const max_height = 5

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day25_input.txt")

  let keylocks: Dict(String, List(List(Int))) =
    content
    |> string.trim
    |> string.split("\n\n")
    |> list.group(fn(schematic) {
      use <- bool.guard(schematic |> is_lock, "lock")
      "key"
    })
    |> dict.map_values(fn(k, vals) {
      vals
      |> list.map(fn(schematic) {
        case k == "lock" {
          True -> schematic |> parse_lock
          False -> schematic |> parse_key
        }
      })
    })
  let locks: List(List(Int)) = keylocks |> dict.get("lock") |> result.unwrap([])
  let keys: List(List(Int)) = keylocks |> dict.get("key") |> result.unwrap([])

  io.print("Part 1: ")
  locks
  |> list.fold(0, fn(tot, lock) {
    tot
    + {
      keys
      |> list.fold(0, fn(subtot, key) {
        subtot + bool.to_int(is_fit(lock, key))
      })
    }
  })
  |> io.debug
}

fn is_fit(lock: List(Int), key: List(Int)) -> Bool {
  list.map2(lock, key, int.add) |> list.all(fn(h) { h <= max_height })
}

fn is_lock(schematic: String) -> Bool {
  let assert [first, ..] = schematic |> string.split("\n")
  first |> string.to_graphemes |> list.all(fn(s) { s == "#" })
}

fn parse_lock(schematic: String) -> List(Int) {
  schematic |> string.split("\n") |> parse
}

fn parse_key(schematic: String) -> List(Int) {
  schematic |> string.split("\n") |> list.reverse |> parse
}

fn parse(schematic: List(String)) -> List(Int) {
  schematic
  |> list.drop(1)
  |> list.fold([0, 0, 0, 0, 0], fn(memo, line) {
    let arr =
      line
      |> string.to_graphemes
      |> list.map(fn(s) {
        use <- bool.guard(s == "#", 1)
        0
      })
    list.map2(memo, arr, int.add)
  })
}
