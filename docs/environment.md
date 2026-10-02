# Reference RTL Environment

## Core Decision

Use **fx68k as the reference 68000 core** and **Mackerel-F as a known-good reference integration**, not as the final survey workspace.

Mackerel-F is valuable because it shows a working memory map, UART path, timer, interrupt logic, and firmware/toolchain integration. However, the preferred long-term environment is a cleaner, self-contained RTL + testbench workspace containing only what the 68k survey needs.

Primary rule:

> Reuse proven Mackerel-F ideas and modules where useful, but keep the survey environment simpler than the full Mackerel system.

The CPU core is treated as a black box. We care about architectural state, instruction execution, bus transactions, exceptions, interrupts, and timing visible at the CPU boundary.

## Reference Core

fx68k is a SystemVerilog, cycle-accurate 68000-compatible core intended to reproduce the original external bus behavior closely.

For this project, its value is the visible 68000 boundary:

```text
address/data
AS
UDS/LDS
R/W
DTACK
BERR
FC
IPL
```

We do not need to study its internal RTL implementation.

## Mackerel-F as Reference

Mackerel-F already provides:

- fx68k integration
- ROM / BSRAM / SDRAM path
- UART
- timer
- interrupt logic
- SPI and other peripherals
- memory map and glue logic

Conceptually:

```text
                 +------------------+
                 |      68000       |
                 |      fx68k       |
                 +---------+--------+
                           |
                     CPU bus boundary
                           |
          +----------------+----------------+
          |                |                |
        memory            UART            timer
          |                                 |
          +----------------+----------------+
                           |
                     RTL simulator
                           |
                    VCD + console
```

Extra Mackerel-F peripherals may remain present; they do not need to be removed merely for minimalism.

## Repository Choice

Keep the full upstream `mackerel-68k` tree available as reference material.

Important areas:

```text
firmware/
pld/mackerel-f/
pld/mackerel-f/cores/fx68k/
```

Mackerel-F fetches its external cores with:

```bash
cd pld/mackerel-f
./get_cores.sh
```

Expected cores:

```text
fx68k
sdram-tang-nano-20k
tiny_spi
uart16550
```

A separate standalone fx68k clone is unnecessary for normal work.

## Hardware

Tang Nano 20K is optional only. FPGA deployment is not part of the current survey requirement.

Simulation is the primary platform.


## Preferred Survey Workspace

The eventual survey repo should contain a clean simulation-oriented environment rather than depend on the full Mackerel project layout.

Target shape:

```text
rtl/
    fx68k/
    selected support RTL
tb/
    cpu/system testbenches
rom/
    tiny survey programs
tools/
    helper scripts
docs/
Makefile
```

The workspace should support a simple loop:

```text
build tiny 68k program
    ->
load ROM image
    ->
run Verilator
    ->
print UART TX
    ->
inspect VCD in Surfer
```

Mackerel-F remains the reference for correctness and useful implementation details; it does not need to remain the permanent execution environment.
