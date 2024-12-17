import gleam/bool
import gleam/dict.{type Dict}
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{type Order}
import gleam/pair
import gleam/result
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
  // let assert Ok(content) = simplifile.read("data/day16_input.txt")
  let assert Ok(content) = simplifile.read("data/day16_input_toy.txt")
  // let assert Ok(content) = simplifile.read("data/day16_input_toy2.txt")

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

  io.print("Part 1: ")
  maze
  |> dijkstra(start, goal)
  |> io.debug
}

fn dijkstra(maze: Dict(Coord, String), start: Vertex, goal: Coord) -> Int {
  let graph: List(Vertex) =
    maze
    |> dict.to_list
    |> list.map(fn(tup) {
      let #(loc, _) = tup
      [E, S, W, N] |> list.map(fn(dir) { Vertex(loc, dir) })
    })
    |> list.flatten

  let q: Heap(#(Vertex, Int)) =
    pq.from_list([#(start, 0)], fn(v1: #(Vertex, Int), v2: #(Vertex, Int)) {
      int.compare(v1.1, v2.1)
    })

  let dist: Dict(Vertex, Int) =
    graph
    |> list.map(fn(v) {
      let d = case v == start {
        True -> 0
        False -> large_num
      }
      #(v, d)
    })
    |> dict.from_list

  let #(_, dist) = do_dijkstra(maze, start, goal, q, dist)

  dist
  |> dict.to_list
  |> list.filter_map(fn(tup) {
    let #(v, d) = tup
    case v.loc == goal {
      True -> Ok(d)
      False -> Error(Nil)
    }
  })
  |> list.fold(large_num, int.min)
}

fn do_dijkstra(
  maze: Dict(Coord, String),
  start: Vertex,
  goal: Coord,
  q: Heap(#(Vertex, Int)),
  dist: Dict(Vertex, Int),
) -> #(Heap(#(Vertex, Int)), Dict(Vertex, Int)) {
  case q |> pq.is_empty {
    True -> #(q, dist)
    False -> {
      let assert Ok(#(#(u, _), q)) = q |> pq.pop
      let Vertex(loc, dir) = u
      let assert Ok(u_cost) = dist |> dict.get(u)

      let #(q, dist) =
        [#(dir, 1), #(dir |> rotate_cw, 1000), #(dir |> rotate_ccw, 1000)]
        |> list.map_fold(#(q, dist), fn(memo, tup) {
          let #(new_dir, cost) = tup
          let new_cost = u_cost + cost
          let v = case new_dir == dir {
            True -> Vertex(loc |> move(dir), dir)
            False -> Vertex(loc, new_dir)
          }
          let assert Ok(v_cost) = dist |> dict.get(v)

          let #(new_q, new_dist) = case new_cost < v_cost {
            True -> #(
              memo.0 |> pq.push(#(v, new_cost)),
              memo.1 |> dict.upsert(v, fn(_) { new_cost }),
            )
            False -> memo
          }

          #(#(new_q, new_dist), -1)
        })
        |> pair.first

      do_dijkstra(maze, start, goal, q, dist)
    }
  }
}

fn dfs(
  maze: Dict(Coord, String),
  reindeer: Reindeer,
  goal: Coord,
  total_cost: Int,
  visited: List(Coord),
) -> #(Int, List(Coord)) {
  let loc = reindeer.loc
  let dir = reindeer.dir

  use <- bool.guard(visited |> list.contains(loc), #(large_num, visited))

  let visited = [loc, ..visited]

  case maze |> dict.get(loc) {
    // If wall or out of bound
    Error(_) | Ok("#") -> #(large_num, visited)
    // If goal
    Ok("E") -> #(total_cost, visited)
    // If space, move by minimizing cost of curr action + recursive cost of next loc
    Ok("S") | Ok(".") -> {
      // io.println("Total cost: " <> total_cost |> int.to_string)
      // pretty_print(maze, reindeer)
      // let _ = erlang.get_line("")

      // 1001 for rotate_cw and ccw since it's actually turning + move forward at once
      let #(_, new_costs) =
        [#(dir, 1), #(dir |> rotate_cw, 1001), #(dir |> rotate_ccw, 1001)]
        |> list.map_fold(visited, fn(memo, tup) {
          let #(next_dir, cost) = tup
          let next_loc = loc |> move(next_dir)
          let new_cost = cost + total_cost
          let #(new_cost, _) =
            dfs(maze, Reindeer(next_loc, next_dir), goal, new_cost, memo)
          #([next_loc, ..memo], new_cost)
        })

      // cost |> io.debug

      let assert Ok(min_cost) =
        new_costs |> list.sort(int.compare) |> list.first
      #(min_cost, visited)
    }
    // Unreachable
    _ -> panic
  }
}

fn is_visited(memo: Dict(Coord, Int), loc: Coord) -> #(Bool, Int) {
  case memo |> dict.get(loc) {
    Ok(v) -> #(True, v)
    _ -> #(False, -1)
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

fn update(d: Dict(Coord, a), loc: Coord, obj: a) -> Dict(Coord, a) {
  d
  |> dict.upsert(loc, fn(_) { obj })
}

fn pretty_print(maze: Dict(Coord, String), reindeer: Reindeer) {
  let max = Coord(15, 15)

  // io.println("")

  list.range(0, max.y - 1)
  |> list.each(fn(y) {
    list.range(0, max.x - 1)
    |> list.each(fn(x) {
      case Coord(x, y) == reindeer.loc {
        True ->
          case reindeer.dir {
            E -> ">"
            S -> "v"
            W -> "<"
            N -> "^"
          }
        False -> {
          let assert Ok(obj) = maze |> dict.get(Coord(x, y))
          obj
        }
      }
      |> io.print
    })
    io.println("")
  })
  io.println("")
}
