import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import simplifile

pub type Dir {
  E
  SE
  S
  SW
  W
  NW
  N
  NE
}

pub type Coord {
  Coord(x: Int, y: Int)
}

pub type Plot {
  Plot(plant: String, visited: Bool)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day12_input.txt")

  let map: Dict(Coord, Plot) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.index_map(fn(line, i) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(val, j) { #(Coord(i, j), Plot(val, False)) })
    })
    |> list.flatten
    |> dict.from_list

  io.print("Part 1: ")
  map
  |> get_regions
  |> list.fold(0, fn(acc, region) {
    acc + get_area(region) * get_perimeter(region, map)
  })
  |> io.debug

  io.print("Part 2: ")
  map
  |> get_regions
  |> list.fold(0, fn(acc, region) {
    acc + get_area(region) * count_sides(region, map)
  })
  |> io.debug
}

fn get_area(region: List(Coord)) -> Int {
  region |> list.length
}

fn get_perimeter(region: List(Coord), map: Dict(Coord, Plot)) -> Int {
  let assert [loc, ..] = region
  let assert Ok(plot) = map |> dict.get(loc)
  region
  |> list.fold(0, fn(total, loc) {
    total
    + {
      [E, S, W, N]
      |> list.fold(0, fn(acc, dir) {
        acc
        + case map |> dict.get(move(loc, dir)) {
          Ok(next_plot) if next_plot.plant != plot.plant -> 1
          Error(_) -> 1
          _ -> 0
        }
      })
    }
  })
}

/// Counting sides == counting corners
fn count_sides(region: List(Coord), map: Dict(Coord, Plot)) -> Int {
  let assert [loc, ..] = region
  let assert Ok(plot) = map |> dict.get(loc)
  region
  |> list.fold(0, fn(total, loc) {
    // OK => next_plant != curr_plant
    let assert [e_ok, se_ok, s_ok, sw_ok, w_ok, nw_ok, n_ok, ne_ok] =
      [E, SE, S, SW, W, NW, N, NE]
      |> list.map(fn(dir) { map |> dict.get(move(loc, dir)) |> is_ok(plot) })

    total
    + bool.to_int(ne_ok && n_ok && e_ok)
    + bool.to_int(se_ok && s_ok && e_ok)
    + bool.to_int(sw_ok && s_ok && w_ok)
    + bool.to_int(nw_ok && n_ok && w_ok)
    + bool.to_int(ne_ok && !n_ok && !e_ok)
    + bool.to_int(se_ok && !s_ok && !e_ok)
    + bool.to_int(sw_ok && !s_ok && !w_ok)
    + bool.to_int(nw_ok && !n_ok && !w_ok)
    + bool.to_int(!ne_ok && n_ok && e_ok)
    + bool.to_int(!se_ok && s_ok && e_ok)
    + bool.to_int(!sw_ok && s_ok && w_ok)
    + bool.to_int(!nw_ok && n_ok && w_ok)
  })
}

fn is_ok(new_plot_or_err: Result(Plot, Nil), plot: Plot) -> Bool {
  case new_plot_or_err {
    Ok(new_plot) -> new_plot.plant != plot.plant
    Error(_) -> True
  }
}

fn get_regions(map: Dict(Coord, Plot)) -> List(List(Coord)) {
  let visit_map =
    map
    |> dict.keys
    |> list.map(fn(loc) { #(loc, False) })
    |> dict.from_list

  map
  |> dict.keys
  |> list.map_fold(visit_map, fn(memo, loc) -> #(Dict(Coord, Bool), Set(Coord)) {
    case memo |> dict.get(loc) {
      Ok(v) if !v -> {
        let res =
          map
          |> dfs(loc)
          |> dict.filter(fn(_, v) { v.visited })
          |> dict.to_list
          |> list.map(pair.first)
          |> set.from_list

        #(memo |> mark(loc), res)
      }
      _ -> #(memo, [] |> set.from_list)
    }
  })
  |> pair.second
  |> set.from_list
  |> set.to_list
  |> list.map(set.to_list)
}

fn dfs(map: Dict(Coord, Plot), loc: Coord) -> Dict(Coord, Plot) {
  case map |> dict.get(loc) {
    Ok(plot) if plot.visited -> map
    Ok(plot) if !plot.visited -> {
      let map = map |> mark_visited(loc)

      [E, S, W, N]
      |> list.map(fn(dir) { move(loc, dir) })
      |> list.map_fold(map, fn(curr_map, new_loc) {
        let new_map = case curr_map |> dict.get(new_loc) {
          Ok(new_plot) if new_plot.plant == plot.plant ->
            curr_map |> dfs(new_loc)
          _ -> curr_map
        }
        #(new_map, new_loc)
      })
      |> pair.first
    }
    _ -> map
  }
}

fn move(curr: Coord, dir: Dir) -> Coord {
  case dir {
    E -> Coord(curr.x + 1, curr.y)
    SE -> Coord(curr.x + 1, curr.y + 1)
    S -> Coord(curr.x, curr.y + 1)
    SW -> Coord(curr.x - 1, curr.y + 1)
    W -> Coord(curr.x - 1, curr.y)
    NW -> Coord(curr.x - 1, curr.y - 1)
    N -> Coord(curr.x, curr.y - 1)
    NE -> Coord(curr.x + 1, curr.y - 1)
  }
}

fn mark_visited(map: Dict(Coord, Plot), k: Coord) -> Dict(Coord, Plot) {
  map
  |> dict.upsert(k, fn(maybe_plot) {
    case maybe_plot {
      Some(plot) -> Plot(plot.plant, True)
      None -> panic
    }
  })
}

fn mark(visit_map: Dict(Coord, Bool), k: Coord) -> Dict(Coord, Bool) {
  visit_map
  |> dict.upsert(k, fn(maybe_visit) {
    case maybe_visit {
      Some(_) -> True
      None -> panic
    }
  })
}
