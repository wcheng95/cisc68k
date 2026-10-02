# Reference RTL Environment

## Core Decision

Use Mackerel-F as the reference system and fx68k as the reference 68000 core.

Primary rule:

> Reuse the existing system unless a concrete architecture question requires a change.

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

## Reference System

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
