# Common Lab Startup

This directory contains the small pieces shared by the cisc68k labs.

For now, the most important file is:

```text
start.S
```

It provides the minimum 68000 reset vectors and startup code needed to enter a C `main()` function.

Current file:

```asm
.section .vectors,"a"
    .long   0x00020000
    .long   _start

.section .text.start,"ax"
.global _start
.extern main

_start:
    jsr     main

1:
    bra.s   1b
```

## Line by Line

### `.section .vectors,"a"`

Select or create an assembler section named:

```text
.vectors
```

The linker script places this section at address:

```text
0x000000
```

The flag:

```text
"a"
```

means the section is allocatable: it occupies memory in the final image.

For the 68000, the first two longwords after reset are special:

```text
0x000000   initial supervisor stack pointer
0x000004   initial program counter
```

So this section begins with exactly those two values.

---

### `.long 0x00020000`

Emit one 32-bit value:

```text
0x00020000
```

This becomes the first reset vector.

The 68000 loads it into its initial supervisor stack pointer during reset.

Our RAM occupies:

```text
0x010000 - 0x01FFFF
```

so:

```text
0x00020000
```

is the first address immediately above RAM.

Because the 68000 stack grows downward, the first stack write lands inside the top of RAM.

In Lab00 we observed stack accesses near:

```text
0x01FFFC
0x01FFFE
```

when `JSR` saved its return address.

---

### `.long _start`

Emit another 32-bit value.

Instead of writing a numeric constant, this value is the address represented by the symbol:

```text
_start
```

The linker resolves that symbol.

This becomes the second reset vector, the initial program counter.

The linker script currently places the startup code beginning at:

```text
0x000100
```

so in Lab00 the CPU fetched:

```text
PC = 0x00000100
```

after reset.

The first eight ROM bytes therefore represent:

```text
address   meaning
-------   --------------------------
000000    initial SP, upper word
000002    initial SP, lower word
000004    initial PC, upper word
000006    initial PC, lower word
```

For Lab00 they were observed as:

```text
000000 -> 0002
000002 -> 0000

000004 -> 0000
000006 -> 0100
```

which reconstructs:

```text
SP = 0x00020000
PC = 0x00000100
```

---

### `.section .text.start,"ax"`

Switch to another section named:

```text
.text.start
```

The section flags are:

```text
a   allocatable
x   executable
```

The linker script deliberately places `.text.start` before the rest of the program text.

This makes the startup entry point easy to locate and keeps it separate from ordinary C-generated code.

---

### `.global _start`

Make the symbol:

```text
_start
```

visible to the linker.

Without this declaration, `_start` would normally remain local to this assembly file.

The linker script also contains:

```text
ENTRY(_start)
```

so `_start` is the ELF entry symbol as well as the address stored in the 68000 reset vector.

For the simulated 68000, the reset vector is what actually determines where execution starts.

---

### `.extern main`

Declare that:

```text
main
```

is defined somewhere else.

In our labs, it is supplied by the lab C file, for example:

```text
labs/lab00/lab00.c
```

The assembler therefore leaves a relocation for the linker to resolve.

---

### `_start:`

Define the symbol:

```text
_start
```

at the current location.

This is the address placed into the reset PC vector.

For Lab00 it is:

```text
0x000100
```

---

### `jsr main`

Execute:

```text
JSR = Jump to SubRoutine
```

The CPU transfers execution to `main`.

Unlike a plain jump, `JSR` also saves a return address on the stack.

In Lab00, the temporary bus trace showed writes near:

```text
0x01FFFC
0x01FFFE
```

followed later by reads from the same locations when `main` returned.

That is our first visible example of the 68000 stack and subroutine mechanism.

At this stage, `start.S` does not initialize a C runtime.

It does not:

- copy initialized data from ROM to RAM
- clear `.bss`
- initialize constructors
- call an operating system
- provide libc startup

Lab00 does not require any of those things.

---

### `1:`

Define a local numeric label named:

```text
1
```

Numeric labels are convenient for short local assembly branches because they can be reused elsewhere in the file.

---

### `bra.s 1b`

`BRA` means unconditional branch.

The suffix:

```text
.s
```

selects the short branch encoding.

The operand:

```text
1b
```

means:

```text
the nearest label "1" backward from here
```

So this instruction branches back to itself forever:

```text
1:
    bra.s 1b
```

This is where execution goes if `main()` returns.

There is nowhere else for a bare-metal program to return to.

In Lab00, `main()` writes:

```text
Hi
```

to the monitor and returns. The testbench finishes the simulation when it sees the newline, so the infinite loop exists mainly to give the CPU a valid destination after `main`.

## Reset-to-main Flow

The complete startup path is:

```text
RESET
  |
  +--> read longword at 0x000000
  |      -> SP = 0x00020000
  |
  +--> read longword at 0x000004
         -> PC = _start = 0x00000100
                    |
                    v
                jsr main
                    |
                    v
                C main()
                    |
                    v
                  RTS
                    |
                    v
                bra.s 1b
```

This startup file is intentionally minimal. As later labs require more C runtime behavior, we should add only what those labs actually need.
