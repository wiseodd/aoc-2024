import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string
import simplifile

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
  // let assert Ok(content) = simplifile.read("data/day06_input.txt")
  let assert Ok(content) = simplifile.read("data/day06_input_toy1.txt")

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

  let map: Dict(Coord, MapItem) =
    raw_map
    |> list.flatten
    |> dict.from_list

  case map |> get_guard_loc_dir {
    Ok(#(coord, _)) -> {
      io.print("Num distinct guard position: ")
      #(coord, map)
      |> Ok
      |> get_trace(map_size)
      |> set.from_list
      |> set.size
      |> io.debug

      Nil
    }
    Error(Nil) -> Nil
  }
}

fn get_trace(
  val_or_err: Result(#(Coord, Dict(Coord, MapItem)), Nil),
  map_size: Coord,
) -> List(Coord) {
  case val_or_err {
    Error(_) -> []
    Ok(#(coord, map)) -> {
      [coord, ..get_trace(simulation_step(map, map_size), map_size)]
    }
  }
}

fn get_guard_loc_dir(
  map: Dict(Coord, MapItem),
) -> Result(#(Coord, MapItem), Nil) {
  map
  |> dict.to_list
  |> list.find(fn(tup) {
    let #(_, item) = tup
    case item {
      GuardNorth | GuardEast | GuardSouth | GuardWest -> True
      _ -> False
    }
  })
}

fn simulation_step(
  map: Dict(Coord, MapItem),
  map_size: Coord,
) -> Result(#(Coord, Dict(Coord, MapItem)), Nil) {
  let guard_loc_dir = map |> get_guard_loc_dir

  case guard_loc_dir {
    Ok(#(coord, dir)) -> {
      let updated_map =
        map
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
        { new_coord.x < map_size.x && new_coord.x >= 0 }
        && { new_coord.y < map_size.y && new_coord.y >= 0 }
      {
        True ->
          #(
            new_coord,
            updated_map
              |> dict.upsert(update: new_coord, with: fn(maybe_item) {
                case maybe_item {
                  Some(_) -> new_dir
                  None -> new_dir
                }
              }),
          )
          |> Ok
        False -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
