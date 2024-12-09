import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const empty = -9999

pub fn main() {
  // let assert Ok(content) = simplifile.read("data/day09_input.txt")
  let assert Ok(content) = simplifile.read("data/day09_input_toy.txt")

  let blocks: List(Int) =
    content
    |> string.trim
    |> string.to_graphemes
    |> list.map(fn(str) {
      let assert Ok(val) = str |> int.parse
      val
    })
    |> map2blocks(0, True)

  let len: Int = blocks |> list.length
  let blocks_bwd: List(Int) = blocks |> list.reverse

  // calculate_checksum(blocks, blocks_bwd, 0, 0, len)
  // |> io.debug

  let files = blocks |> blocks2files(0, 0)

  [1, 2, 3, 4, 5] |> replace(1, 100) |> insert_at(1, 9) |> io.debug
  arrange_whole(files, 0, { files |> list.length } - 1) |> io.debug
}

fn map2blocks(disk_map: List(Int), block_id: Int, is_block: Bool) -> List(Int) {
  case disk_map {
    [] -> []
    [first, ..rest] -> {
      let #(new_block_id, space) = case is_block {
        True -> #(block_id + 1, block_id |> list.repeat(first))
        False -> #(block_id, empty |> list.repeat(first))
      }
      [space, map2blocks(rest, new_block_id, !is_block)] |> list.flatten
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

pub type File {
  File(id: Int, size: Int)
}

fn blocks2files(blocks: List(Int), prev: Int, size: Int) -> List(File) {
  case blocks {
    [] -> []
    [last] -> [File(id: last, size: size + 1)]
    [first, ..rest] -> {
      case first {
        _ if first != prev -> [
          File(id: prev, size: size),
          ..blocks2files(rest, first, 1)
        ]
        _ -> blocks2files(rest, prev, size + 1)
      }
    }
  }
}

fn files2blocks(files: List(File)) -> List(Int) {
  case files {
    [] -> []
    [first, ..rest] ->
      [first.id |> list.repeat(first.size), files2blocks(rest)] |> list.flatten
  }
}

fn arrange_whole(files: List(File), idx_fwd: Int, idx_bwd: Int) -> List(File) {
  let maybe_last = files |> list.drop(idx_bwd) |> list.first

  case maybe_last {
    _ if idx_bwd < 0 -> files
    Error(_) -> files
    _ if idx_fwd >= idx_bwd -> arrange_whole(files, 0, idx_bwd - 1)
    Ok(last) if last.id == empty -> arrange_whole(files, 0, idx_bwd - 1)
    Ok(last) if last.id != empty -> {
      let maybe_first = files |> list.drop(idx_fwd) |> list.first

      case maybe_first {
        Error(_) -> arrange_whole(files, 0, idx_bwd - 1)
        Ok(first) if first.id == empty && first.size == last.size ->
          arrange_whole(files |> replace(idx_fwd, last), 0, idx_bwd - 1)
        Ok(first) if first.id == empty && last.size < first.size ->
          arrange_whole(
            files
              |> replace(idx_fwd, last)
              |> replace(idx_bwd, File(id: empty, size: last.size))
              |> insert_at(
                idx_fwd + 1,
                File(id: empty, size: first.size - last.size),
              ),
            0,
            idx_bwd - 1,
          )
        Ok(first) if first.id == empty && last.size > first.size ->
          arrange_whole(files, idx_fwd + 1, idx_bwd)
        Ok(first) if first.id != empty ->
          arrange_whole(files, idx_fwd + 1, idx_bwd)
        _ -> {
          [maybe_last, maybe_first] |> io.debug
          panic
        }
      }
    }
    _ -> panic
  }
}

fn replace(lst: List(a), idx: Int, val: a) -> List(a) {
  lst
  |> list.index_map(fn(v, i) {
    case i == idx {
      True -> val
      False -> v
    }
  })
}

fn insert_at(lst: List(a), idx: Int, val: a) -> List(a) {
  [lst |> list.take(idx), [val], lst |> list.drop(idx)] |> list.flatten
}
