import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import gleamy/pairing_heap.{type Heap}
import gleamy/priority_queue as pq
import simplifile

pub type Dir {
  E
  S
  W
  N
}

pub type Coord {
  Coord(x: Int, y: Int)
}

pub fn main() {
  // let assert Ok(content) = simplifile.read("data/day21_input.txt")
  let assert Ok(content) = simplifile.read("data/day21_input_toy.txt")

  let seqs: List(List(String)) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(seq) { seq |> string.to_graphemes })

  let loc2numpad: Dict(Coord, String) =
    [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], ["#", "0", "A"]]
    |> list.index_map(fn(line, y) {
      line |> list.index_map(fn(c, x) { #(Coord(x, y), c) })
    })
    |> list.flatten
    |> dict.from_list
  let numpad2loc: Dict(String, Coord) = loc2numpad |> invert_dict

  let loc2dpad: Dict(Coord, String) =
    [["#", "^", "A"], ["<", "v", ">"]]
    |> list.index_map(fn(line, y) {
      line |> list.index_map(fn(c, x) { #(Coord(x, y), c) })
    })
    |> list.flatten
    |> dict.from_list
  let dpad2loc: Dict(String, Coord) = loc2dpad |> invert_dict

  let start_numpad = Coord(2, 3)
  let start_dpad = Coord(2, 0)

  seqs
  |> list.take(1)
  |> list.map(fn(num_seq) {
    let dpad_seqs = press_pad(num_seq, start_numpad, loc2numpad, numpad2loc)
    dpad_seqs
    |> list.map(fn(seq) {
      let len = press_dpad_nested(seq, 1, 0, start_dpad, loc2dpad, dpad2loc)
      // complexity(num_seq, seq)
      len
    })
  })
  // |> list.fold(0, int.add)
  // |> io.debug
}

fn press_dpad_nested(
  seq: List(String),
  level: Int,
  total: Int,
  start_dpad: Coord,
  loc2dpad: Dict(Coord, String),
  dpad2loc: Dict(String, Coord),
) -> Int {
  use <- bool.guard(seq == [], 0)
  let assert [start, ..rest] = seq
  let dpad_seqs = press_pad(seq, start_dpad, loc2dpad, dpad2loc)
  use <- bool.lazy_guard(level == 0, fn() {
    let assert Ok(len) =
      dpad_seqs |> list.map(list.length) |> list.reduce(int.min)
    press_dpad_nested(rest, level, total + len, start_dpad, loc2dpad, dpad2loc)
  })

  let total =
    total
    + list.fold(dpad_seqs, 100_000_000, fn(acc, seq) {
      int.min(
        acc,
        press_dpad_nested(seq, level - 1, total, start_dpad, loc2dpad, dpad2loc),
      )
    })

  press_dpad_nested(rest, level, total, start_dpad, loc2dpad, dpad2loc)
}

fn press_pad(
  seq: List(String),
  start: Coord,
  loc2pad: Dict(Coord, String),
  pad2loc: Dict(String, Coord),
) -> List(List(String)) {
  use <- bool.guard(seq == [], [[]])

  let assert [key, ..rest] = seq
  let assert Ok(goal) = pad2loc |> dict.get(key)
  let dist = l1_dist(start, goal)
  let seqs =
    get_paths(loc2pad, start, goal, dist, [start], [], set.from_list([start]))
    |> list.map(path2dpad)

  let new_press_seqs = press_pad(rest, goal, loc2pad, pad2loc)

  seqs
  |> list.flat_map(fn(ap) {
    new_press_seqs
    |> list.map(fn(np) {
      case rest == [] {
        True -> [ap, np, ["A"]] |> list.flatten
        False -> [ap, ["A"], np] |> list.flatten
      }
    })
  })
}

fn get_paths(
  pad: Dict(Coord, String),
  start: Coord,
  goal: Coord,
  target_cost: Int,
  path: List(Coord),
  paths: List(List(Coord)),
  visited: Set(Coord),
) -> List(List(Coord)) {
  // #(goal, path) |> io.debug
  use <- bool.guard(start == goal, [path |> list.reverse, ..paths])
  use <- bool.guard(list.length(path) > target_cost, paths)

  [E, S, W, N]
  |> list.map(fn(dir) {
    let next = move(start, dir)
    use <- bool.guard(visited |> set.contains(next), paths)
    use <- bool.guard(!dict.has_key(pad, next), paths)
    let assert Ok(key) = pad |> dict.get(next)
    use <- bool.guard(key == "#", paths)
    get_paths(
      pad,
      next,
      goal,
      target_cost,
      [next, ..path],
      paths,
      visited |> set.insert(next),
    )
  })
  |> list.flatten
}

fn l1_dist(loc: Coord, goal: Coord) -> Int {
  int.absolute_value(goal.x - loc.x) + int.absolute_value(goal.y - loc.y)
}

fn move(loc: Coord, dir: Dir) -> Coord {
  case dir {
    E -> Coord(loc.x + 1, loc.y)
    S -> Coord(loc.x, loc.y + 1)
    W -> Coord(loc.x - 1, loc.y)
    N -> Coord(loc.x, loc.y - 1)
  }
}

fn path2dpad(path: List(Coord)) -> List(String) {
  case path {
    [] | [_] -> []
    [curr, next, ..rest] -> {
      let d = case Nil {
        _ if next.x > curr.x -> ">"
        _ if next.x < curr.x -> "<"
        _ if next.y < curr.y -> "^"
        _ -> "v"
      }
      [d, ..path2dpad([next, ..rest])]
    }
  }
}

fn complexity(code: List(String), press_seq: List(String)) -> Int {
  let press_len = press_seq |> list.length
  let assert Ok(code_num) =
    int.parse(code |> string.join("") |> string.slice(0, list.length(code) - 1))
  [press_len, code_num] |> io.debug
  press_len * code_num
}

fn invert_dict(d: Dict(a, b)) -> Dict(b, a) {
  d
  |> dict.to_list
  |> list.map(fn(tup) { #(tup.1, tup.0) })
  |> dict.from_list
}
