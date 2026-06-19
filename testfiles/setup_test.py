#!/usr/bin/env python3
"""
setup_test.py

Generates all test files (weights, biases, sigmoid LUT, and test images)
for a fixed-point neural network hardware simulation.

Usage:
    python3 setup_test.py [--out-dir DIR]

Network architecture (configurable via the CONFIG constants below):
    Input  : 28 x 28 image            (784 values)
    Layer 1: 784 -> HIDDEN_SIZE        (default 15)
    Layer 2: HIDDEN_SIZE -> OUTPUT_SIZE (default 10)

All values are written as 32-bit fixed-point hex (Q16.16 by default),
one value per line, matching the format expected by the HDL testbench.
"""

import argparse
import math
import random
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
IMAGE_DIM = 28                          # image is IMAGE_DIM x IMAGE_DIM
INPUT_SIZE = IMAGE_DIM * IMAGE_DIM      # 784
HIDDEN_SIZE = 15
OUTPUT_SIZE = 10

SIGN_BITS = 1                           # Q15.16 fixed point:
INT_BITS = 15                           #   1 sign bit + 15 integer bits +
FRAC_BITS = 16                          #   16 fractional bits = 32 bits total
WORD_BITS = SIGN_BITS + INT_BITS + FRAC_BITS  # 32

WEIGHT_RANGE = 0.5                      # weights ~ U(-0.5, 0.5)
BIAS_RANGE = 0.1                        # biases  ~ U(-0.1, 0.1)

RANDOM_SEED = 42

SIGMOID_LUT_SIZE = 256
SIGMOID_X_MIN, SIGMOID_X_MAX = -8.0, 8.0


# ---------------------------------------------------------------------------
# Fixed point helpers
# ---------------------------------------------------------------------------
def float_to_fixed(value: float, frac_bits: int = FRAC_BITS, word_bits: int = WORD_BITS) -> int:
    """Convert a float to an unsigned word_bits-bit two's-complement fixed-point integer."""
    scale = 1 << frac_bits
    fixed = int(round(value * scale))

    max_val = 1 << (word_bits - 1)
    if fixed >= max_val or fixed < -max_val:
        raise ValueError(
            f"Value {value} overflows {word_bits}-bit Q{word_bits - frac_bits}.{frac_bits} format"
        )

    if fixed < 0:
        fixed += 1 << word_bits
    return fixed


def fixed_to_float(fixed: int, frac_bits: int = FRAC_BITS, word_bits: int = WORD_BITS) -> float:
    """Inverse of float_to_fixed. Handy for sanity-checking generated .hex files."""
    if fixed >= (1 << (word_bits - 1)):
        fixed -= 1 << word_bits
    return fixed / (1 << frac_bits)


def write_hex_file(path: Path, values, word_bits: int = WORD_BITS) -> None:
    """Write integer values as zero-padded hex, one per line."""
    hex_digits = word_bits // 4
    with open(path, "w") as f:
        for val in values:
            f.write(f"{val:0{hex_digits}x}\n")
    print(f"  wrote {path.name:<24s} ({len(values)} values)")


# ---------------------------------------------------------------------------
# 1. Sigmoid lookup table
# ---------------------------------------------------------------------------
def generate_sigmoid_lut(out_dir: Path) -> None:
    """Sigmoid sampled uniformly over [SIGMOID_X_MIN, SIGMOID_X_MAX]."""
    values = []
    for i in range(SIGMOID_LUT_SIZE):
        x = SIGMOID_X_MIN + i * (SIGMOID_X_MAX - SIGMOID_X_MIN) / SIGMOID_LUT_SIZE
        sigmoid_val = 1.0 / (1.0 + math.exp(-x))
        values.append(float_to_fixed(sigmoid_val))
    write_hex_file(out_dir / "sigmoid_lut.hex", values)


# ---------------------------------------------------------------------------
# 2. Weights & biases
# ---------------------------------------------------------------------------
def generate_weights_biases(out_dir: Path) -> None:
    rng = random.Random(RANDOM_SEED)  # local RNG instance -> deterministic & isolated

    def rand_layer(n_values: int, lo: float, hi: float):
        return [float_to_fixed(rng.uniform(lo, hi)) for _ in range(n_values)]

    # Layer 1: INPUT_SIZE -> HIDDEN_SIZE
    write_hex_file(
        out_dir / "layer1_weights.hex",
        rand_layer(INPUT_SIZE * HIDDEN_SIZE, -WEIGHT_RANGE, WEIGHT_RANGE),
    )
    write_hex_file(
        out_dir / "layer1_biases.hex",
        rand_layer(HIDDEN_SIZE, -BIAS_RANGE, BIAS_RANGE),
    )

    # Layer 2: HIDDEN_SIZE -> OUTPUT_SIZE
    write_hex_file(
        out_dir / "layer2_weights.hex",
        rand_layer(HIDDEN_SIZE * OUTPUT_SIZE, -WEIGHT_RANGE, WEIGHT_RANGE),
    )
    write_hex_file(
        out_dir / "layer2_biases.hex",
        rand_layer(OUTPUT_SIZE, -BIAS_RANGE, BIAS_RANGE),
    )


