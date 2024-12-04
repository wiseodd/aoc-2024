import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day01_input.txt")

  let list1: List(Int) = extract_sorted_list(content, First)
  let list2: List(Int) = extract_sorted_list(content, Second)

  // ----- Part 1 -----

  io.print("Distance: ")
  list.map2(list1, list2, fn(item1: Int, item2: Int) -> Int {
    int.absolute_value(item1 - item2)
  })
  |> int.sum
  |> int.to_string
  |> io.println

  // ----- Part 2 -----

  // Storing [num, count] where num is a number from list1 and count is the number
  // of occurrences in list2
  let cache: dict.Dict(Int, Int) = dict.new()

  io.print("Similarity: ")
  list1
  |> list.map(fn(item: Int) -> Int {
    let count: Int = case cache |> dict.get(item) {
      Ok(cnt) -> cnt
      Error(_) -> {
        let cnt: Int =
          list2
          |> list.count(fn(val: Int) -> Bool { val == item })
        cache |> dict.insert(item, cnt)
        cnt
      }
    }

    item * count
  })
  |> int.sum
  |> int.to_string
  |> io.println
}

type WhichList {
  First
  Second
}

fn extract_sorted_list(file_content: String, which_list: WhichList) -> List(Int) {
  file_content
  |> string.split(on: "\n")
  |> list.map(fn(line: String) -> Int {
    let items: List(String) = line |> string.split(on: "   ")
    let item: String = case which_list {
      First -> items |> list.first |> result.unwrap("")
      Second -> items |> list.last |> result.unwrap("")
    }
    item |> int.parse() |> result.unwrap(0)
  })
  |> list.sort(by: int.compare)
}
