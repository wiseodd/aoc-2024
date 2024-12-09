import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const empty = -9999

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day09_input.txt")
  // let assert Ok(content) = simplifile.read("data/day09_input_toy.txt")

  let blocks: List(Int) =
    content
    |> string.trim
    |> string.to_graphemes
    |> list.map(fn(str) {
      let assert Ok(val) = str |> int.parse
      val
    })
    |> to_blocks(0, True)

  let len: Int = blocks |> list.length
  let blocks_bwd: List(Int) = blocks |> list.reverse

  calculate_checksum(blocks, blocks_bwd, 0, 0, len)
  |> io.debug
}

fn to_blocks(disk_map: List(Int), block_id: Int, is_block: Bool) -> List(Int) {
  case disk_map {
    [] -> []
    [first, ..rest] -> {
      let #(new_block_id, space) = case is_block {
        True -> #(block_id + 1, block_id |> list.repeat(first))
        False -> #(block_id, empty |> list.repeat(first))
      }
      [space, to_blocks(rest, new_block_id, !is_block)] |> list.flatten
    }
  }
}

fn calculate_checksum(
  blocks_fwd: List(Int),
  blocks_bwd: List(Int),
  idx_fwd: Int,
  idx_bwd: Int,
  len: Int,
) -> Int {
  case blocks_fwd {
    [] -> 0
    _ if idx_fwd >= len - idx_bwd -> 0
    [first, ..rest] if first != empty ->
      first
      * idx_fwd
      + calculate_checksum(rest, blocks_bwd, idx_fwd + 1, idx_bwd, len)
    [first, ..rest] if first == empty ->
      case blocks_bwd {
        [last, ..rest_bwd] if last != empty ->
          last
          * idx_fwd
          + calculate_checksum(rest, rest_bwd, idx_fwd + 1, idx_bwd + 1, len)
        [last, ..rest_bwd] if last == empty ->
          calculate_checksum(blocks_fwd, rest_bwd, idx_fwd, idx_bwd + 1, len)
        _ -> panic
      }
    _ -> panic
  }
}
