import gleam/string
import simplifile

pub fn main() {
  // let assert Ok(content) = simplifile.read("data/day13_input.txt")
  let assert Ok(content) = simplifile.read("data/day13_input_toy.txt")

  let map =
    content
    |> string.trim
    |> string.split("\n")
}
