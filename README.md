# Bilinear Image Scaler (Verilog)

A hardware image scaling module implemented in Verilog that performs **bilinear interpolation** to resize images from an input resolution (`Win x Hin`) to any output resolution (`Wout x Hout`), supporting both grayscale and RGB images.

## Overview

This module reads pixel data from `.hex` memory files, scales the image using bilinear interpolation, and writes the scaled result back out to `.hex` files. It is built as a synthesizable FSM (finite state machine) rather than a purely behavioral testbench-only design, so it reflects how this would map onto real hardware resources.

## Key Design Goals

- **Minimal hardware usage** — the design intentionally uses only **one multiplier**, reused sequentially across all interpolation terms and all color channels, instead of instantiating separate multipliers per channel or per weight term.
- **Multiplication avoidance for scaling steps** — rather than multiplying the pixel index by `scalex`/`scaley` every cycle to find the next input coordinate, the design **accumulates** by adding `scalex`/`scaley` to the running fixed-point coordinate (`xin`, `yin`) each step. This trades a multiply for an add.
- **Latency vs. area tradeoff** — because hardware is reused instead of duplicated, each output pixel takes multiple clock cycles to compute. This is a deliberate compromise: lower resource utilization at the cost of higher latency.

## How Bilinear Interpolation Works Here

For each output pixel, the module computes a fixed-point input coordinate `(xin, yin)` using a `Q8.8`-style fixed-point format:

- `x0 = xin[23:8]`, `y0 = yin[23:8]` → integer part (which input pixel to anchor to)
- `a = xin[7:0]`, `b = yin[7:0]` → fractional part (sub-pixel weight)

From these, four bilinear weights are derived:

| Weight | Meaning                          |
|--------|-----------------------------------|
| `wa`   | weight for bottom-right neighbor (`a*b`) |
| `wb`   | weight for bottom-left neighbor  |
| `wc`   | weight for top-right neighbor    |
| `wd`   | weight for top-left neighbor (I00)|

Each weight is computed **sequentially** using the single shared multiplier, and the result is accumulated into the output pixel across several clock cycles.

Edge handling is done via three flags:
- `rw` (right edge, not bottom row)
- `dw` (bottom row, not right edge)
- `last` (bottom-right corner)

These ensure the interpolation doesn't read out of bounds at image borders — it simply falls back to duplicating the nearest valid pixel.

## FSM State Breakdown

The core scaling logic runs as a 16-state FSM (`S0`–`S15`):

| States   | Purpose                          |
|----------|-----------------------------------|
| `S0`     | Compute next input coordinate (`xin`, `yin`) and output base address |
| `S1`     | Compute input memory address from integer coordinates |
| `S2`–`S6`| Compute `wa`, `wb`, `wc`, `wd` and accumulate the **Red** (or grayscale) channel |
| `S7`–`S10`| Repeat accumulation for the **Green** channel |
| `S11`–`S14`| Repeat accumulation for the **Blue** channel |
| `S15`    | Advance to next output pixel coordinate, or assert `done` when finished |

**For grayscale images (`CHANNELS = 1`)**, the FSM skips the Green and Blue stages entirely and only cycles through `S0`–`S6` and `S15` — reducing the per-pixel latency to just 7 active states instead of 16.

This state reuse is what allows a single multiplier and a single accumulate path to serve all three channels (or just one, for grayscale) without duplicating datapath hardware.

## Module Parameters

| Parameter   | Description                        | Example |
|-------------|-------------------------------------|---------|
| `Win`       | Input image width                  | 275     |
| `Hin`       | Input image height                 | 183     |
| `Wout`      | Output image width                 | 2160    |
| `Hout`      | Output image height                | 1800    |
| `CHANNELS`  | `1` = grayscale, `3` = RGB          | 1       |

## Ports

| Port    | Direction | Description                        |
|---------|-----------|--------------------------------------|
| `clk`   | input     | Clock                                |
| `rst`   | input     | Synchronous reset                    |
| `done`  | output    | Asserted high when scaling completes |
| `xout`  | output    | Current output column being written  |
| `yout`  | output    | Current output row being written     |

## File I/O

**Inputs (read via `$readmemh`):**
- `inputR.hex`, `inputG.hex`, `inputB.hex` — one byte per pixel, row-major order

**Outputs (written via `$writememh` once `done` is asserted):**
- `outputR.hex`, `outputG.hex`, `outputB.hex`

## Simulation

A testbench (`testbench.v`) instantiates the module with sample dimensions and clocks it until `done` is asserted:
