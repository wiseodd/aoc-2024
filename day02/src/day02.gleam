import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input.txt")

  let reports: List(List(Int)) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(line: String) -> List(Int) {
      line
      |> string.split(" ")
      |> list.map(fn(str: String) -> Int {
        str |> int.parse() |> result.unwrap(0)
      })
    })

  io.print("Number of safe report: ")
  let num_safe: Int =
    reports
    |> list.count(is_safe)
  num_safe |> int.to_string |> io.println

  io.print("Number of safe report with dampener: ")
  reports
  |> list.filter(fn(report) { !is_safe(report) })
  |> list.count(is_safe_with_dampener)
  |> int.add(num_safe)
  |> int.to_string
  |> io.println
}

fn is_safe(report: List(Int)) -> Bool {
  { is_sorted(report, order.Lt) || is_sorted(report, order.Gt) }
  && is_difference_ok(report)
}

fn is_safe_with_dampener(report: List(Int)) -> Bool {
  report |> is_safe_if_removed({ report |> list.length } - 1)
}

fn is_safe_if_removed(report: List(Int), idx: Int) -> Bool {
  case idx {
    _ if idx >= 0 ->
      { report |> remove_by_idx(idx) |> is_safe }
      // Or since it's safe overall if it's safe with at least one index is removed
      || is_safe_if_removed(report, idx - 1)
    _ -> False
  }
}

fn is_sorted(lst: List(Int), order: order.Order) -> Bool {
  case lst {
    [a, b, ..rest] ->
      int.compare(a, b) == order && is_sorted([b, ..rest], order)
    _ -> True
  }
}

fn is_difference_ok(lst: List(Int)) -> Bool {
  case lst {
    [a, b, ..rest] -> {
      let absval = int.absolute_value(a - b)
      { absval >= 1 && absval <= 3 } && is_difference_ok([b, ..rest])
    }
    _ -> True
  }
}

fn remove_by_idx(lst: List(Int), idx: Int) -> List(Int) {
  remove_by_idx_(lst, idx, [], 0)
}

fn remove_by_idx_(
  lst: List(Int),
  idx_to_remove: Int,
  acc_lst: List(Int),
  acc_idx: Int,
) -> List(Int) {
  case lst {
    [] -> acc_lst
    [head, ..rest] -> {
      case acc_idx == idx_to_remove {
        True -> remove_by_idx_(rest, idx_to_remove, acc_lst, acc_idx + 1)
        False ->
          remove_by_idx_(rest, idx_to_remove, [head, ..acc_lst], acc_idx + 1)
      }
    }
  }
}
