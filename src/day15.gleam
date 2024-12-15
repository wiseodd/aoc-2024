import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import simplifile

pub type Coord {
  Coord(x: Int, y: Int)
}

pub type Dir {
  E
  S
  W
  N
}

pub type Object {
  Robot
  Box
  BoxL
  BoxR
  Wall
  Space
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day15_input.txt")

  let assert [map_str, moves_str] =
    content |> string.trim |> string.split("\n\n")

  io.print("Part 1: ")
  map_str
  |> simulate(moves_str)
  |> total_gps
  |> io.debug

  io.print("Part 2: ")
  map_str
  |> string.replace("#", "##")
  |> string.replace(".", "..")
  |> string.replace("O", "[]")
  |> string.replace("@", "@.")
  |> simulate(moves_str)
  |> total_gps
  |> io.debug
}

fn simulate(map_str: String, moves_str: String) -> Dict(Coord, Object) {
  let warehouse: Dict(Coord, Object) =
    map_str
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, y) {
      line
      |> string.trim
      |> string.to_graphemes
      |> list.index_map(fn(c, x) {
        let obj = case c {
          "#" -> Wall
          "O" -> Box
          "[" -> BoxL
          "]" -> BoxR
          "@" -> Robot
          _ -> Space
        }
        #(Coord(x, y), obj)
      })
    })
    |> list.flatten
    |> dict.from_list

  let assert Ok(robot_loc) =
    warehouse
    |> dict.to_list
    |> list.find_map(fn(tup) {
      let #(coord, obj) = tup
      case obj {
        Robot -> Ok(coord)
        _ -> Error(Nil)
      }
    })

  let moves =
    moves_str
    |> string.to_graphemes
    |> list.filter(fn(c) { c != "\n" })
    |> list.map(fn(char) {
      case char {
        ">" -> E
        "v" -> S
        "<" -> W
        _ -> N
      }
    })

  moves
  |> list.map_fold(#(warehouse, robot_loc), fn(memo, dir) {
    let memo = move(dir, memo.0, memo.1)
    #(memo, dir)
  })
  |> pair.first
  |> pair.first
}

fn move(
  dir: Dir,
  wh: Dict(Coord, Object),
  loc: Coord,
) -> #(Dict(Coord, Object), Coord) {
  // let Ok(obj_prev) = wh |> dict.get(case Dir)

  let assert Ok(obj) = wh |> dict.get(loc)
  let loc_next = loc |> get_next_loc(dir)
  let assert Ok(obj_next) = wh |> dict.get(loc_next)

  // #(dir, obj, loc_next, obj_next) |> io.debug

  case obj_next {
    Wall -> #(wh, loc)
    Space -> #(wh |> update(loc, Space) |> update(loc_next, obj), loc_next)
    _ if dir == E || dir == W -> {
      let #(wh_next, _) = move(dir, wh, loc_next)
      case wh_next |> dict.get(loc_next) {
        // Move if new space opened up
        Ok(Space) -> move(dir, wh_next, loc)
        // Otherwise don't move, return the state as is
        _ -> #(wh_next, loc)
      }
    }
    Box -> {
      let #(wh_next, _) = move(dir, wh, loc_next)
      case wh_next |> dict.get(loc_next) {
        // Move if new space opened up
        Ok(Space) -> move(dir, wh_next, loc)
        // Otherwise don't move, return the state as is
        _ -> #(wh_next, loc)
      }
    }
    BoxL -> {
      // Hypothetically move both [ and ]
      let loc_pair = loc_next |> get_next_loc(E)
      let #(_, loc_nn_l) = move(dir, wh, loc_next)
      let #(_, loc_nn_r) = move(dir, wh, loc_next |> get_next_loc(E))

      // Can *both* of them move? If so, move both of them.
      let wh_next = case loc_nn_l != loc_next && loc_nn_r != loc_pair {
        True -> {
          let #(wh_next, _) = move(dir, wh, loc_next)
          let #(wh_next, _) = move(dir, wh_next, loc_pair)
          wh_next
        }
        False -> wh
      }

      case wh_next |> dict.get(loc_next) {
        Ok(Space) -> move(dir, wh_next, loc)
        _ -> #(wh_next, loc)
      }
    }
    BoxR -> {
      // Hypothetically move both [ and ]
      let loc_pair = loc_next |> get_next_loc(W)
      let #(_, loc_nn_l) = move(dir, wh, loc_next)
      let #(_, loc_nn_r) = move(dir, wh, loc_next |> get_next_loc(W))

      // Can *both* of them move? If so, move both of them.
      let wh_next = case loc_nn_l != loc_next && loc_nn_r != loc_pair {
        True -> {
          let #(wh_next, _) = move(dir, wh, loc_next)
          let #(wh_next, _) = move(dir, wh_next, loc_pair)
          wh_next
        }
        False -> wh
      }

      case wh_next |> dict.get(loc_next) {
        Ok(Space) -> move(dir, wh_next, loc)
        _ -> #(wh_next, loc)
      }
    }
    Robot -> panic
  }
}

fn total_gps(wh: Dict(Coord, Object)) -> Int {
  wh
  |> dict.to_list
  |> list.fold(0, fn(acc, tup) {
    let #(loc, obj) = tup
    let gps = case obj {
      Box | BoxL -> loc.x + 100 * loc.y
      _ -> 0
    }
    acc + gps
  })
}

fn get_next_loc(loc: Coord, dir: Dir) -> Coord {
  let Coord(x, y) = loc
  case dir {
    E -> Coord(x + 1, y)
    S -> Coord(x, y + 1)
    W -> Coord(x - 1, y)
    N -> Coord(x, y - 1)
  }
}

fn update(
  wh: Dict(Coord, Object),
  loc: Coord,
  obj: Object,
) -> Dict(Coord, Object) {
  wh
  |> dict.upsert(loc, fn(_) { obj })
}
