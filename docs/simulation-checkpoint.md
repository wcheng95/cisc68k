# Simulation Checkpoint

## Known-Good Unit Tests

Mackerel-F's existing unit-style simulations work on macOS with Homebrew Icarus.

The Makefile was adjusted to use PATH-based tools:

```make
IVERILOG ?= iverilog
VVP      ?= vvp
```

Passing tests:

- timer test
- SDRAM cache test

The timer test covers reset defaults, register access, frequency selection, IRQ assertion/acknowledge, disable behavior, and DTACK.

The cache test covers representative reads and writes.

Both can emit VCD waveforms.

## Waveform Viewer

Surfer works well on macOS.

Typical flow:

```text
RTL
 -> Icarus or Verilator
 -> VCD
 -> Surfer
```

## Icarus vs Verilator

Icarus is excellent for small unit tests but cannot elaborate fx68k's SystemVerilog unpacked structs.

Verilator successfully builds the full Mackerel-F + fx68k design when used with:

```text
--binary
--timing
--trace-vcd
--no-assert-case
-Wno-fatal
-Wno-BLKANDNBLK
-Wno-UNOPTFLAT
```

The generated executable is a native host program under `obj_dir/`.

## Full-System Milestone

A minimal ROM program was built that initializes the real Mackerel-F 16550 UART and transmits:

```text
Hi\r\n
```

The full path passed:

```text
68000 code in ROM
    ->
fx68k
    ->
Mackerel-F bus fabric
    ->
16550 UART RTL
    ->
serial TX waveform
    ->
testbench decoder
    ->
Hi\r\n
```

This is the first full-system 68k simulation milestone.

## VCD

The full-system testbench can use:

```systemverilog
$dumpfile("mackerel_f_tb.vcd");
$dumpvars(0, mackerel_f_tb);
```

Build Verilator with `--trace-vcd`, run the generated executable, then open the resulting VCD with Surfer.

## Bootloader Experiment

Replacing the small ROM with the full Mackerel bootloader did not yet produce UART output.

The Hi test proves CPU/ROM/UART operation; the remaining difference is the broader memory/system path, especially SDRAM.

A simple behavioral SDRAM model was started, but the bootloader path is not yet validated.

This is not blocking the architecture survey. TX-only ROM programs are sufficient for the planned CISC labs.

## Current Baseline

Known good:

- native Apple-Silicon Mackerel cross toolchain
- cleaned Mackerel-F firmware build
- timer simulation
- SDRAM-cache simulation
- full fx68k + Mackerel-F Verilator build
- UART TX full-system test
- VCD + Surfer workflow

Not required now:

- UART RX
- interactive terminal
- full bootloader simulation
- FPGA hardware
