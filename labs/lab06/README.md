# Lab06 — Exceptions and Vector Table

## Goal

Study how the original 68000 enters an exception, finds the handler through the vector table, builds an exception stack frame, and returns with `RTE`.

This first exception lab uses only:

```text
TRAP #0              vector 32
ILLEGAL              vector 4
RTE
```

No new hardware is added.

Expected output:

```text
06
```

## Vector Table

Each vector is one 32-bit handler address.

```text
vector 0    0x000000   initial supervisor SP
vector 1    0x000004   initial PC
vector 4    0x000010   illegal instruction
vector 32   0x000080   TRAP #0
```

`labs/common/start.S` supplies vectors 0 and 1.

Lab06 adds a `.vectors.lab06` input section. The linker appends `.vectors.*` directly after the common reset vectors, so the first lab-specific entry is vector 2.

## TRAP #0

```asm
trap #0
```

For `TRAP #n`:

```text
vector = 32 + n
```

Therefore `TRAP #0` uses vector 32 at address `0x000080`.

The handler records the exception frame and then executes:

```asm
rte
```

On the original 68000, the saved PC in this normal exception frame points to the next instruction, so execution resumes normally.

Success marker:

```text
0x0100C0 = 0x11
```

## Normal 68000 Exception Frame

For the normal group 1/2 frame used by these exceptions, the supervisor stack points at:

```text
SP+0   saved SR    word
SP+2   saved PC    long
```

Only SR and PC are present in this original-68000 short frame.

Lab06 saves the TRAP frame at:

```text
0x0100C4   saved SR
0x0100C6   saved PC
```

`RTE` restores the saved SR and PC from the exception frame.

## Illegal Instruction

```asm
illegal
```

uses vector 4 at:

```text
0x000010
```

The handler records its frame at:

```text
0x0100CA   saved SR
0x0100CC   saved PC
```

For the original 68000 group 1/2 exception frame, the saved PC points to the next instruction to execute. Therefore this lab's illegal-instruction handler can simply use `RTE`; it does not need to modify the stacked PC.

This is worth treating as a processor-generation detail rather than assuming every later 68k uses exactly the same exception-frame semantics.

Success marker:

```text
0x0100C1 = 0x22
```

Handler-entry markers:

```text
0x0100C2 = 0xA0   TRAP #0 handler ran
0x0100C3 = 0xA4   illegal-instruction handler ran
```

## Build

```bash
make clean
make LAB=lab06
```

Disassemble:

```bash
make disasm LAB=lab06
```

Waveform:

```bash
surfer logs/lab06/lab06.vcd
```

## What to Inspect

Vector fetches:

```text
0x000010   vector 4
0x000080   vector 32
```

RAM:

```text
0x0100C0-0x0100C3   flow/handler markers
0x0100C4-0x0100C9   TRAP exception frame copy
0x0100CA-0x0100D1   ILLEGAL exception frame copy
```

VCD:

```text
byte_addr
iEdb
oEdb
ASn
UDSn
LDSn
eRWn
DTACKn
FC0
FC1
FC2
```

Watch the CPU:

1. execute the exception-generating instruction,
2. write SR/PC to the supervisor stack,
3. read the handler address from the vector table,
4. execute the handler,
5. use `RTE` to restore execution.

## Questions

- Why is a vector an address rather than executable code?
- Why does `TRAP #0` use vector 32?
- What gets pushed automatically when the exception is taken?
- How is `RTE` different from `RTS`?
- Where does the original 68000 normal exception frame point when it saves PC?
