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


## Lab00 — Standalone Sanity Check: PASS

The first standalone cisc68k lab completed successfully.

Program:

```text
lab00.c
  -> writes "Hi\n"
```

Execution path:

```text
68k toolchain
    ->
rom.hex
    ->
testbench ROM
    ->
fx68k
    ->
68000 bus
    ->
write-only monitor
    ->
host console
```

Observed output:

```text
Hi
RESULT: lab00 PASS
```

The simulation also generated:

```text
logs/lab00/lab00.vcd
```

with a waveform size of about 122 kB, small enough to keep full VCD tracing enabled for these early labs.

Useful observations from the temporary bus trace used during bring-up:

- reset SP fetched as `0x00020000`
- reset PC fetched as `0x00000100`
- supervisor program fetches used `FC=110`
- supervisor data accesses used `FC=101`
- `JSR` pushed the return address into RAM near `0x01FFFC`
- `RTS` read the return address back
- byte writes duplicated the byte across `oEdb` while `UDS/LDS` selected the active lane
- monitor writes reached `0xF00000`

The temporary console bus trace was removed after validation. VCD + Surfer is now the normal inspection path.

This completes the infrastructure sanity check. The next work can focus on learning the 68000 rather than building the simulator.
