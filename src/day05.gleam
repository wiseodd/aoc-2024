import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day05_input.txt")

  let assert [rules, updates] =
    content
    |> string.trim
    |> string.split("\n\n")

  let rule_dict: Dict(Int, List(Int)) =
    rules
    |> string.split("\n")
    |> list.map(fn(rule) {
      let assert [num1, num2] =
        rule
        |> string.split("|")
        |> list.map(fn(num) { num |> int.parse |> result.unwrap(0) })
      #(num1, [num2])
    })
    |> to_dict(dict.new())

  let update_list: List(List(Int)) =
    updates
    |> string.split("\n")
    |> list.map(fn(line) {
      line
      |> string.split(",")
      |> list.map(fn(page) { page |> int.parse |> result.unwrap(0) })
    })

  // PART 1
  io.print("Total middle number of correctly-ordered updates: ")
  update_list
  |> list.filter(fn(update) { update |> check_ordering(rule_dict) })
  |> list.map(get_middle_num)
  |> list.fold(0, int.add)
  |> io.debug

  // PART 2
  io.print("Total middle number of corrected updates: ")
  update_list
  |> list.filter(fn(update) { !{ update |> check_ordering(rule_dict) } })
  |> list.map(fn(update) { update |> sort_by_rules(rule_dict) })
  |> list.map(get_middle_num)
  |> list.fold(0, int.add)
  |> io.debug
}

fn to_dict(
  rule_list: List(#(Int, List(Int))),
  res: Dict(Int, List(Int)),
) -> Dict(Int, List(Int)) {
  case rule_list {
    [] -> res
    [#(num1, num2), ..rest] ->
      to_dict(
        rest,
        res
          |> dict.upsert(num1, fn(maybe_lst) {
            case maybe_lst {
              Some(maybe_lst) -> maybe_lst |> list.append(num2)
              None -> num2
            }
          }),
      )
  }
}

fn sort_by_rules(lst: List(Int), rule_dict: Dict(Int, List(Int))) -> List(Int) {
  lst
  |> list.sort(fn(a, b) {
    let a_before_b =
      rule_dict |> dict.get(a) |> result.unwrap([]) |> list.contains(b)

    case a_before_b {
      True -> order.Lt
      False -> order.Gt
    }
  })
}

fn check_ordering(lst: List(Int), rule_dict: Dict(Int, List(Int))) -> Bool {
  lst
  |> sort_by_rules(rule_dict)
  |> list.map2(lst, fn(a, b) { a == b })
  |> list.fold(True, bool.and)
}

fn get_middle_num(lst: List(Int)) -> Int {
  let assert [#(_, val)] =
    lst
    |> list.index_map(fn(x, i) { #(i, x) })
    |> list.filter(fn(ix) { ix.0 == { lst |> list.length } / 2 })

  val
}
