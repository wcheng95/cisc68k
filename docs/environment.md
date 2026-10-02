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

Baseline machine:

```text
              +---------+
              |  fx68k  |
              +----+----+
                   |
             68000 bus boundary
                   |
        +----------+----------+
        |          |          |
       ROM        RAM      MONITOR
                              |
                              +--> host text output
```

The monitor is a single write-only memory-mapped register. It is not intended to model a UART.

Target repository shape:

```text
rtl/
    fx68k/
    rom.sv
    ram.sv
    monitor.sv
    system.sv
tb/
    system_tb.sv
rom/
    tiny survey programs
tools/
    helper scripts
docs/
Makefile
```

The first standalone sanity check is:

```text
rom.hex
    ->
ROM
    ->
fx68k
    ->
68000 bus write
    ->
MONITOR
    ->
"Hi"
```

followed by VCD inspection in Surfer.

### Peripheral Rule

A peripheral only needs as much internal behavior as required by the experiment.

However, everything visible at the 68000 boundary must be faithful enough for the architectural question being studied:

- address decoding
- data width and byte lanes
- read/write direction
- DTACK timing
- BERR behavior where relevant
- IPL levels where relevant
- interrupt acknowledge behavior where relevant
- vector behavior where relevant

Therefore, a timer used to study interrupts can be trivial internally, while its interrupt assertion and 68000 acknowledge behavior must be correct.

Mackerel-F remains a reference for proven integration details; it does not define the permanent survey architecture.


## Top-Level Machine Definition

The standalone survey machine is defined by:

```text
cisc68k.sv
```

This is the architectural top level for the project.

Its responsibilities are deliberately small:

- instantiate fx68k
- define the 24-bit memory map
- decode address regions
- connect ROM, RAM, and the write-only monitor
- route the 68000 bus signals
- generate/route DTACK and other bus termination signals
- expose and observe FC0-FC2 where relevant
- connect later experiment peripherals only when a survey topic requires them

Initial structure:

```text
cisc68k.sv
  |
  +-- fx68k
  +-- rom.sv
  +-- ram.sv
  +-- monitor.sv
```

Later additions should be narrow and experiment-driven:

```text
  +-- timer.sv
  +-- irq_source.sv
  +-- berr_device.sv
  +-- waitstate_device.sv
```

### Initial Memory Map

Use a simple, human-readable map:

```text
0x000000 - 0x00FFFF   ROM
0x010000 - 0x01FFFF   RAM
0xF00000               MONITOR
0xF10000 - 0xFFFFFF   reserved for future experiments
```

The exact sizes may be adjusted if an experiment requires it, but the map should remain simple and explicit.

### Function Codes

`FC0-FC2` are outputs from the 68000 that describe the type of current bus access.

They are not generic peripheral inputs that every device must implement.

Instead, `cisc68k.sv` should make them available to decode or special peripheral logic when the architectural experiment requires them.

Examples:

- distinguishing user vs supervisor access
- distinguishing program vs data access
- identifying CPU-space cycles
- recognizing interrupt-acknowledge cycles where `FC=111`

This keeps function-code handling faithful at the 68000 boundary without adding unnecessary peripheral complexity.

> `cisc68k.sv` defines the architectural boundary of the simulated 68000 machine.
