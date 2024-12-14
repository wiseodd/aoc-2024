import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/regexp
import gleam/string
import simplifile

pub type Coord {
  Coord(x: Int, y: Int)
}

pub type Robot {
  Robot(pos: Coord, vel: Coord)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day14_input.txt")
  let max = Coord(101, 103)

  let quadrants = [
    #(Coord(0, 0), Coord(max.x / 2, max.y / 2)),
    #(Coord(max.x / 2 + 1, 0), Coord(max.x, max.y / 2)),
    #(Coord(0, max.y / 2 + 1), Coord(max.x / 2, max.y)),
    #(Coord(max.x / 2 + 1, max.y / 2 + 1), Coord(max.x, max.y)),
  ]

  let robots: Dict(Int, Robot) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, i) {
      let robot = extract_robot(line)
      #(i, robot)
    })
    |> dict.from_list

  io.print("Part 1: ")
  let sf1 =
    robots
    |> simulate(max, 100)
    |> safety_factor(quadrants)
  sf1 |> io.debug

  io.print("Part 2: ")
  list.range(0, 10_000)
  |> list.map_fold(robots, fn(memo, i) {
    case memo |> no_overlap {
      True -> {
        io.debug(i)
        memo |> pretty_print(max, False)
      }
      False -> Nil
    }

    #(step(memo, max), i)
  })
}

fn extract_robot(line: String) -> Robot {
  let assert Ok(re) =
    regexp.from_string("p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)")

  let assert [
    regexp.Match(_, submatches: [Some(x), Some(y), Some(vx), Some(vy)]),
  ] = re |> regexp.scan(line)

  let assert #(Ok(x), Ok(y), Ok(vx), Ok(vy)) = #(
    x |> int.parse,
    y |> int.parse,
    vx |> int.parse,
    vy |> int.parse,
  )

  Robot(pos: Coord(x, y), vel: Coord(vx, vy))
}

fn simulate(robots: Dict(Int, Robot), max: Coord, n: Int) -> Dict(Int, Robot) {
  list.range(1, n)
  |> list.map_fold(robots, fn(memo, i) { #(step(memo, max), i) })
  |> pair.first
}

fn step(robots: Dict(Int, Robot), max: Coord) -> Dict(Int, Robot) {
  robots
  |> dict.keys
  |> list.map_fold(robots, fn(memo, id) {
    let assert Ok(robot) = memo |> dict.get(id)
    #(memo |> update(id, Robot(pos: move(robot, max), vel: robot.vel)), id)
  })
  |> pair.first
}

fn move(robot: Robot, max: Coord) -> Coord {
  let new_x = robot.pos.x + robot.vel.x
  let new_x = case new_x >= 0 && new_x < max.x {
    True -> new_x
    False -> mod(new_x, max.x)
  }

  let new_y = robot.pos.y + robot.vel.y
  let new_y = case new_y >= 0 && new_y < max.y {
    True -> new_y
    False -> mod(new_y, max.y)
  }

  Coord(new_x, new_y)
}

fn count(quadrant: #(Coord, Coord), robots: Dict(Int, Robot)) -> Int {
  robots
  |> dict.to_list
  |> list.fold(0, fn(acc, tup) {
    let #(_, Robot(Coord(x, y), _)) = tup
    let #(bound_x1, bound_x2) = #({ quadrant.0 }.x, { quadrant.1 }.x)
    let #(bound_y1, bound_y2) = #({ quadrant.0 }.y, { quadrant.1 }.y)

    acc
    + bool.to_int(
      x >= bound_x1 && x < bound_x2 && y >= bound_y1 && y < bound_y2,
    )
  })
}

fn safety_factor(
  robots: Dict(Int, Robot),
  quadrants: List(#(Coord, Coord)),
) -> Int {
  quadrants
  |> list.map(fn(quadrant) { quadrant |> count(robots) })
  |> list.fold(1, int.multiply)
}

fn update(robots: Dict(Int, Robot), id: Int, robot: Robot) -> Dict(Int, Robot) {
  robots
  |> dict.upsert(id, fn(_) { robot })
}

fn mod(a: Int, b: Int) -> Int {
  let assert Ok(c) = a |> int.modulo(b)
  c
}

fn no_overlap(robots: Dict(Int, Robot)) -> Bool {
  let pos = robots |> dict.values |> list.map(fn(robot) { robot.pos })
  list.length(pos) == list.length(pos |> list.unique)
}

fn pretty_print(robots: Dict(Int, Robot), max: Coord, num: Bool) {
  list.range(0, max.y - 1)
  |> list.each(fn(i) {
    list.range(0, max.x - 1)
    |> list.each(fn(j) {
      let n =
        robots
        |> dict.filter(fn(_, v) { v.pos == Coord(j, i) })
        |> dict.size

      case n {
        0 -> "."
        _ ->
          case num {
            True -> n |> int.to_string
            False -> "*"
          }
      }
      |> io.print
    })
    io.println("")
  })
}
