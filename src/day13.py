from typing import Tuple
import numpy as np


def main():
    arm_costs = np.array([3, 1], dtype=np.int32)

    with open("data/day13_input.txt", "r") as f:
        # with open("data/day13_input_toy.txt", "r") as f:
        content = f.read().strip()

    total_cost = 0

    for block in content.split("\n\n"):
        [button_a, button_b, prize] = block.splitlines()
        a11, a21 = extract_button(button_a)
        a12, a22 = extract_button(button_b)
        b1, b2 = extract_prize(prize)

        x = np.linalg.solve(
            np.array([[a11, a12], [a21, a22]], dtype=np.int32),
            np.array([b1, b2], dtype=np.int32),
        )

        print(x)

        if np.allclose(x.round(), x):
            # print(x)
            total_cost += x.astype(np.int32) @ arm_costs

    print(total_cost)


def extract_button(line: str) -> Tuple[int, int]:
    cols = line.split(" ")
    return int(cols[2][2:-1]), int(cols[3][2:])


def extract_prize(line: str) -> Tuple[int, int]:
    cols = line.split(" ")
    return int(cols[1][2:-1]), int(cols[2][2:])


if __name__ == "__main__":
    main()
