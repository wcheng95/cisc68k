# 68000 Assembly Tutorial

This is a small cumulative tutorial for the 68000 assembly concepts learned in the cisc68k labs.

It is **not** intended to replace the Motorola 68000 User's Manual. Each lab README explains the code used in that lab; this document collects the reusable assembly ideas that carry forward.

## Documentation Pattern

```text
labs/common/README.md
    startup/linker details shared by all labs

labs/labNN/README.md
    explain that lab's code, experiment, and observations

docs/asm-tutorial.md
    cumulative 68000 assembly concepts learned across labs
```

Tags used where useful:

```text
[68K]   Motorola 68000 architecture
[ASM]   GNU assembler syntax/directive
[LD]    GNU linker-script syntax/command
[CONV]  convention or project choice
```

---

# From Common Startup

## Labels and Symbols

A label defines a symbolic address:

```asm
_start:
```

`_start` is a name chosen by us; the assembler/linker resolve it to a numeric address.

Local numeric labels are convenient for short branches:

```asm
1:
    bra.s 1b
```

```text
1b   nearest label 1 backward
1f   nearest label 1 forward
```

The numeric-label syntax is an assembler feature, not part of the 68000 ISA.

## Sections

GNU assembler directives such as:

```asm
.section .vectors,"a"
.section .text.start,"ax"
```

classify emitted bytes into named sections.

The assembler creates sections; the linker decides where they live.

Common flags:

```text
a   allocatable
x   executable
```

## Emitting Data

```asm
.long 0x00020000
.long _start
```

`.long` emits a 32-bit value.

The value may be:

- a literal constant
- a symbol whose address the linker resolves

This is how the reset vector table is created.

## Symbol Visibility

```asm
.global _start
.extern main
```

`.global` exports a symbol from the current assembly file.

`.extern` declares that a symbol is defined elsewhere.

These are assembler/linker mechanisms, not CPU instructions.

## JSR — Jump to Subroutine

```asm
jsr main
```

`JSR` transfers control to a subroutine and saves the return address on the stack.

Conceptually:

```text
push return PC
PC <- destination
```

Lab00 showed the return address being written near the top of RAM.

## RTS — Return from Subroutine

The compiler-generated `main()` returns with:

```asm
rts
```

Conceptually:

```text
PC <- longword popped from stack
```

So `JSR` and `RTS` form a call/return pair.

## BRA — Unconditional Branch

```asm
bra.s 1b
```

`BRA` is an unconditional branch.

The `.s` selects the short-displacement encoding in GNU 68k assembly syntax.

In startup code we use it to park the CPU if `main()` returns.

---

# Stack Basics Learned So Far

The 68000 uses `A7` as the stack pointer.

The stack grows toward lower addresses.

Typical push forms use pre-decrement addressing:

```asm
move.w d0,-(a7)
move.l d1,-(a7)
```

Typical pop forms use post-increment addressing:

```asm
move.w (a7)+,d0
move.l (a7)+,d1
```

Word push:

```text
A7 = A7 - 2
```

Longword push:

```text
A7 = A7 - 4
```

The original 68000 requires word and longword accesses to begin on an even address; 4-byte alignment is not required.

A byte operation using `A7` still adjusts the stack pointer by 2 so stack alignment remains even.

---

# Lab00 Notes

Lab00 is intentionally tiny.

Its purpose is to prove:

```text
reset vectors
    ->
_start
    ->
main()
    ->
memory-mapped monitor write
```

The generated code writes:

```text
H
i
newline
```

to the monitor at:

```text
0xF00000
```

As later labs introduce new instructions and addressing modes, add only the reusable concepts here. Keep experiment-specific details in the lab README.
