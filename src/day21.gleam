import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import rememo/memo
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

pub type Pad {
  NumPad
  DirPad
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
  let numpad_paths = cache_paths(loc2numpad)

  let loc2dpad: Dict(Coord, String) =
    [["#", "^", "A"], ["<", "v", ">"]]
    |> list.index_map(fn(line, y) {
      line |> list.index_map(fn(c, x) { #(Coord(x, y), c) })
    })
    |> list.flatten
    |> dict.from_list
  let dpad2loc: Dict(String, Coord) = loc2dpad |> invert_dict
  let dpad_paths = cache_paths(loc2dpad)

  let start_numpad = Coord(2, 3)
  let start_dpad = Coord(2, 0)

  io.print("Part 1: ")
  use cache <- memo.create()
  seqs
  |> list.take(1)
  |> list.map(fn(num_seq) {
    press_pad(
      num_seq,
      start_numpad,
      loc2numpad,
      numpad2loc,
      NumPad,
      numpad_paths,
    )
    |> list.map(fn(lseq) {
      lseq
      |> list.map(fn(s) {
        min_len(s, 0, start_dpad, loc2dpad, dpad2loc, dpad_paths, cache)
      })
      |> list.fold(1_000_000_000, int.min)
    })
    |> list.fold(0, int.add)
    |> complexity(num_seq, _)
  })
  |> list.fold(0, int.add)
  |> io.debug
}

fn min_len(
  seq: List(String),
  level: Int,
  start_dpad: Coord,
  loc2dpad: Dict(Coord, String),
  dpad2loc: Dict(String, Coord),
  dpad_paths: Dict(#(Coord, Coord), List(List(List(String)))),
  cache,
) -> Int {
  use <- bool.guard(level == 0, list.length(seq))

  use <- memo.memoize(cache, #(seq, level))

  press_pad(seq, start_dpad, loc2dpad, dpad2loc, DirPad, dpad_paths)
  |> io.debug
  |> list.map(fn(dpad_seq) {
    dpad_seq
    |> list.map(fn(s) {
      min_len(s, level - 1, start_dpad, loc2dpad, dpad2loc, dpad_paths, cache)
    })
    |> list.fold(0, int.add)
    // |> io.debug
  })
  |> list.fold(100_000_000, int.min)
  // |> list.fold(0, int.add)
}

fn press_pad(
  seq: List(String),
  start: Coord,
  loc2pad: Dict(Coord, String),
  pad2loc: Dict(String, Coord),
  pad: Pad,
  all_paths: Dict(#(Coord, Coord), List(List(List(String)))),
) -> List(List(List(String))) {
  use <- bool.guard(seq == [], [[[]]])

  let assert [key, ..rest] = seq
  let assert Ok(goal) = pad2loc |> dict.get(key)

  let seqs: List(List(List(String))) =
    all_paths |> dict.get(#(start, goal)) |> result.unwrap([[[]]])
  let new_press_seqs: List(List(List(String))) =
    press_pad(rest, goal, loc2pad, pad2loc, pad, all_paths)

  seqs
  |> list.flat_map(fn(ap) {
    new_press_seqs
    |> list.map(fn(np) {
      case rest == [] {
        True ->
          [[[ap, [["A"]]] |> list.flatten |> list.flatten]] |> list.flatten
        False ->
          [[[ap, [["A"]]] |> list.flatten |> list.flatten], np] |> list.flatten
      }
    })
  })
}

fn cache_paths(
  pad: Dict(Coord, String),
) -> Dict(#(Coord, Coord), List(List(List(String)))) {
  pad
  |> dict.keys
  |> list.combinations(2)
  |> list.map(fn(p) {
    let assert [p1, p2] = p
    [p, [p2, p1]]
  })
  |> list.flatten
  |> list.map(fn(p) {
    let assert [s, e] = p
    let paths =
      get_paths(pad, s, e, l1_dist(s, e), [s], [], set.from_list([s]))
      |> list.map(fn(llst) { llst |> list.map(path2dpad) })
    #(#(s, e), paths)
  })
  |> dict.from_list
}

fn get_paths(
  pad: Dict(Coord, String),
  start: Coord,
  goal: Coord,
  target_cost: Int,
  path: List(Coord),
  paths: List(List(Coord)),
  visited: Set(Coord),
) -> List(List(List(Coord))) {
  // #(goal, path) |> io.debug
  use <- bool.guard(start == goal, [[path |> list.reverse, ..paths]])
  use <- bool.guard(list.length(path) > target_cost, [paths])

  [E, S, W, N]
  |> list.map(fn(dir) {
    let next = move(start, dir)
    use <- bool.guard(visited |> set.contains(next), [paths])
    use <- bool.guard(!dict.has_key(pad, next), [paths])
    let assert Ok(key) = pad |> dict.get(next)
    use <- bool.guard(key == "#", [paths])
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
  |> list.filter(fn(x) { !list.is_empty(x) })
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

fn complexity(code: List(String), min_seq_len: Int) -> Int {
  let assert Ok(code_num) =
    int.parse(code |> string.join("") |> string.slice(0, list.length(code) - 1))
  min_seq_len * code_num
}

fn invert_dict(d: Dict(a, b)) -> Dict(b, a) {
  d
  |> dict.to_list
  |> list.map(fn(tup) { #(tup.1, tup.0) })
  |> dict.from_list
}
