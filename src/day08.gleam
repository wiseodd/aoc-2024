import gleam/dict
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import simplifile

pub type Coord {
  Coord(x: Int, y: Int)
}

pub type Antenna {
  Antenna(loc: Coord, kind: String)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day08_input.txt")
  let content_lst = content |> string.trim |> string.split("\n")

  let max_y = content_lst |> list.length
  let assert Ok(max_x) =
    content_lst
    |> list.map(fn(line) { line |> string.to_graphemes |> list.length })
    |> list.first
  let bounds = Coord(max_x, max_y)

  let antennas =
    content_lst
    |> list.index_map(fn(line, i) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(item, j) { Antenna(Coord(i, j), kind: item) })
    })
    |> list.flatten
    |> list.filter(fn(antenna) { antenna.kind != "." })
    |> list.group(fn(antenna) -> String { antenna.kind })

  [
    #("Num. of unique locs containing an antinode: ", 1),
    #("Num. of unique locs containing antinode with resonant: ", 20),
  ]
  |> list.each(fn(setup) {
    io.print(setup.0)
    antennas
    |> dict.map_values(fn(_, v) {
      v
      |> list.combinations(2)
      |> list.map(fn(pair) {
        let assert [ant1, ant2] = pair
        create_antinodes(ant1, ant2, bounds, setup.1)
      })
    })
    |> dict.values
    |> list.flatten
    |> list.flatten
    |> set.from_list
    |> set.size
    |> io.debug
  })
}

fn create_antinodes(
  ant1: Antenna,
  ant2: Antenna,
  bounds: Coord,
  max_resonance: Int,
) -> List(Coord) {
  let dx = ant1.loc.x - ant2.loc.x
  let dy = ant1.loc.y - ant2.loc.y
  let resonances = list.range(1, max_resonance)

  [
    create_resonant_antinodes(ant1, dx, dy, resonances),
    create_resonant_antinodes(ant2, dx, dy, resonances),
  ]
  |> list.flatten
  |> list.filter(fn(coord) {
    { coord.x >= 0 && coord.x < bounds.x }
    && { coord.y >= 0 && coord.y < bounds.y }
    // If max_resonance == 1, then this is part-1 and we don't count antinodes
    // that overlap towers with the same frequencies. For part-2, we count them all.
    && { max_resonance != 1 || coord != ant1.loc && coord != ant2.loc }
  })
}

fn create_resonant_antinodes(
  ant: Antenna,
  dx: Int,
  dy: Int,
  resonances: List(Int),
) -> List(Coord) {
  let lst1 =
    resonances
    |> list.map(fn(reso) { Coord(ant.loc.x - reso * dx, ant.loc.y - reso * dy) })
  let lst2 =
    resonances
    |> list.map(fn(reso) { Coord(ant.loc.x + reso * dx, ant.loc.y + reso * dy) })

  [lst1, lst2] |> list.flatten
}
