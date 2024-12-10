import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Coord {
  Coord(x: Int, y: Int)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day10_input.txt")
  let content = content |> string.trim |> string.split("\n")

  let topo_map: Dict(Coord, Int) =
    content
    |> list.index_map(fn(line, i) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(val, j) {
        let height = val |> int.parse |> result.unwrap(-9999)
        #(Coord(i, j), height)
      })
    })
    |> list.flatten
    |> dict.from_list

  let trailheads: List(#(Coord, Int)) =
    topo_map |> dict.to_list |> list.filter(fn(node) { node.1 == 0 })

  io.print("Sum of the scores of all trailheads: ")
  trailheads
  |> list.flat_map(fn(trailhead) { trailhead |> dfs(topo_map) |> list.unique })
  |> list.length
  |> io.debug

  io.print("Sum of the ratings of all trailheads: ")
  trailheads
  |> list.flat_map(fn(trailhead) { trailhead |> dfs(topo_map) })
  |> list.length
  |> io.debug
}

fn dfs(node: #(Coord, Int), topo_map: Dict(Coord, Int)) -> List(Coord) {
  let #(loc, height) = node

  case node {
    _ if height == 9 -> [loc]
    _ -> {
      [
        Coord(x: loc.x + 1, y: loc.y),
        Coord(x: loc.x, y: loc.y + 1),
        Coord(x: loc.x - 1, y: loc.y),
        Coord(x: loc.x, y: loc.y - 1),
      ]
      |> list.map(fn(next_loc) {
        case topo_map |> dict.get(next_loc) {
          Ok(next_height) ->
            case next_height - height == 1 {
              True -> dfs(#(next_loc, next_height), topo_map)
              False -> []
            }
          Error(_) -> []
        }
      })
      |> list.flatten
    }
  }
}
