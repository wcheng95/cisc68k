# Lab07 — Supervisor and User Mode

## Goal

Study the 68000 supervisor bit, privilege violation, supervisor-stack exception entry, and the limits of what supervisor/user mode protects.

Expected output:

```text
07
```

## Core Idea

The status register contains the supervisor bit:

```text
S = 1   supervisor mode
S = 0   user mode
```

After reset, the 68000 starts in supervisor mode.

Lab07 deliberately clears `S`, performs an ordinary RAM write in user mode, then executes the privileged `RESET` instruction.

## Enter User Mode

```asm
andi.w  #0xdfff,%sr
```

Bit 13 is `S`.

```text
0xDFFF = all ones except bit 13
```

So this clears only the supervisor bit and enters user mode.

The instruction is legal here because it is executed while still in supervisor mode.

## User-Mode Memory Access

Immediately after entering user mode:

```asm
move.b  #0x11,0x0100d0
```

This should succeed.

Important lesson:

> Supervisor/user mode by itself is not an MMU.

Our simple 68000 machine has no memory-protection hardware, so user-mode code can still access ordinary RAM and the monitor MMIO address.

## Privilege Violation

Then:

```asm
reset
```

`RESET` is privileged.

Executing it in user mode does not perform a reset. Instead the CPU takes:

```text
vector 8   privilege violation
address    8 × 4 = 0x000020
```

Lab07 installs vector 8 as `privilege_handler`.

The processor:

1. copies the user SR,
2. enters supervisor mode,
3. switches to the supervisor stack,
4. saves SR and PC,
5. fetches vector 8,
6. runs the handler.

## Saved State

The handler records:

```text
0x0100D4   saved pre-exception SR
0x0100D6   saved PC
0x0100DA   current SR inside handler
```

The interesting comparison is:

```text
saved SR      S = 0   user mode before exception
handler SR    S = 1   supervisor mode during handler
```

This proves the privilege exception crossed the mode boundary.

## Returning

For privilege violation, the saved PC identifies the offending instruction.

`RESET` is one 16-bit word, so the handler does:

```asm
addq.l  #2,2(%sp)
rte
```

`RTE` restores the saved SR and PC.

Because the saved SR has `S=0`, the CPU returns to user mode at the instruction after `RESET`.

Success marker:

```text
0x0100D1 = 0x22
```

Handler marker:

```text
0x0100D2 = 0xA8
```

## Why main Does Not RTS

`start.S` called `main` while in supervisor mode, so that return address lives on the supervisor stack.

After Lab07 deliberately switches to user mode, `A7` refers to the user stack instead.

Therefore Lab07 does not try to `RTS` from `main`. After printing `07\n`, it loops. The testbench stops when the monitor receives the newline.

## Build

```bash
make clean
make LAB=lab07
```

Disassemble:

```bash
make disasm LAB=lab07
```

Waveform:

```bash
surfer logs/lab07/lab07.vcd
```

## What to Inspect

RAM:

```text
0x0100D0 = 0x11   user-mode RAM write succeeded
0x0100D1 = 0x22   returned from privilege handler
0x0100D2 = 0xA8   privilege handler ran
0x0100D4          saved user SR
0x0100D6          saved PC
0x0100DA          handler SR
```

Vector:

```text
0x000020          vector 8
```

Useful VCD signals:

```text
byte_addr
FC0
FC1
FC2
ASn
eRWn
UDSn
LDSn
```

## Questions

- Which SR bit selects supervisor vs user mode?
- Why can the user-mode RAM write still succeed?
- Why does `RESET` trap instead of resetting the machine?
- Which stack is used for the privilege exception?
- Why does `RTE` return to user mode?
- Why does this lab avoid `RTS` at the end of `main`?
