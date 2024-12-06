import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string
import simplifile

pub type Map {
  Map(
    guard_loc_dir: Result(#(Coord, MapItem), Nil),
    map_size: Coord,
    map_dict: Dict(Coord, MapItem),
  )
}

pub type MapItem {
  Obstruction
  Space
  GuardNorth
  GuardEast
  GuardSouth
  GuardWest
}

pub type Coord {
  Coord(x: Int, y: Int)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day06_input.txt")
  // let assert Ok(content) = simplifile.read("data/day06_input_toy1.txt")

  let raw_map: List(List(#(Coord, MapItem))) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, i) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(char, j) {
        let item = case char {
          "#" -> Obstruction
          "^" -> GuardNorth
          ">" -> GuardEast
          "v" -> GuardSouth
          "<" -> GuardWest
          _ -> Space
        }

        // row -> y-axis, col -> x-axis
        #(Coord(j, i), item)
      })
    })

  let assert [first, ..] = raw_map
  let map_size: Coord =
    Coord(x: first |> list.length, y: raw_map |> list.length)

  let map_dict: Dict(Coord, MapItem) =
    raw_map
    |> list.flatten
    |> dict.from_list

  let map =
    Map(
      guard_loc_dir: raw_map
        |> list.flatten
        |> list.find(fn(tup) {
          let #(_, item) = tup
          case item {
            GuardNorth | GuardEast | GuardSouth | GuardWest -> True
            _ -> False
          }
        }),
      map_size: map_size,
      map_dict: map_dict,
    )

  // PART 1
  io.print("Num distinct guard position: ")
  map
  |> get_trace
  |> set.from_list
  |> set.size
  |> io.debug

  // PART 2
  io.print("Num of loops: ")
  map
  |> count_loop(map, Coord(x: 0, y: 0))
  |> io.debug
}

fn get_trace(map: Map) -> List(Coord) {
  case map.guard_loc_dir {
    Error(_) -> []
    Ok(#(coord, _)) -> {
      [coord, ..get_trace(simulation_step(map))]
    }
  }
}

fn count_loop(map: Map, starting_map: Map, coord: Coord) -> Int {
  let Coord(x_max, y_max) = map.map_size

  // coord |> io.debug

  case coord {
    _ if coord.x >= x_max || coord.y >= y_max -> 0
    _ if coord.x >= x_max - 1 ->
      {
        map
        |> place_obstruction(coord)
        |> is_loop(starting_map, 0)
        |> bool.to_int
      }
      + count_loop(map, starting_map, Coord(x: 0, y: coord.y + 1))
    _ ->
      {
        map
        |> place_obstruction(coord)
        |> is_loop(starting_map, 0)
        |> bool.to_int
      }
      + count_loop(map, starting_map, Coord(x: coord.x + 1, y: coord.y))
  }
}

fn place_obstruction(map: Map, coord: Coord) -> Map {
  let updated_map_dict =
    map.map_dict
    |> dict.upsert(coord, fn(maybe_item) {
      let assert Some(item) = maybe_item
      case item {
        Space -> Obstruction
        _ -> item
      }
    })

  Map(..map, map_dict: updated_map_dict)
}

fn is_loop(current: Map, starting: Map, i: Int) -> Bool {
  let assert Ok(#(Coord(x_start, y_start), dir_start)) = starting.guard_loc_dir

  case current.guard_loc_dir {
    // Termination heuristic!
    _ if i > 10_000 -> True
    // Termination case; i.e. when guard leave the area
    Error(Nil) -> False
    Ok(#(Coord(x_curr, y_curr), dir_curr)) -> {
      let back_at_square_one =
        i != 0
        && x_curr == x_start
        && y_curr == y_start
        && dir_curr == dir_start

      case back_at_square_one {
        True -> True
        False -> current |> simulation_step |> is_loop(starting, i + 1)
      }
    }
  }
}

fn simulation_step(map: Map) -> Map {
  case map.guard_loc_dir {
    Ok(#(coord, dir)) -> {
      let updated_map =
        map.map_dict
        |> dict.upsert(update: coord, with: fn(maybe_item) {
          case maybe_item {
            Some(_) -> Space
            None -> Space
          }
        })

      let maybe_new_coord = case dir {
        GuardNorth -> Coord(x: coord.x, y: coord.y - 1)
        GuardEast -> Coord(x: coord.x + 1, y: coord.y)
        GuardSouth -> Coord(x: coord.x, y: coord.y + 1)
        _ -> Coord(x: coord.x - 1, y: coord.y)
      }

      let new_dir = case updated_map |> dict.get(maybe_new_coord) {
        // Turn right and step from the original pos
        Ok(item) ->
          case item {
            Obstruction ->
              case dir {
                GuardNorth -> GuardEast
                GuardEast -> GuardSouth
                GuardSouth -> GuardWest
                _ -> GuardNorth
              }
            _ -> dir
          }
        Error(_) -> dir
      }

      // If there's no turning => no obstacle => safe to step
      let new_coord = case new_dir == dir {
        True -> maybe_new_coord
        False -> coord
      }

      case
        { new_coord.x < map.map_size.x && new_coord.x >= 0 }
        && { new_coord.y < map.map_size.y && new_coord.y >= 0 }
      {
        True ->
          Map(
            ..map,
            guard_loc_dir: #(new_coord, new_dir) |> Ok,
            map_dict: updated_map
              |> dict.upsert(update: new_coord, with: fn(_) { new_dir }),
          )
        False -> Map(..map, guard_loc_dir: Error(Nil))
      }
    }
    Error(_) -> Map(..map, guard_loc_dir: Error(Nil))
  }
}
