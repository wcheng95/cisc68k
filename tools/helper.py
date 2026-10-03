#!/usr/bin/env python3

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a big-endian 68k binary image to 16-bit $readmemh words."
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    data = args.input.read_bytes()
    if len(data) & 1:
        data += b"\x00"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="ascii") as out:
        for i in range(0, len(data), 2):
            word = (data[i] << 8) | data[i + 1]
            out.write(f"{word:04x}\n")


if __name__ == "__main__":
    main()
