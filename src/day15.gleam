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
  Wall
  Space
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day15_input.txt")
  // let assert Ok(content) = simplifile.read("data/day15_input_toy.txt")
  // let assert Ok(content) = simplifile.read("data/day15_input_toy2.txt")

  let assert [map_str, moves_str] =
    content |> string.trim |> string.split("\n\n")

  let nrows = map_str |> string.trim |> string.split("\n") |> list.length
  let assert Ok(line) =
    map_str |> string.trim |> string.split("\n") |> list.first
  let ncols = line |> string.to_graphemes |> list.length
  let max: Coord = Coord(ncols, nrows)

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

  let warehouse =
    moves
    // |> list.take(7)
    |> list.map_fold(#(warehouse, robot_loc), fn(memo, dir) {
      let memo = move(dir, memo.0, memo.1)

      // io.debug(dir)
      // memo.0 |> draw(max)

      #(memo, dir)
    })
    |> pair.first
    |> pair.first

  io.print("Part 1: ")
  warehouse
  |> dict.to_list
  |> list.fold(0, fn(acc, tup) {
    let #(loc, obj) = tup
    let gps = case obj {
      Box -> loc |> gps
      _ -> 0
    }
    acc + gps
  })
  |> io.debug
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
    Box -> {
      // Move the next object
      let #(wh_next, _) = move(dir, wh, loc_next)
      case wh_next |> dict.get(loc_next) {
        Ok(Space) -> move(dir, wh_next, loc)
        _ -> #(wh_next, loc)
      }
    }
    Robot -> panic
  }
}

fn gps(loc: Coord) -> Int {
  loc.x + 100 * loc.y
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

fn draw(wh: Dict(Coord, Object), max: Coord) {
  io.println("")

  list.range(0, max.y - 1)
  |> list.each(fn(y) {
    list.range(0, max.x - 1)
    |> list.each(fn(x) {
      let assert Ok(obj) = wh |> dict.get(Coord(x, y))
      case obj {
        Space -> "."
        Wall -> "#"
        Box -> "O"
        Robot -> "@"
      }
      |> io.print
    })
    io.println("")
  })
  io.println("")
}
