# Lab10 — Memory-Mapped I/O

## Goal

Show that the 68000 talks to peripherals with the same ordinary bus instructions used for memory.

Lab10 adds one tiny read/write 16-bit peripheral register:

```text
0xF00020   MMIO register
```

Expected output:

```text
10
```

## Core Idea

The 68000 has no separate I/O instruction space here.

These are ordinary `MOVE` instructions:

```asm
move.w  #0x1234,0x00f00020
move.w  0x00f00020,%d0
```

The only reason `0xF00020` behaves like a peripheral instead of RAM is external address decoding in the testbench.

So from the CPU's point of view:

```text
RAM access      = bus cycle to RAM address
MMIO access     = bus cycle to peripheral address
```

The instruction mechanism is the same.

## Full-Word Write and Readback

First:

```asm
move.w  #0x1234,0x00f00020
```

The peripheral stores:

```text
0x1234
```

Then:

```asm
move.w  0x00f00020,%d0
```

reads the same value back.

The lab verifies it with:

```asm
cmpi.w  #0x1234,%d0
bne.s   fail
```

## Byte Writes

Next:

```asm
move.b  #0xab,0x00f00020
move.b  #0xcd,0x00f00021
```

Because the register is 16 bits wide:

```text
even byte address   -> upper byte
odd byte address    -> lower byte
```

After those writes:

```text
register = 0xABCD
```

A word read verifies that result:

```asm
move.w  0x00f00020,%d1
cmpi.w  #0xabcd,%d1
```

## Trace

Default:

```bash
make clean
make LAB=lab10
cat logs/lab10/lab10.trace
```

Look for accesses to:

```text
[F00020]
```

The expected pattern is roughly:

```text
W [F00020] 1234 00 101
R [F00020] 1234 00 101
W [F00020] ABxx 01 101
W [F00020] xxCD 10 101
R [F00020] ABCD 00 101
```

The exact unused byte shown on a byte-write data bus is not important. `UDS/LDS` tells you which lane is valid.

## Why This Is MMIO

Nothing inside the 68000 knows that `0xF00020` is a peripheral.

The external machine does:

```text
address == 0xF00020
        ↓
select mmio_reg
        ↓
read/write register
        ↓
assert DTACK
```

That is memory-mapped I/O.

## Success Marker

The lab writes:

```text
0x0100F0 = 0x11   PASS
0x0100F0 = 0xEE   FAIL
```

Then prints:

```text
10
```

## Questions

- Why does the CPU not need a special I/O instruction?
- What makes `0xF00020` a peripheral instead of RAM?
- Why do byte writes to `0xF00020` and `0xF00021` update different halves of the register?
- What role does `DTACK` still play for MMIO?
- Why is `UDS/LDS` more important than the unused byte value during a byte write?
