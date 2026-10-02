# Verilator Cheat Sheet

Practical reference for the cisc68k RTL simulation workflow.

## What Verilator Does

Verilator translates Verilog/SystemVerilog into C++, builds a native host executable, and runs the simulation as software.

Typical flow:

```text
RTL + testbench
    ->
Verilator
    ->
generated C++
    ->
native executable
    ->
console output + VCD
```

The generated executable normally appears under:

```text
obj_dir/
```

For the current top module:

```text
obj_dir/Vmackerel_f_tb
```

## Minimal Full-System Build

Current useful options:

```bash
verilator \
  --binary \
  --timing \
  --trace-vcd \
  --no-assert-case \
  -Wno-fatal \
  -Wno-BLKANDNBLK \
  -Wno-UNOPTFLAT \
  -Icores/uart16550/rtl/verilog \
  --top-module mackerel_f_tb \
  mackerel_f_tb.sv \
  mackerel_f.v \
  boot_signal.v \
  bus_watchdog.v \
  irq_encoder.v \
  sdram_cache.v \
  sdram_controller.v \
  uart.v \
  timer.v \
  ws2812.v \
  spi.v \
  cores/tiny_spi/rtl/verilog/tiny_spi.v \
  cores/sdram-tang-nano-20k/src/sdram.v \
  cores/fx68k/fx68k.sv \
  cores/fx68k/fx68kAlu.sv \
  cores/fx68k/uaddrPla.sv \
  cores/uart16550/rtl/verilog/*.v
```

Run:

```bash
./obj_dir/Vmackerel_f_tb
```

## Important Options

### `--binary`

Build a runnable simulation executable automatically.

Without it, Verilator may only generate intermediate C++/model files.

### `--timing`

Enable SystemVerilog timing constructs such as:

```systemverilog
#100;
always #5 clk = ~clk;
```

Required by our testbench clock/timing code.

### `--trace-vcd`

Enable VCD waveform tracing.

The testbench must still request dumping with:

```systemverilog
$dumpfile("mackerel_f_tb.vcd");
$dumpvars(0, mackerel_f_tb);
```

### `--top-module NAME`

Select the simulation top explicitly.

Example:

```bash
--top-module mackerel_f_tb
```

### `-I<dir>`

Add an HDL include directory.

Example:

```bash
-Icores/uart16550/rtl/verilog
```

Useful for includes such as `timescale.v`.

## Warning/Compatibility Options Used Here

### `-Wno-fatal`

Do not stop the build merely because warnings exist.

Useful with older RTL that triggers many width/style warnings.

### `-Wno-BLKANDNBLK`

Suppress Verilator's complaint about blocking and nonblocking assignments involving different members of the same aggregate.

Needed by fx68k.

### `-Wno-UNOPTFLAT`

Suppress combinational-loop optimization warnings that fx68k triggers.

### `--no-assert-case`

Disable runtime assertions generated from `unique` / `priority` case statements.

Needed because fx68k can transiently present unmatched values during initialization.

## First Standalone Sanity Check

The first standalone cisc68k simulation should reproduce:

```text
ROM
  ->
fx68k
  ->
68000 bus
  ->
UART
  ->
TX pin
  ->
testbench decoder
  ->
Hi\r\n
```

Expected console output:

```text
UART: 0x48 'H'
UART: 0x69 'i'
UART: 0x0d
UART: 0x0a

RESULT: UART Hi test PASSED
```

## VCD from the Testbench

Add:

```systemverilog
initial begin
    $dumpfile("mackerel_f_tb.vcd");
    $dumpvars(0, mackerel_f_tb);
end
```

Then run the executable normally.

The VCD appears in the current working directory.

## Useful Cleanup

Remove generated Verilator output:

```bash
rm -rf obj_dir
```

Remove waveform:

```bash
rm -f *.vcd
```

## Common Failure Patterns

### `Need --binary, --cc ...`

Usually means the shell line continuation failed.

Make sure the backslash is the final character:

```bash
verilator \
  --binary \
  ...
```

Do not leave spaces after `\`.

### `Cannot find file containing module`

Usually one of:

- missing RTL file in the file list
- missing include directory
- accidental Unicode/non-breaking space in the shell command

### `Exiting due to N warning(s)`

Add:

```bash
-Wno-fatal
```

### Runtime `unique case` assertion

Add:

```bash
--no-assert-case
```

### fx68k `BLKANDNBLK`

Add:

```bash
-Wno-BLKANDNBLK
```

## Recommended Project Practice

For cisc68k:

- keep source/file lists in a Makefile rather than retyping the long command
- keep upstream fx68k unchanged
- use Verilator for full-system simulation
- use Icarus only where it is simpler for small unit tests
- generate VCD only when waveform inspection is useful
