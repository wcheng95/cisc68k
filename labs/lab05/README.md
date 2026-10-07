# Lab05 — Condition Codes and Control Flow

## Goal

Study how the 68000 sets condition codes and how branch instructions interpret them.

Focus:

```text
N  negative
Z  zero
V  overflow
C  carry
X  extend

CMP
signed vs unsigned branches
DBRA
```

Expected output:

```text
05
```

No new hardware is added.

## CCR / SR

The low five condition bits are:

```text
X N Z V C
```

Lab05 stores the full 16-bit status register after several operations so the low condition bits can be inspected in RAM.

Result locations:

```text
0x0100A0   after 5 - 5
0x0100A2   after 0 - 1
0x0100A4   after 0x7FFF + 1 (word)
0x0100A6   after 0xFFFF + 1 (word)
```

Only the low CCR bits are the focus here.

## Case 1 — Zero

```asm
moveq  #5,%d0
subq.l #5,%d0
```

Result:

```text
D0 = 0
Z = 1
```

## Case 2 — Negative

```asm
moveq  #0,%d1
subq.l #1,%d1
```

Result:

```text
D1 = 0xFFFFFFFF
N = 1
```

## Case 3 — Signed Overflow

```asm
move.w #0x7fff,%d2
addq.w #1,%d2
```

Low word result:

```text
0x7FFF + 1 = 0x8000
```

Interpreted as signed 16-bit:

```text
+32767 -> -32768
```

So:

```text
V = 1
N = 1
```

## Case 4 — Unsigned Carry

```asm
move.w #0xffff,%d3
addq.w #1,%d3
```

Low word wraps:

```text
0xFFFF + 1 = 0x0000
```

Expected:

```text
Z = 1
C = 1
X = 1
```

## Signed vs Unsigned Compare

```asm
move.w #0xffff,%d4
moveq  #1,%d5
cmp.w  %d5,%d4
```

`CMP source,destination` behaves like:

```text
destination - source
```

without storing the result.

The same bit pattern `0xFFFF` can mean:

```text
signed     -1
unsigned   65535
```

Therefore both of these statements are true:

```text
signed:    -1 < 1
unsigned: 65535 > 1
```

Lab05 proves that with:

```asm
blt.s   signed_less
bhi.s   unsigned_higher
```

RAM markers:

```text
0x0100B0 = 0x11   signed BLT taken
0x0100B1 = 0x22   unsigned BHI taken
```

If a check fails, the corresponding byte is `0xEE`.

## DBRA Loop

```asm
moveq #2,%d6
moveq #0,%d7

loop:
    addq.l #1,%d7
    dbra   %d6,loop
```

`DBRA` decrements the low word of D6 and branches until it reaches `-1`.

Starting from 2, the loop body runs three times.

Expected:

```text
D7 = 3
0x0100B4 = 0x00000003
```

## Build

```bash
make clean
make LAB=lab05
```

Disassemble:

```bash
make disasm LAB=lab05
```

Waveform:

```bash
surfer logs/lab05/lab05.vcd
```

## What to Inspect

RAM:

```text
0x0100A0-0x0100A7   saved SR snapshots
0x0100B0             signed branch result
0x0100B1             unsigned branch result
0x0100B4-0x0100B7   DBRA loop count
```

Useful VCD signals remain:

```text
byte_addr
iEdb
oEdb
ASn
UDSn
LDSn
eRWn
DTACKn
```

## Questions

- What is the difference between carry and overflow?
- Why can `BLT` and `BHI` both be true for the same two bit patterns?
- Does `CMP` store a result?
- What does `DBRA` test for?
- Which condition code is special about `X`, and why might it matter for multiword arithmetic later?
