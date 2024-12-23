import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day23_input.txt")

  let graph: Dict(String, Set(String)) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.map_fold(dict.from_list([]), fn(memo, line) {
      let assert [a, b] = line |> string.split("-")
      #(memo |> upsert(a, b) |> upsert(b, a), Nil)
    })
    |> pair.first

  io.print("Part 1: ")
  let cliques =
    graph
    |> get_cliques(3)

  cliques
  |> set.filter(fn(s) {
    s
    |> set.fold(False, fn(acc, str) { acc || string.starts_with(str, "t") })
  })
  |> set.size
  |> io.debug

  io.print("Part 2: ")
  graph
  |> get_max_cliques
  |> set.to_list
  |> list.map(set.to_list)
  |> list.fold([], fn(acc, clique) {
    case list.length(clique) > list.length(acc) {
      True -> clique
      False -> acc
    }
  })
  |> list.sort(string.compare)
  |> string.join(",")
  |> io.println
}

fn get_cliques(graph: Dict(String, Set(String)), k: Int) -> Set(Set(String)) {
  graph
  |> dict.keys
  |> list.map(fn(n) { dfs(graph, n, k, set.new()) })
  |> list.fold(set.new(), set.union)
}

fn get_max_cliques(graph: Dict(String, Set(String))) -> Set(Set(String)) {
  let vertices = graph |> dict.keys |> set.from_list
  vertices
  |> set.map(fn(n) { max_clique(graph, vertices, set.from_list([n])) })
}

fn max_clique(
  graph: Dict(String, Set(String)),
  vertices: Set(String),
  res: Set(String),
) -> Set(String) {
  case vertices |> set.to_list {
    [] -> res
    [v, ..rest] ->
      case is_clique(graph, res |> set.insert(v)) {
        True -> max_clique(graph, rest |> set.from_list, res |> set.insert(v))
        False -> max_clique(graph, rest |> set.from_list, res)
      }
  }
}

fn is_clique(graph: Dict(String, Set(String)), subgraph: Set(String)) -> Bool {
  subgraph
  |> set.to_list
  |> list.combination_pairs
  |> list.fold(True, fn(acc, p) {
    acc && { graph |> get(p.0) |> set.contains(p.1) }
  })
}

fn dfs(
  graph: Dict(String, Set(String)),
  start: String,
  k: Int,
  subgraph: Set(String),
) -> Set(Set(String)) {
  use <- bool.guard(
    set.size(subgraph) == k && is_clique(graph, subgraph),
    set.from_list([subgraph]),
  )
  use <- bool.guard(set.size(subgraph) > k, set.new())

  graph
  |> get(start)
  |> set.map(fn(n) {
    use <- bool.guard(subgraph |> set.contains(n), set.new())
    dfs(graph, n, k, subgraph |> set.insert(start))
  })
  |> set.fold(set.new(), set.union)
}

fn get(d: Dict(String, Set(String)), k: String) {
  let assert Ok(v) = d |> dict.get(k)
  v
}

fn upsert(d: Dict(String, Set(String)), k: String, v: String) {
  d
  |> dict.upsert(k, fn(maybe_set) {
    case maybe_set {
      Some(s) -> s |> set.insert(v)
      None -> set.from_list([v])
    }
  })
}
