# Lab09 — External Bus

## Goal

Read the 68000 external bus directly through the compact trace.

This first bus lab adds no new hardware. It deliberately generates bus cycles that make the original 16-bit bus easy to recognize:

```text
instruction fetch
byte write at even address
byte write at odd address
word write/read
long write/read
stack traffic from JSR/RTS
MMIO writes
```

Expected output:

```text
09
```

## Trace Format

Default:

```bash
make clean
make LAB=lab09
cat logs/lab09/lab09.trace
```

Each line is:

```text
<cycle> <R|W> [<addr>] <data> <UDS><LDS> <FC>
```

Example:

```text
 12 W [010100] 7878 01 101
```

The address shown is the full byte address reconstructed by the testbench.

## Function Codes

For this lab, the important supervisor-mode function codes are:

```text
FC=110   supervisor program
FC=101   supervisor data
```

Instruction fetches should therefore appear as `110`.

RAM, stack, and MMIO data transfers should appear as `101`.

## Byte Lanes

The original 68000 has a 16-bit external data bus and no external A0 pin.

The byte lane is selected by active-low strobes:

```text
even byte address   UDS=0 LDS=1
odd byte address    UDS=1 LDS=0
word transfer       UDS=0 LDS=0
```

Lab09 performs:

```asm
move.b  %d0,0x010100
move.b  %d0,0x010101
```

With:

```text
D0 = 0x12345678
```

both byte operations use:

```text
D0[7:0] = 0x78
```

but they use different byte lanes.

## Word Transfer

```asm
move.w  %d0,0x010102
```

uses:

```text
D0[15:0] = 0x5678
```

and should require one 16-bit bus cycle:

```text
address 0x010102
UDS/LDS = 00
data = 0x5678
```

## Long Transfer

```asm
move.l  %d0,0x010104
```

moves:

```text
0x12345678
```

The original 68000 external bus is only 16 bits wide, so the longword requires two word bus cycles:

```text
0x010104 -> 0x1234
0x010106 -> 0x5678
```

This is a direct external-bus view of a 32-bit architectural operation being implemented over a 16-bit bus.

## Reads

The lab then performs:

```asm
move.b  0x010100,%d1
move.w  0x010102,%d2
move.l  0x010104,%d3
```

The trace should show corresponding `R` cycles.

Remember:

```text
MOVE.B to Dn changes only Dn[7:0]
MOVE.W to Dn changes only Dn[15:0]
MOVE.L to Dn changes all 32 bits
```

## Stack Traffic

```asm
jsr bus_subroutine
...
bus_subroutine:
    nop
    rts
```

`JSR` pushes a 32-bit return PC.

On the 16-bit bus that becomes two word writes to the supervisor stack.

`RTS` later reads the return PC back from the stack.

Look for accesses near:

```text
0x01FFFx
```

with:

```text
FC=101
```

## Program vs Data

The same physical ROM/RAM system therefore shows two visibly different access classes:

```text
instruction fetch     FC=110
data/stack access     FC=101
```

This is why the FC signals are useful externally even though the address bus itself does not say "instruction" or "data."

## MMIO

The final writes to:

```text
0xF00000
```

print:

```text
09
```

Those are ordinary supervisor-data bus writes from the CPU's point of view.

## What to Inspect

Find these in the trace:

```text
0x010100   even byte write
0x010101   odd byte write
0x010102   word write/read
0x010104   long high word
0x010106   long low word
0x01FFFx   JSR/RTS stack traffic
0xF00000   monitor MMIO
```

Also compare:

```text
FC=110   instruction fetches
FC=101   data accesses
```

## Not Yet in This First Pass

Lab09 will add these only after the baseline bus behavior is understood:

```text
DTACK wait states
BERR
```

Those change bus-cycle completion rather than the basic byte/word/long transfer rules.

## Questions

- Why can the trace reconstruct a byte address even though the original 68000 has no external A0 pin?
- Why do the two byte writes use different strobes but the same low byte of D0?
- Why does a word take one bus cycle?
- Why does a longword take two?
- Why are instruction fetches FC=110 while stack/data accesses are FC=101?
- What bus traffic does JSR add beyond the instruction fetches?
