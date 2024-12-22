import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day22_input.txt")

  let secrets: List(Int) =
    content
    |> string.trim
    |> string.split("\n")
    |> list.map(fn(str) {
      let assert Ok(secret) = int.parse(str)
      secret
    })

  io.print("Part 1: ")
  secrets
  |> list.fold(0, fn(total, secret) { total + simulate(secret, 2000) })
  |> io.debug

  io.print("Part 2: ")
  let counter: Dict(List(Int), Int) = dict.from_list([])
  secrets
  |> list.map_fold(counter, fn(memo, secret) {
    #(get_banana(secret, memo), Nil)
  })
  |> pair.first
  |> dict.fold(0, fn(acc, _, v) { int.max(acc, v) })
  |> io.debug
}

fn get_banana(
  secret: Int,
  counter: Dict(List(Int), Int),
) -> Dict(List(Int), Int) {
  let #(prices, diffs) = secret |> get_prices_and_diffs(2000)
  let done: Set(List(Int)) = set.from_list([])
  diffs
  |> list.window(4)
  |> list.index_fold(#(counter, done), fn(memos, pattern, idx) {
    let #(counter, done) = memos
    use <- bool.guard(done |> set.contains(pattern), #(counter, done))
    let assert Ok(banana) = prices |> list.take(idx + 4) |> list.last
    #(counter |> upsert(pattern, banana), done |> set.insert(pattern))
  })
  |> pair.first
}

fn simulate(secret: Int, n_steps: Int) -> Int {
  use <- bool.guard(n_steps == 0, secret)
  simulate(step(secret), n_steps - 1)
}

fn get_prices_and_diffs(secret: Int, n_steps: Int) -> #(List(Int), List(Int)) {
  use <- bool.guard(n_steps == 0, #([], []))
  let new_secret = step(secret)
  let price = get_price(secret)
  let new_price = get_price(new_secret)
  let diff = new_price - price
  let #(prices, diffs) = get_prices_and_diffs(new_secret, n_steps - 1)
  #([[new_price], prices] |> list.flatten, [[diff], diffs] |> list.flatten)
}

fn get_price(secret: Int) -> Int {
  let assert Ok(digits) = secret |> int.digits(10)
  let assert Ok(price) = digits |> list.last
  price
}

fn step(secret: Int) -> Int {
  let secret =
    secret
    |> int.multiply(64)
    |> mix(secret)
    |> prune
  let secret =
    secret
    |> int.divide(32)
    |> result.unwrap(-1000)
    |> mix(secret)
    |> prune
  secret
  |> int.multiply(2048)
  |> mix(secret)
  |> prune
}

fn mix(value: Int, secret: Int) -> Int {
  int.bitwise_exclusive_or(value, secret)
}

fn prune(secret: Int) -> Int {
  secret % 16_777_216
}

fn upsert(d: Dict(a, Int), k: a, v: Int) -> Dict(a, Int) {
  d
  |> dict.upsert(k, fn(maybe_val) {
    case maybe_val {
      Some(val) -> val + v
      None -> v
    }
  })
}
