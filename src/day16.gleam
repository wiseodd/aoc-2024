import gleam/bool
import gleam/dict.{type Dict}
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
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

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day16_input.txt")
  // let assert Ok(content) = simplifile.read("data/day16_input_toy.txt")
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

  let reindeer = Reindeer(loc: maze |> find("S"), dir: E)
  let goal = maze |> find("E")

  io.print("Part 1: ")
  maze
  |> explore(reindeer, goal, 0, [])
  |> pair.first
  |> io.debug
}

fn explore(
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
            explore(maze, Reindeer(next_loc, next_dir), goal, new_cost, memo)
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
