import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub type Register {
  Register(a: Int, b: Int, c: Int)
}

pub type RegType {
  A
  B
  C
}

pub type OpCode {
  Adv
  Bxl
  Bst
  Jnz
  Bxc
  Out
  Bdv
  Cdv
  Literal(Int)
  Combo(Int)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("data/day17_input.txt")

  let assert [regs_str, program_str] =
    content
    |> string.trim
    |> string.split("\n\n")

  let assert [a, b, c] =
    regs_str
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [_, val_str] = line |> string.trim |> string.split(": ")
      let assert Ok(val) = val_str |> int.parse
      val
    })
  let regs = Register(a, b, c)

  let program_str =
    program_str
    |> string.trim
    |> string.split(": ")
    |> list.last
    |> result.unwrap("")
    |> string.split(",")

  let program: Dict(Int, OpCode) = program_str |> str2program

  io.print("Part 1: ")
  program
  |> run(regs, 0)
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.println

  io.print("Part 2: ")
  reverse_engineer_a(0, list.length(program_str) - 1, program_str, regs)
  |> io.debug
}

/// Reason why it works: Check the original program. Notice: A <- A / 8
/// always happens before `out` and `length(program)` equals how many A <- A / 8.
/// So start from the back and do an exhaustive search (val_a + 1) until the result
/// equals the last last numbers of the target. Then we search for the next digit
/// by doing the reverse of A <- A / 8, i.e. `val_a * 8`.
fn reverse_engineer_a(
  val_a: Int,
  i: Int,
  target: List(String),
  regs: Register,
) -> Int {
  let res =
    target
    |> str2program
    |> run(Register(..regs, a: val_a), 0)
    |> list.map(int.to_string)

  case i {
    0 if res == target -> val_a
    _ ->
      case res == list.drop(target, i) {
        True -> reverse_engineer_a(val_a * 8, i - 1, target, regs)
        False -> reverse_engineer_a(val_a + 1, i, target, regs)
      }
  }
}

fn run(program: Dict(Int, OpCode), regs: Register, ip: Int) -> List(Int) {
  let len = program |> dict.size

  case ip {
    _ if ip < 0 -> []
    _ if ip >= len -> []
    _ -> {
      let assert Ok(op) = program |> dict.get(ip)
      let assert Ok(operand) = program |> dict.get(ip + 1)

      let #(res, regs) = case op {
        Adv -> {
          let res = regs |> run_xdv(operand)
          #(res, Register(..regs, a: res))
        }
        Bxl -> regs |> run_bxl(operand)
        Bst -> regs |> run_bst(operand)
        Jnz -> regs |> run_jnz(operand)
        Bxc -> regs |> run_bxc(operand)
        Out -> regs |> run_out(operand)
        Bdv -> {
          let res = regs |> run_xdv(operand)
          #(res, Register(..regs, b: res))
        }
        Cdv -> {
          let res = regs |> run_xdv(operand)
          #(res, Register(..regs, c: res))
        }
        _ -> panic
      }

      let ip = case op {
        Jnz ->
          case res {
            -1 -> ip + 2
            _ -> res
          }
        _ -> ip + 2
      }

      case op {
        Out -> [res, ..run(program, regs, ip)]
        _ -> run(program, regs, ip)
      }
    }
  }
}

fn str2program(program_str: List(String)) -> Dict(Int, OpCode) {
  program_str
  |> list.map_fold(
    #(0, True, program_str |> list.first |> result.unwrap("") |> parse_opcode),
    fn(memo, x) {
      let #(idx, is_opcode, prev) = memo

      let val = case is_opcode {
        True -> parse_opcode(x)
        False -> parse_operand(x, prev)
      }
      #(#(idx + 1, !is_opcode, val), #(idx, val))
    },
  )
  |> pair.second
  |> dict.from_list
}

fn parse_opcode(str: String) -> OpCode {
  case str {
    "0" -> Adv
    "1" -> Bxl
    "2" -> Bst
    "3" -> Jnz
    "4" -> Bxc
    "5" -> Out
    "6" -> Bdv
    "7" -> Cdv
    _ -> panic
  }
}

fn parse_operand(str: String, opcode: OpCode) -> OpCode {
  let assert Ok(x) = str |> int.parse
  case opcode {
    Adv -> Combo(x)
    Bxl -> Literal(x)
    Bst -> Combo(x)
    Jnz -> Literal(x)
    Bxc -> Literal(x)
    Out -> Combo(x)
    Bdv -> Combo(x)
    Cdv -> Combo(x)
    _ -> panic
  }
}

fn run_xdv(regs: Register, operand: OpCode) -> Int {
  let num = regs.a |> int.to_float
  let pow = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let assert Ok(denom) = int.power(2, pow |> int.to_float)
  float.floor(num /. denom) |> float.round
}

fn run_bxl(regs: Register, operand: OpCode) -> #(Int, Register) {
  let left = regs.b
  let assert Literal(right) = operand
  let res = int.bitwise_exclusive_or(left, right)
  #(res, Register(..regs, b: res))
}

fn run_bst(regs: Register, operand: OpCode) -> #(Int, Register) {
  let val = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let res = val % 8
  #(res, Register(..regs, b: res))
}

fn run_jnz(regs: Register, operand: OpCode) -> #(Int, Register) {
  let val_a = regs.a
  case val_a {
    0 -> #(-1, regs)
    _ -> {
      let assert Literal(v) = operand
      #(v, regs)
    }
  }
}

fn run_bxc(regs: Register, _operand: OpCode) -> #(Int, Register) {
  let val_b = regs.b
  let val_c = regs.c
  let res = int.bitwise_exclusive_or(val_b, val_c)
  #(res, Register(..regs, b: res))
}

fn run_out(regs: Register, operand: OpCode) -> #(Int, Register) {
  let val = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let res = val % 8
  #(res, regs)
}

fn get_combo_val(regs: Register, val: Int) -> Int {
  case val {
    _ if val >= 0 && val <= 3 -> val
    4 -> regs.a
    5 -> regs.b
    6 -> regs.c
    _ -> -1
  }
}
