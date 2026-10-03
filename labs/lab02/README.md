# Lab02 — Instruction Encoding

## Goal

Study how 68000 assembly instructions become machine-code words.

Lab02 keeps the same ROM/RAM/monitor environment and adds no hardware.

Focus:

```text
variable instruction length
opcode word
immediate extension word
absolute address extension
branch displacement
```

Expected output:

```text
02
```

## Program

Key instructions:

```asm
moveq   #5,%d0
move.w  #0x1234,%d1
add.w   %d1,%d0

lea     0x010020,%a0
move.w  %d0,(%a0)

bra.s   1f
nop
```

The exact machine encoding is the subject of this lab.

## Build

```bash
make clean
make LAB=lab02
```

To inspect the linked instruction stream:

```bash
make disasm LAB=lab02
```

Use the disassembly as evidence rather than memorizing opcode tables.

## What to Look For

### Fixed opcode word vs extension words

Some instructions fit entirely in one 16-bit instruction word.

Others need additional words for:

- immediate constants
- absolute addresses
- displacements

Compare the byte length of:

```text
MOVEQ
MOVE.W immediate
ADD.W register-to-register
LEA absolute
BRA.S
NOP
```

### Variable length

The 68000 does not use one fixed instruction width.

Conceptually:

```text
opcode word
    +
zero or more extension words
```

That is one of the classic CISC characteristics.

## Runtime Check

The arithmetic path is:

```text
D0 = 5
D1 = 0x1234
D0 = D0 + D1
   = 0x1239
```

Then:

```asm
move.w %d0,(%a0)
```

stores:

```text
0x1239
```

at RAM address:

```text
0x010020
```

This runtime effect confirms the instruction sequence executed correctly; the main learning target remains the encoding.

## Surfer

Use `byte_addr` for the full 24-bit byte address.

Watch instruction fetches starting near the linked `main` address and compare them with:

```bash
make disasm LAB=lab02
```

Useful signals:

```text
byte_addr
iEdb
ASn
UDSn
LDSn
eRWn
DTACKn
```

## Questions

- Which instructions are one word long?
- Which instructions require extension words?
- Where is the immediate value `0x1234` stored in the instruction stream?
- How is the absolute address `0x010020` represented?
- Why can `BRA.S` be shorter than an absolute jump?
