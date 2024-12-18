import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import gleamy/pairing_heap.{type Heap}
import gleamy/priority_queue as pq
import simplifile

const large_num = 1_000_000_000_000

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
  let assert Ok(content) = simplifile.read("data/day18_input.txt")

  let block_list = content |> string.trim |> string.split("\n")
  let start = Coord(0, 0)
  let goal = Coord(70, 70)
  let n_bytes = 1024

  let grid: Dict(Coord, String) =
    list.range(start.y, goal.y)
    |> list.map(fn(y) {
      list.range(start.x, goal.x)
      |> list.map(fn(x) { #(Coord(x, y), ".") })
    })
    |> list.flatten
    |> dict.from_list

  io.print("Part 1: ")
  block_list |> build_maze(n_bytes, grid) |> a_star(start, goal) |> io.debug

  io.print("Part 2: ")
  block_list
  |> bin_search(1024, list.length(block_list) - 1, 1024, grid, start, goal)
  |> io.println
}

fn build_maze(
  block_list: List(String),
  n_bytes: Int,
  grid: Dict(Coord, String),
) -> Dict(Coord, String) {
  block_list
  |> list.map(fn(line) {
    let assert [x, y] = line |> string.trim |> string.split(",")
    let assert Ok(x) = x |> int.parse
    let assert Ok(y) = y |> int.parse
    Coord(x, y)
  })
  |> list.take(n_bytes)
  |> list.map_fold(grid, fn(memo, xy) {
    #(memo |> dict.upsert(xy, fn(_) { "#" }), Nil)
  })
  |> pair.first
}

fn a_star(maze: Dict(Coord, String), start: Coord, goal: Coord) -> Int {
  let frontier: Heap(#(Coord, Int)) =
    pq.from_list(
      [#(start, heuristic(start, goal))],
      fn(v1: #(Coord, Int), v2: #(Coord, Int)) { int.compare(v1.1, v2.1) },
    )

  let costs: Dict(Coord, Int) =
    maze
    |> dict.filter(fn(_, v) { v != "#" })
    |> dict.map_values(fn(k, _) {
      use <- bool.guard(k == start, 0)
      large_num
    })

  let #(_, costs) = do_a_star(maze, start, goal, frontier, costs)

  let best_cost =
    costs
    |> dict.to_list
    |> list.filter_map(fn(tup) {
      let #(v, d) = tup
      case v == goal {
        True -> Ok(d)
        False -> Error(Nil)
      }
    })
    |> list.fold(large_num, int.min)

  best_cost
}

fn do_a_star(
  maze: Dict(Coord, String),
  start: Coord,
  goal: Coord,
  frontier: Heap(#(Coord, Int)),
  costs: Dict(Coord, Int),
) -> #(Heap(#(Coord, Int)), Dict(Coord, Int)) {
  use <- bool.guard(frontier |> pq.is_empty, #(frontier, costs))

  let assert Ok(#(#(curr_node, _), frontier)) = frontier |> pq.pop
  let assert Ok(curr_cost) = costs |> dict.get(curr_node)

  let #(frontier, costs) =
    [#(E, 1), #(S, 1), #(W, 1), #(N, 1)]
    |> list.map_fold(#(frontier, costs), fn(memo, tup) {
      let #(action, action_cost) = tup
      let next_node = curr_node |> move(action)
      let new_cost = curr_cost + action_cost

      let #(frontier, costs) = case costs |> dict.get(next_node) {
        Ok(cost) -> {
          use <- bool.guard(new_cost >= cost, memo)
          #(
            memo.0
              |> pq.push(#(next_node, new_cost + heuristic(next_node, goal))),
            memo.1 |> dict.upsert(next_node, fn(_) { new_cost }),
          )
        }
        Error(Nil) -> memo
      }

      #(#(frontier, costs), -1)
    })
    |> pair.first

  do_a_star(maze, start, goal, frontier, costs)
}

fn heuristic(loc: Coord, goal: Coord) -> Int {
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

fn bin_search(
  block_list: List(String),
  min: Int,
  max: Int,
  result: Int,
  grid: Dict(Coord, String),
  start: Coord,
  goal: Coord,
) -> String {
  use <- bool.guard(
    min >= max,
    block_list
      |> list.drop(result - 1)
      |> list.first
      |> result.unwrap("Not found"),
  )

  let assert Ok(mid) = int.floor_divide(min + max, 2)
  let shortest_path =
    block_list |> build_maze(mid + 1, grid) |> a_star(start, goal)

  case shortest_path != large_num {
    True -> bin_search(block_list, mid + 1, max, result, grid, start, goal)
    False -> bin_search(block_list, min, mid - 1, mid + 1, grid, start, goal)
  }
}
