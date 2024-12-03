import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input.txt")

  // PART 1
  io.print("Sum of mults: ")

  let assert Ok(re) =
    regexp.from_string("mul\\((?<first>\\d+),(?<second>\\d+)\\)")

  regexp.scan(re, content |> string.trim)
  |> list.fold(0, fn(sum: Int, val: regexp.Match) -> Int {
    let regexp.Match(_, submatches) = val
    sum + get_product(submatches)
  })
  |> int.to_string
  |> io.println

  // PART 2
  io.print("Sum of mults with do() and don't(): ")

  let assert Ok(re) =
    regexp.from_string(
      "mul\\((?<first>\\d+),(?<second>\\d+)\\)|do\\(\\)|don't\\(\\)",
    )

  regexp.scan(re, content |> string.trim)
  |> multiply_do_dont(1)
  |> int.to_string
  |> io.println
}

fn multiply_do_dont(matches: List(regexp.Match), multiplier: Int) -> Int {
  case matches {
    [regexp.Match(match, submatches), ..rest] -> {
      case match {
        "do()" -> multiply_do_dont(rest, 1)
        "don't()" -> multiply_do_dont(rest, 0)
        _ -> {
          multiplier
          * get_product(submatches)
          + multiply_do_dont(rest, multiplier)
        }
      }
    }
    _ -> 0
  }
}

fn get_product(submatches: List(Option(String))) -> Int {
  submatches
  |> list.fold(1, fn(acc: Int, sm: Option(String)) -> Int {
    acc * { sm |> option.unwrap("0") |> int.parse |> result.unwrap(0) }
  })
}
