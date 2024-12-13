import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  // let assert Ok(content) = simplifile.read("data/day13_input.txt")
  let assert Ok(content) = simplifile.read("data/day13_input_toy.txt")

  [#("Part 1: ", 0), #("Part 2: ", 10_000_000_000_000)]
  |> list.each(fn(tup) {
    io.print(tup.0)

    content
    |> string.trim
    |> string.split("\n\n")
    |> list.map(fn(block) {
      let assert [line_a, line_b, line_p] =
        block
        |> string.trim()
        |> string.split("\n")

      let #(a1, a2) = line_a |> extract_arm
      let #(b1, b2) = line_b |> extract_arm
      let #(p1, p2) = line_p |> extract_prize

      [a1, a2, b1, b2, p1, p2]
    })
    |> list.fold(0, fn(acc, problem) { acc + solve(problem, tup.1) })
    |> io.debug
  })
}

fn extract_arm(line: String) -> #(Int, Int) {
  let assert [_, _, first, second] = line |> string.split(" ")
  let assert Ok(first) =
    first |> string.drop_start(2) |> string.drop_end(1) |> int.parse
  let assert Ok(second) = second |> string.drop_start(2) |> int.parse
  #(first, second)
}

fn extract_prize(line: String) -> #(Int, Int) {
  let assert [_, first, second] = line |> string.split(" ")
  let assert Ok(first) =
    first |> string.drop_start(2) |> string.drop_end(1) |> int.parse
  let assert Ok(second) = second |> string.drop_start(2) |> int.parse
  #(first, second)
}

fn solve(problem: List(Int), offset: Int) -> Int {
  let assert [a, c, b, d, p1, p2] = problem |> list.map(int.to_float)
  let #(p1, p2) = #(p1 +. int.to_float(offset), p2 +. int.to_float(offset))

  let det: Float = a *. d -. b *. c

  use <- bool.guard(when: det |> float.loosely_equals(0.0, 0.001), return: 0)

  let #(inv_11, inv_12, inv_21, inv_22) = #(
    d /. det,
    float.negate(b) /. det,
    float.negate(c) /. det,
    a /. det,
  )

  let n1 = float.round(inv_11 *. p1 +. inv_12 *. p2)
  let n2 = float.round(inv_21 *. p1 +. inv_22 *. p2)

  let assert [a, c, b, d, p1, p2] = problem
  let is_valid = a * n1 + b * n2 == p1 && c * n1 + d * n2 == p2

  use <- bool.guard(!is_valid, 0)

  3 * n1 + n2
}
