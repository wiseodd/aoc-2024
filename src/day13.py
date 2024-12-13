from typing import Tuple
import numpy as np


def main():
    with open("data/day13_input.txt", "r") as f:
        content = f.read().strip()

    total_part1 = 0
    total_part2 = 0

    for block in content.split("\n\n"):
        [button_a, button_b, prize] = block.splitlines()
        a1, a2 = extract_button(button_a)
        b1, b2 = extract_button(button_b)
        p1, p2 = extract_prize(prize)

        total_part1 += np.array([3, 1], dtype=int) @ sol_numpy(
            a1, a2, b1, b2, p1, p2, offset=0
        )
        total_part2 += np.array([3, 1], dtype=int) @ sol_numpy(
            a1, a2, b1, b2, p1, p2, offset=10000000000000
        )

    print(total_part1)
    print(total_part2)


def sol_numpy(a1, a2, b1, b2, p1, p2, offset=0):
    A = np.array([[a1, b1], [a2, b2]])
    b = np.array([p1 + offset, p2 + offset])
    x = np.linalg.solve(A, b)

    if round(x[0], 2).is_integer() and round(x[1], 2).is_integer():
        return x.round().astype(int)
    else:
        return np.zeros(2, dtype=int)


def extract_button(line: str) -> Tuple[int, int]:
    cols = line.split(" ")
    return int(cols[2][2:-1]), int(cols[3][2:])


def extract_prize(line: str) -> Tuple[int, int]:
    cols = line.split(" ")
    return int(cols[1][2:-1]), int(cols[2][2:])


if __name__ == "__main__":
    main()
