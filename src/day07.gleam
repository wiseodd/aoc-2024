import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day07_input.txt")

  [
    #("Total calibration with + and *: ", False),
    #("Total calibration with +, *, and ||: ", True),
  ]
  |> list.each(fn(setup) {
    setup.0 |> io.print

    content
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(line: String) -> Int {
      let assert [target, numbers] = line |> string.trim |> string.split(":")
      let target = target |> int.parse |> result.unwrap(-1)
      let assert [first, ..rest] =
        numbers
        |> string.trim
        |> string.split(" ")
        |> list.map(fn(x) { x |> int.parse |> result.unwrap(-1) })

      case rest |> check(target, setup.1, first) {
        True -> target
        False -> 0
      }
    })
    |> list.fold(0, int.add)
    |> io.debug
  })
}

fn check(numbers: List(Int), target: Int, with_concat: Bool, acc: Int) -> Bool {
  case numbers {
    [] if acc == target -> True
    [] -> False
    _ if acc > target -> False
    [num, ..rest] ->
      check(rest, target, with_concat, num + acc)
      || check(rest, target, with_concat, num * acc)
      || {
        with_concat && check(rest, target, with_concat, concat_nums(acc, num))
      }
  }
}

fn concat_nums(num1: Int, num2: Int) -> Int {
  { { num1 |> int.to_string } <> { num2 |> int.to_string } }
  |> int.parse
  |> result.unwrap(-1)
}