# ---------------------------------------------------------------------------
# 3. Test images (28x28 = 784 values each)
# ---------------------------------------------------------------------------
def upscale_pattern(pattern_8x8, target_dim: int = IMAGE_DIM):
    """Nearest-neighbour upscale an 8x8 binary pattern to target_dim x target_dim."""
    src_dim = 8
    out = []
    for r in range(target_dim):
        src_r = min(src_dim - 1, r * src_dim // target_dim)
        for c in range(target_dim):
            src_c = min(src_dim - 1, c * src_dim // target_dim)
            out.append(pattern_8x8[src_r * src_dim + src_c])
    return out


# Simplified digit shapes, defined once at 8x8 and upscaled to IMAGE_DIM x IMAGE_DIM
# so they stay easy to read/edit while matching the new 28x28 input size.
DIGIT_PATTERNS_8x8 = {
    "0": [
        0, 1, 1, 1, 1, 1, 1, 0,
        1, 1, 0, 0, 0, 0, 1, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 0, 0, 0, 0, 1, 1,
        0, 1, 1, 1, 1, 1, 1, 0,
    ],
    "1": [
        0, 0, 0, 1, 1, 0, 0, 0,
        0, 0, 1, 1, 1, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0,
        0, 0, 0, 1, 1, 0, 0, 0,
        0, 0, 0, 1, 1, 0, 0, 0,
        0, 0, 0, 1, 1, 0, 0, 0,
        0, 0, 0, 1, 1, 0, 0, 0,
        1, 1, 1, 1, 1, 1, 1, 1,
    ],
    "5": [
        1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 0, 0, 0, 0, 0, 0,
        1, 1, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 1, 1, 1, 0, 0,
        0, 0, 0, 0, 0, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 1, 1,
        1, 1, 0, 0, 0, 1, 1, 0,
        0, 1, 1, 1, 1, 1, 0, 0,
    ],
}


def generate_test_images(out_dir: Path) -> None:
    n = INPUT_SIZE

    write_hex_file(out_dir / "test_zeros.hex", [0] * n)
    write_hex_file(out_dir / "test_ones.hex", [float_to_fixed(1.0)] * n)

    checkerboard = [float_to_fixed(1.0 if i % 2 == 0 else -1.0) for i in range(n)]
    write_hex_file(out_dir / "test_checkerboard.hex", checkerboard)

    gradient = [float_to_fixed((i / (n - 1)) * 2.0 - 1.0) for i in range(n)]
    write_hex_file(out_dir / "test_gradient.hex", gradient)

    for digit, pattern in DIGIT_PATTERNS_8x8.items():
        upscaled = upscale_pattern(pattern)
        fixed = [float_to_fixed(float(v)) for v in upscaled]
        write_hex_file(out_dir / f"test_digit_{digit}.hex", fixed)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(description="Generate test files for the NN hardware simulation")
    parser.add_argument(
        "--out-dir", type=Path, default=Path("."), help="Output directory for .hex files (default: current dir)"
    )
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print(f"Generating test files for a {IMAGE_DIM}x{IMAGE_DIM} ({INPUT_SIZE}-input) network")
    print(f"Architecture: {INPUT_SIZE} -> {HIDDEN_SIZE} -> {OUTPUT_SIZE}, "
          f"Q{INT_BITS}.{FRAC_BITS} fixed point ({SIGN_BITS} sign + {INT_BITS} int "
          f"+ {FRAC_BITS} frac = {WORD_BITS} bits)")
    print("=" * 60)

    print("\n1. Sigmoid LUT")
    generate_sigmoid_lut(args.out_dir)

    print("\n2. Weights & biases")
    generate_weights_biases(args.out_dir)

    print("\n3. Test images")
    generate_test_images(args.out_dir)

    print("\n" + "=" * 60)
    print("Done. Files written to:", args.out_dir.resolve())
    print("=" * 60)


if __name__ == "__main__":
    main()
