# 68000 Assembly Review

A cumulative review sheet for concepts already learned in the labs.

Keep explanations and experiments in each lab README. Add only reusable facts here.

## Tags

```text
[68K]   Motorola 68000 architecture
[ASM]   GNU assembler syntax/directive
[LD]    GNU linker-script syntax
[CONV]  convention/project choice
```

# Assembly Basics

## Labels

```asm
_start:
```

A label gives the current address a symbolic name. [ASM]

Local numeric labels:

```asm
1:
    bra.s 1b
```

```text
1b   nearest 1: backward
1f   nearest 1: forward
```

## Sections

```asm
.section .vectors,"a"
.section .text.start,"ax"
```

```text
a   allocatable
x   executable
```

Assembler creates sections; linker places them.

## Emit a Longword

```asm
.long 0x00020000
.long _start
```

`.long` emits 32 bits. [ASM]

A symbol operand is resolved by the linker.

## Symbol Visibility

```asm
.global _start
.extern main
```

```text
.global   export symbol
.extern   symbol defined elsewhere
```

## Data-register operand sizes

For an ordinary data-register operand, size always selects the low part of `Dn`: [68K]

```text
.B   Dn[7:0]
.W   Dn[15:0]
.L   Dn[31:0]
```

Example:

```text
D7 = 0x12345678

MOVE.B D7,...  -> 0x78
MOVE.W D7,...  -> 0x5678
MOVE.L D7,...  -> 0x12345678
```

`MOVE.W` to a data register changes only the low 16 bits; it does not sign-extend.

There is no direct word-sized view of `Dn[31:16]`. Move/copy and rearrange first, for example:

```asm
move.l  %d7,%d0
swap    %d0
move.w  %d0,...
```

After `SWAP`, the original upper word is in `D0[15:0]`.

# Control Flow

## JSR

```asm
jsr main
```

Jump to subroutine and push return PC. [68K]

## RTS

```asm
rts
```

Pop return PC and continue there. [68K]

## BRA

```asm
bra.s target
```

Unconditional branch. [68K]

`.s` selects the short branch encoding.

# Stack

`A7` is the stack pointer. [68K]

Stack grows downward:

```text
push -> A7 decreases
pop  -> A7 increases
```

Typical forms:

```asm
move.w d0,-(a7)    // push word
move.l d1,-(a7)    // push long

move.w (a7)+,d0    // pop word
move.l (a7)+,d1    // pop long
```

```text
word push   A7 -= 2
long push   A7 -= 4
```

Word/longword addresses must be even. A longword does not require 4-byte alignment on the original 68000.

A byte operation using A7 changes A7 by 2, preserving even stack alignment.

# Reset Facts

On reset: [68K]

```text
0x000000 -> initial supervisor SP
0x000004 -> initial PC
```

The names `_start`, `.vectors`, and `main` are conventions, not CPU requirements.

# Linker Facts

```ld
. = 0x000000;
```

`.` is the linker location counter. [LD]

```ld
KEEP(*(.vectors))
```

Keep matching input sections even with section garbage collection. [LD]

```ld
ALIGN(2)
```

Move the location counter to the next 2-byte boundary. [LD]

```ld
ENTRY(_start)
```

Sets the ELF entry point; it does not control the 68000 reset PC. [LD]

# File Conventions

```text
.S    assembly passed through C preprocessor
.s    plain assembly
.ld   conventional linker-script suffix
```

For our current startup, `.S` preprocessing is not yet required.

# Review Questions

- What does the 68000 fetch from addresses 0 and 4?
- Which names are CPU-defined and which are conventions?
- What is the difference between a section and its placement?
- What does `JSR` put on the stack?
- Why can initial SP be one address beyond RAM?
- Why does the 68000 only require even alignment for longwords?
- Which bits of a data register do `.B`, `.W`, and `.L` select?
- How do you reach the original upper word of a data register?
- What is the difference between `.S` and `.s`?
- Why is `ENTRY(_start)` not what starts the CPU?
