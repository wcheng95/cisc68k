# Simulation Checkpoint

## What Has Been Proven

The reference Mackerel-F environment successfully runs fx68k in full-system simulation under Verilator.

A minimal ROM program executed through the real Mackerel-F integration and produced:

```text
Hi\r\n
```

through the 16550 UART path.

That proved the important chain:

```text
rom.hex
    ->
fx68k
    ->
68000 bus
    ->
memory-mapped output device
    ->
host-visible result
```

This is enough evidence to proceed with a smaller standalone survey machine.

## Current Tool Baseline

### Verilator

Use Verilator for full fx68k system simulation.

Known useful options:

```text
--binary
--timing
--trace-vcd
--no-assert-case
-Wno-fatal
-Wno-BLKANDNBLK
-Wno-UNOPTFLAT
```

### Icarus Verilog

Icarus remains useful for small isolated RTL tests, but it is not the preferred simulator for the full fx68k system because of SystemVerilog compatibility limitations.

### Surfer

Surfer is the waveform viewer.

Current flow:

```text
Verilator
    ->
native simulation executable
    ->
console output + VCD
    ->
Surfer
```

## VCD

The testbench can request waveform output with:

```systemverilog
$dumpfile("cisc68k.vcd");
$dumpvars(0, cisc68k_tb);
```

and Verilator must be built with:

```text
--trace-vcd
```

The waveform should be used to inspect the 68000-visible boundary:

- address
- data
- AS
- UDS/LDS
- R/W
- DTACK
- BERR
- FC0-FC2
- IPL0-IPL2 when relevant

## Final Standalone Simulator

The planned standalone environment was completed and became the permanent lab machine:

```text
tbench/cisc68k_tb.sv
  |
  +-- fx68k
  +-- ROM
  +-- RAM
  +-- monitor
  +-- IRQ source
  +-- MMIO register
```

The default observation path evolved from VCD-first bring-up to the compact external-bus trace:

```text
make LAB=labNN
    ->
logs/labNN/labNN.trace
```

VCD remains available with `MODE=vcd` or `MODE=both` when RTL timing detail is needed.

## Archive Status

**Complete — 2026-10-14.**

The standalone machine supported Labs 00–12 through the final CISC-vs-RISC capstone. Mackerel-F remains reference material only; no further simulator construction is planned.

