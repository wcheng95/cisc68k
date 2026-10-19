# Environment

## Core Decision

Use **fx68k as the reference 68000 core**.

Use **Mackerel-F as a known-good reference workspace**, not as the permanent survey machine.

Build our own **standalone simulation workspace** around fx68k for the actual architecture survey.

The CPU core is treated as a black box unless an architectural question requires looking inside it. The main observation boundary is the original 68000 interface:

```text
address/data
AS
UDS/LDS
R/W
DTACK
BERR
FC0-FC2
IPL0-IPL2
```

The project studies 68000 behavior, not peripheral implementation.

---

## Mackerel Reference Workspace

Keep the full upstream `mackerel-68k` repository available as reference material.

Useful areas:

```text
firmware/
pld/mackerel-f/
pld/mackerel-f/cores/fx68k/
```

Mackerel-F provides a proven integration of:

- fx68k
- ROM
- BSRAM / SDRAM
- UART
- timer
- interrupts
- SPI and other peripherals
- address decoding and bus glue
- firmware/toolchain integration

Its external cores are fetched with:

```bash
cd pld/mackerel-f
./get_cores.sh
```

Typical fetched cores:

```text
fx68k
sdram-tang-nano-20k
tiny_spi
uart16550
```

Mackerel-F has already served its main purpose for this project:

- prove fx68k can be integrated into a working system
- provide examples of reset, ROM, memory, UART, timer, and interrupt wiring
- provide a working 68k firmware/toolchain reference
- provide a known-good comparison point when our standalone environment behaves unexpectedly

We do **not** need to reproduce its complete machine.

Tang Nano 20K hardware remains optional. The survey is simulation-first.

---

## Standalone Survey and Simulation Workspace

The final survey environment is small, explicit, and easy to understand.

### Top Level

The simulation top is:

```text
tbench/cisc68k_tb.sv
```

It instantiates fx68k and owns the standalone survey machine around the CPU boundary: ROM, RAM, address decoding, DTACK routing, trace generation, and the small experiment peripherals used by the labs.

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

### Final Repository Shape

```text
fx68k/             upstream/reference CPU RTL and micro/nano ROM data
tbench/            standalone simulation machine and peripherals
labs/common/       reset/startup and linker script
labs/lab00-lab12/  cumulative survey labs
tools/             build helper
docs/              architecture and workflow notes
Makefile           build/run/trace control
```

### Memory Map

The 68000 has a 24-bit byte address space:

```text
0x000000 - 0xFFFFFF
```

Initial map:

```text
0x000000 - 0x00FFFF   ROM
0x010000 - 0x01FFFF   RAM
0xF00000               MONITOR
0xF00010               IRQ trigger (survey peripheral)
0xF00020               16-bit MMIO register
0xF10000 - 0xFFFFFF   reserved for future experiments
```

ROM contains reset vectors and survey code and is loaded from:

```text
rom.hex
```

RAM is plain scratch memory for:

- stack
- data
- temporary storage

No SDRAM controller or cache is required.

### Monitor

The baseline I/O device is a single write-only memory-mapped monitor register.

Example behavior:

```text
write byte 'H' -> host prints H
write byte 'i' -> host prints i
```

It is intentionally **not** a UART.

First standalone sanity check:

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
Hi
```

The same run should generate a VCD for inspection in Surfer.

### Peripheral Rule

Add a peripheral only when it helps answer a 68000 architecture question.

Examples:

```text
timer              -> interrupt behavior
irq_source         -> IPL / acknowledge / vectors
waitstate_device   -> DTACK and wait states
berr_device        -> bus-error exception
input register     -> memory-mapped read behavior
```

Peripheral internals may be deliberately simple.

What must be correct is the behavior visible at the **68000 boundary**, including where relevant:

- address decoding
- data width
- UDS/LDS byte lanes
- read/write direction
- DTACK timing
- BERR behavior
- IPL levels
- interrupt acknowledge
- vector behavior
- function-code interpretation

The project studies the 68000, not the peripherals.

### Function Codes

`FC0-FC2` are outputs from the CPU describing the current bus address space.

They are not features every peripheral must implement.

The testbench exposes them to decode or experiment logic only when needed, for example:

- user vs supervisor accesses
- program vs data accesses
- CPU-space cycles
- interrupt-acknowledge cycles where `FC=111`

### Simulation Flow

Use Verilator for the standalone full-system simulator.

```text
68k source
    ->
cross assembler/compiler
    ->
lab hex image
    ->
tbench/cisc68k_tb.sv + fx68k
    ->
Verilator
    ->
console result + compact bus trace
    ->
optional VCD / Surfer
```

The first goal is not a complete computer. It is a transparent machine in which each 68000-visible transaction is easy to explain.
