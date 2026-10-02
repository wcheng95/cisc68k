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

## Standalone Simulator: Next Milestone

The next environment is intentionally smaller than Mackerel-F:

```text
cisc68k.sv
  |
  +-- fx68k
  +-- ROM
  +-- RAM
  +-- write-only MONITOR
```

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

The same run should generate a useful VCD.

## Current Status

Known good:

- native Apple-Silicon 68k cross toolchain
- fx68k full-system simulation under Verilator
- host-visible output from 68000 code
- VCD generation path
- Surfer workflow

Next:

- build the standalone `cisc68k.sv` machine
- replace Mackerel-F memory/peripheral complexity with simple ROM, RAM, and monitor models
- use that machine for the architecture survey

Mackerel-F remains a reference workspace, not the permanent simulation environment.
