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
  // let assert Ok(content) = simplifile.read("data/day17_input.txt")
  let assert Ok(content) = simplifile.read("data/day17_input_toy.txt")

  let assert [regs_str, program_str] =
    content
    |> string.trim
    |> string.split("\n\n")

  let regs: Dict(Register, Int) =
    regs_str
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [reg_str, val_str] = line |> string.trim |> string.split(": ")
      let reg = case reg_str |> string.slice(9, 1) {
        "A" -> A
        "B" -> B
        _ -> C
      }
      let assert Ok(val) = val_str |> int.parse
      #(reg, val)
    })
    |> dict.from_list

  let program_str =
    program_str
    |> string.trim
    |> string.split(": ")
    |> list.last
    |> result.unwrap("")
    |> string.split(",")

  let program: Dict(Int, OpCode) =
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

  program
  |> run(regs, 0)
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.debug
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

fn run(
  program: Dict(Int, OpCode),
  regs: Dict(Register, Int),
  ip: Int,
) -> List(Int) {
  let len = program |> dict.size

  case ip {
    _ if ip < 0 -> []
    _ if ip >= len -> []
    _ -> {
      let assert Ok(op) = program |> dict.get(ip)
      let assert Ok(operand) = program |> dict.get(ip + 1)

      let #(res, regs) = case op {
        Adv -> regs |> run_xdv(operand, A)
        Bxl -> regs |> run_bxl(operand)
        Bst -> regs |> run_bst(operand)
        Jnz -> regs |> run_jnz(operand)
        Bxc -> regs |> run_bxc(operand)
        Out -> regs |> run_out(operand)
        Bdv -> regs |> run_xdv(operand, B)
        Cdv -> regs |> run_xdv(operand, C)
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

fn run_xdv(
  regs: Dict(Register, Int),
  operand: OpCode,
  x: Register,
) -> #(Int, Dict(Register, Int)) {
  let num = regs |> get_reg(A) |> int.to_float
  let pow = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let assert Ok(denom) = int.power(2, pow |> int.to_float)
  let res = float.floor(num /. denom) |> float.round
  #(res, regs |> update_reg(x, res))
}

fn run_bxl(
  regs: Dict(Register, Int),
  operand: OpCode,
) -> #(Int, Dict(Register, Int)) {
  let left = regs |> get_reg(B)
  let assert Literal(right) = operand
  let res = int.bitwise_exclusive_or(left, right)
  #(res, regs |> update_reg(B, res))
}

fn run_bst(
  regs: Dict(Register, Int),
  operand: OpCode,
) -> #(Int, Dict(Register, Int)) {
  let val = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let res = val % 8
  #(res, regs |> update_reg(B, res))
}

fn run_jnz(
  regs: Dict(Register, Int),
  operand: OpCode,
) -> #(Int, Dict(Register, Int)) {
  let val_a = regs |> get_reg(A)
  case val_a {
    0 -> #(-1, regs)
    _ -> {
      let assert Literal(v) = operand
      #(v, regs)
    }
  }
}

fn run_bxc(
  regs: Dict(Register, Int),
  _operand: OpCode,
) -> #(Int, Dict(Register, Int)) {
  let val_b = regs |> get_reg(B)
  let val_c = regs |> get_reg(C)
  let res = int.bitwise_exclusive_or(val_b, val_c)
  #(res, regs |> update_reg(B, res))
}

fn run_out(
  regs: Dict(Register, Int),
  operand: OpCode,
) -> #(Int, Dict(Register, Int)) {
  let val = case operand {
    Combo(val) -> regs |> get_combo_val(val)
    _ -> panic
  }
  let res = val % 8
  #(res, regs)
}

fn get_combo_val(regs: Dict(Register, Int), val: Int) -> Int {
  case val {
    _ if val >= 0 && val <= 3 -> val
    4 -> regs |> get_reg(A)
    5 -> regs |> get_reg(B)
    6 -> regs |> get_reg(C)
    _ -> -1
  }
}

fn get_reg(regs: Dict(Register, Int), k: Register) -> Int {
  let assert Ok(v) = regs |> dict.get(k)
  v
}

fn update_reg(
  regs: Dict(Register, Int),
  k: Register,
  v: Int,
) -> Dict(Register, Int) {
  regs |> dict.upsert(k, fn(_) { v })
}
