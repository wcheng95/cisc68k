# Lab01 — Registers and Operand Sizes

## Goal

Begin studying the 68000 programming model directly in assembly.

Lab01 adds no new hardware. It reuses the Lab00 machine and focuses on:

```text
D0       data register
A0       address register
MOVE.B   byte
MOVE.W   word
MOVE.L   longword
MOVEA.L  load an address register
```

Expected output:

```text
OK
RESULT: lab00 PASS
```

The testbench still uses the Lab00 completion message; the important new evidence is in RAM and the VCD.

## Program

```asm
move.l  #0x12345678,%d0

move.b  %d0,0x010000
move.w  %d0,0x010002
move.l  %d0,0x010004

movea.l #0x010010,%a0
move.l  #0x89abcdef,(%a0)
```

## What to Observe

### D0 is 32 bits

After:

```asm
move.l #0x12345678,%d0
```

the same register can be used with different operand sizes.

The stores should produce:

```text
0x010000   byte      0x78
0x010002   word      0x5678
0x010004   longword  0x12345678
```

This demonstrates that byte/word operations select part of the 32-bit data register.

### A0 is an address register

```asm
movea.l #0x010010,%a0
move.l  #0x89abcdef,(%a0)
```

loads a RAM address into A0, then uses A0 as a pointer.

Expected RAM contents:

```text
0x010010-0x010013   0x89ABCDEF
```

## Surfer

Useful signals:

```text
eab
oEdb
iEdb
ASn
UDSn
LDSn
eRWn
FC0-FC2
DTACKn
```

Look for the RAM writes at:

```text
0x010000
0x010002
0x010004
0x010010
```

The longword stores should require two 16-bit bus transfers because the MC68000 external data bus is 16 bits.

## Questions

- Why does `MOVE.B D0,...` store `0x78`?
- Why does `MOVE.W D0,...` store `0x5678`?
- How many bus cycles does `MOVE.L` require?
- What is the conceptual difference between D0 and A0?
- What does `(A0)` mean?
