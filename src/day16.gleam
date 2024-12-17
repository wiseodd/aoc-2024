import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleamy/pairing_heap.{type Heap}
import gleamy/priority_queue as pq
import simplifile

const large_num = 10_000_000_000

pub type Dir {
  E
  S
  W
  N
}

pub type Coord {
  Coord(x: Int, y: Int)
}

pub type Reindeer {
  Reindeer(loc: Coord, dir: Dir)
}

pub type Vertex {
  Vertex(loc: Coord, dir: Dir)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day16_input.txt")

  let maze: Dict(Coord, String) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, y) {
      line
      |> string.trim
      |> string.to_graphemes
      |> list.index_map(fn(char, x) { #(Coord(x, y), char) })
    })
    |> list.flatten
    |> dict.from_list

  let start = Vertex(loc: maze |> find("S"), dir: E)
  let goal = maze |> find("E")

  let #(best_cost, n_best_nodes) =
    maze
    |> dijkstra(start, goal)

  io.print("Part 1: ")
  best_cost |> io.debug

  io.print("Part 2: ")
  n_best_nodes |> io.debug
}

fn dijkstra(
  maze: Dict(Coord, String),
  start: Vertex,
  goal: Coord,
) -> #(Int, Int) {
  let graph: List(Vertex) =
    maze
    |> dict.to_list
    |> list.filter_map(fn(tup) {
      let #(loc, obj) = tup
      case obj != "#" {
        True -> Ok([E, S, W, N] |> list.map(fn(dir) { Vertex(loc, dir) }))
        False -> Error(Nil)
      }
    })
    |> list.flatten

  let frontier: Heap(#(Vertex, Int)) =
    pq.from_list([#(start, 0)], fn(v1: #(Vertex, Int), v2: #(Vertex, Int)) {
      int.compare(v1.1, v2.1)
    })

  let costs: Dict(Vertex, Int) =
    graph
    |> list.map(fn(v) {
      let d = case v == start {
        True -> 0
        False -> large_num
      }
      #(v, d)
    })
    |> dict.from_list

  let prevs: Dict(Vertex, Set(Vertex)) = dict.from_list([])

  let #(_, costs, prevs) = do_dijkstra(start, goal, frontier, costs, prevs)

  let best_cost =
    costs
    |> dict.to_list
    |> list.filter_map(fn(tup) {
      let #(v, d) = tup
      case v.loc == goal {
        True -> Ok(d)
        False -> Error(Nil)
      }
    })
    |> list.fold(large_num, int.min)

  let assert [goal] =
    costs
    |> dict.to_list
    |> list.filter_map(fn(tup) {
      let #(v, cost) = tup
      case v.loc == goal && cost == best_cost {
        True -> Ok(v)
        False -> Error(Nil)
      }
    })

  let n_best_nodes =
    backtrace(goal, start, prevs)
    |> list.map(fn(v) { v.loc })
    |> list.unique
    |> list.length

  #(best_cost, n_best_nodes)
}

fn backtrace(
  goal: Vertex,
  start: Vertex,
  prevs: Dict(Vertex, Set(Vertex)),
) -> List(Vertex) {
  case goal == start {
    True -> [start]
    False -> {
      let assert Ok(vs) = prevs |> dict.get(goal)
      let prev_nodes =
        vs
        |> set.to_list
        |> list.map(fn(v) { backtrace(v, start, prevs) })
        |> list.flatten
      [goal, ..prev_nodes]
    }
  }
}

fn do_dijkstra(
  start: Vertex,
  goal: Coord,
  frontier: Heap(#(Vertex, Int)),
  costs: Dict(Vertex, Int),
  prevs: Dict(Vertex, Set(Vertex)),
) -> #(Heap(#(Vertex, Int)), Dict(Vertex, Int), Dict(Vertex, Set(Vertex))) {
  case frontier |> pq.is_empty {
    True -> #(frontier, costs, prevs)
    False -> {
      // Pick a node from the frontier with min cost
      let assert Ok(#(#(curr_node, _), frontier)) = frontier |> pq.pop
      let Vertex(loc, dir) = curr_node
      let assert Ok(curr_cost) = costs |> dict.get(curr_node)

      let #(frontier, costs, prevs) =
        // Check all possible actions = { forward, rotate CW, rotate CCW }
        // each associated with an intermediate cost
        [#(dir, 1), #(dir |> rotate_cw, 1000), #(dir |> rotate_ccw, 1000)]
        |> list.map_fold(#(frontier, costs, prevs), fn(memo, tup) {
          let #(new_dir, action_cost) = tup
          let new_cost = curr_cost + action_cost

          // Get the new node by following the action
          let v = case new_dir == dir {
            True -> Vertex(loc |> move(dir), dir)
            False -> Vertex(loc, new_dir)
          }

          // If the new node is valid (not a wall, not outside maze)
          // and if the current path's cost is lower than previous one,
          // put that new node into the frontier
          let #(frontier, costs, prevs) = case costs |> dict.get(v) {
            Ok(v_cost) ->
              case new_cost < v_cost {
                True -> #(
                  memo.0 |> pq.push(#(v, new_cost)),
                  memo.1 |> dict.upsert(v, fn(_) { new_cost }),
                  memo.2
                    |> dict.upsert(v, fn(maybe_set) {
                      case maybe_set {
                        Some(s) -> s |> set.insert(curr_node)
                        None -> set.from_list([curr_node])
                      }
                    }),
                )
                // Alternative path: doesn't matter for the frontier list
                // but add to previous nodes list so we can backtrace along
                _ if new_cost == v_cost -> #(
                  memo.0,
                  memo.1,
                  memo.2
                    |> dict.upsert(v, fn(maybe_set) {
                      case maybe_set {
                        Some(s) -> s |> set.insert(curr_node)
                        None -> set.from_list([curr_node])
                      }
                    }),
                )
                False -> memo
              }
            Error(Nil) -> memo
          }

          // The second element doesn't matter
          #(#(frontier, costs, prevs), -1)
        })
        |> pair.first

      do_dijkstra(start, goal, frontier, costs, prevs)
    }
  }
}

fn find(maze: Dict(Coord, String), obj: String) -> Coord {
  maze
  |> dict.to_list
  |> list.find(fn(tup) { tup.1 == obj })
  |> result.unwrap(#(Coord(-1, -1), obj))
  |> pair.first
}

fn move(loc: Coord, dir: Dir) -> Coord {
  case dir {
    E -> Coord(loc.x + 1, loc.y)
    S -> Coord(loc.x, loc.y + 1)
    W -> Coord(loc.x - 1, loc.y)
    N -> Coord(loc.x, loc.y - 1)
  }
}

fn rotate_cw(dir: Dir) -> Dir {
  case dir {
    E -> S
    S -> W
    W -> N
    N -> E
  }
}

fn rotate_ccw(dir: Dir) -> Dir {
  case dir {
    E -> N
    N -> W
    W -> S
    S -> E
  }
}
