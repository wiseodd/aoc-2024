import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
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
  let assert Ok(content) = simplifile.read("data/day20_input.txt")

  let maze: Dict(Coord, String) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, y) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(c, x) { #(Coord(x, y), c) })
    })
    |> list.flatten
    |> dict.from_list
  let assert [#(start, _)] =
    maze |> dict.to_list |> list.filter(fn(tup) { tup.1 == "S" })
  let assert [#(goal, _)] =
    maze |> dict.to_list |> list.filter(fn(tup) { tup.1 == "E" })

  let path = get_path(maze, start, goal, [start])
  let path2idx =
    path
    |> list.index_map(fn(loc, idx) { #(loc, idx) })
    |> dict.from_list

  io.print("Part 1: ")
  path |> count_cheats(path2idx, 2, 100) |> io.debug

  io.print("Part 2: ")
  path |> count_cheats(path2idx, 20, 100) |> io.debug
}

fn count_cheats(
  path: List(Coord),
  path2idx: Dict(Coord, Int),
  max_l1: Int,
  min_saving: Int,
) -> Int {
  path
  |> list.index_map(fn(loc, i) {
    path
    |> list.drop(i + 1)
    |> list.map(fn(next_loc) {
      let l1 = l1_dist(loc, next_loc)
      use <- bool.guard(l1 > max_l1, 0)
      let assert Ok(dist_start) = path2idx |> dict.get(loc)
      let assert Ok(dist_end) = path2idx |> dict.get(next_loc)
      dist_end - dist_start - l1
    })
  })
  |> list.flatten
  |> list.filter(fn(x) { x > 1 })
  |> list.group(fn(x) { x })
  |> dict.map_values(fn(_, v) { v |> list.length })
  |> dict.fold(0, fn(acc, k, v) {
    use <- bool.guard(k < min_saving, acc + 0)
    acc + v
  })
}

fn get_path(
  maze: Dict(Coord, String),
  start: Coord,
  goal: Coord,
  visited: List(Coord),
) -> List(Coord) {
  use <- bool.guard(start == goal, visited |> list.reverse)
  [E, S, W, N]
  |> list.map(fn(dir) {
    let next = move(start, dir)
    use <- bool.guard(visited |> list.contains(next), [])
    let assert Ok(obj) = maze |> dict.get(next)
    use <- bool.guard(obj == "#", [])
    get_path(maze, next, goal, [next, ..visited])
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
