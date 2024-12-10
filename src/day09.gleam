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
  // part1(content)
  part2(content)
}

// ------------------------------------ PART 1 -----------------------------------------

fn part1(content: String) {
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

// ------------------------------------ PART 2 -----------------------------------------

pub type FileSpace {
  FileSpace(id: Int, size: Int, space_after: Int)
}

fn part2(content: String) {
  let files: List(FileSpace) =
    content
    |> string.trim
    |> string.to_graphemes
    |> list.map(fn(s) {
      let assert Ok(val) = s |> int.parse
      val
    })
    // list of pairs of `(file_size, space_after)`
    |> list.sized_chunk(2)
    |> list.index_map(fn(sizes: List(Int), file_id: Int) -> FileSpace {
      case sizes {
        [file_size, space_after] -> FileSpace(file_id, file_size, space_after)
        [file_size] -> FileSpace(file_id, file_size, 0)
        _ -> panic
      }
    })

  files
  |> list.reverse
  |> arrange_whole
  |> list.reverse
  // |> calculate_checksum_whole(0)
  |> io.debug

  io.println("")

  files
  |> list.reverse
  |> arrange_whole2
  |> list.reverse
  // |> calculate_checksum_whole(0)
  |> io.debug
}

fn calculate_checksum_whole(files: List(FileSpace), idx: Int) -> Int {
  case files {
    [] -> 0
    [first, ..rest] ->
      {
        // #(first.id, first.size, idx) |> io.debug
        first.id
        |> list.repeat(first.size)
        |> list.index_fold(0, fn(acc, val, i) { acc + val * { idx + i } })
      }
      + calculate_checksum_whole(rest, idx + first.size + first.space_after)
  }
}

fn arrange_whole(reversed_files: List(FileSpace)) -> List(FileSpace) {
  case reversed_files {
    [] -> []
    [file, ..rest] -> {
      let files = rest |> list.reverse
      let #(before, after) =
        files
        |> list.split_while(fn(fs) {
          // Negated since want to take the first that >=
          fs.space_after < file.size
        })

      case after {
        [] -> [[file], before |> list.reverse |> arrange_whole] |> list.flatten
        [first_after, ..rest_after] -> {
          let res =
            [
              before,
              [FileSpace(first_after.id, first_after.size, 0)],
              [
                FileSpace(
                  file.id,
                  file.size,
                  first_after.space_after - file.size,
                ),
              ],
              rest_after,
            ]
            |> list.flatten
            |> list.reverse

          [
            [FileSpace(file.id, 0, file.size + file.space_after)],
            res |> arrange_whole,
          ]
          |> list.flatten
        }
      }
    }
  }
}

fn arrange_whole2(reversed_files: List(FileSpace)) -> List(FileSpace) {
  case reversed_files {
    [] -> []
    [file, ..rest] -> {
      let files = rest |> list.reverse
      let #(before, after) =
        files
        |> list.split_while(fn(fs) {
          // Negated since want to take the first that >=
          fs.space_after < file.size
        })

      case after {
        [] -> [[file], before |> list.reverse |> arrange_whole2] |> list.flatten
        [first_after, ..rest_after] -> {
          [
            before,
            [FileSpace(first_after.id, first_after.size, 0)],
            [FileSpace(file.id, file.size, first_after.space_after - file.size)],
            case rest_after |> list.reverse {
              [] -> []
              [last_rest_after, ..first_rest_after] -> {
                [
                  FileSpace(
                    last_rest_after.id,
                    last_rest_after.size,
                    last_rest_after.space_after + file.size + file.space_after,
                  ),
                  ..first_rest_after
                ]
                |> list.reverse
              }
            },
          ]
          |> list.flatten
          |> list.reverse
          |> arrange_whole2
        }
      }
    }
  }
}
