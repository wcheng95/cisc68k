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


# Linker Script: `link.ld`

The second shared startup file is:

```text
link.ld
```

It tells the linker where each program section belongs in the 68000 address space.

Current file:

```ld
OUTPUT_ARCH(m68k)
ENTRY(_start)

SECTIONS
{
    . = 0x000000;

    .vectors :
    {
        KEEP(*(.vectors))
    }

    . = 0x000100;

    .text :
    {
        *(.text.start)
        *(.text*)
        *(.rodata*)
    }

    . = ALIGN(2);

    .data :
    {
        *(.data*)
    }

    .bss 0x010000 (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    }

    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
    }
}
```

## Line by Line

### `OUTPUT_ARCH(m68k)`

Tell the linker that the output file targets the Motorola 68k architecture.

This helps the linker reject incompatible object files and produce an ELF file with the correct architecture metadata.

It does **not** choose where execution begins and does not define the memory map.

---

### `ENTRY(_start)`

Set the ELF entry-point symbol to:

```text
_start
```

The linker resolves the address of `_start` and records that address in the ELF header.

For our bare 68000 simulation, this ELF entry field is not what causes the CPU to begin at `_start`.

The CPU actually starts there because the reset vector at address `0x000004` contains the address of `_start`.

So these are related but separate:

```text
ENTRY(_start)
    -> ELF/toolchain entry point

.long _start at vector 1
    -> actual 68000 reset PC
```

---

### `SECTIONS`

Begin the section-placement part of the linker script.

Inside this block we decide where assembler/compiler sections are placed in the final address space.

---

### `. = 0x000000;`

Set the linker location counter `.` to:

```text
0x000000
```

The location counter means:

> the address where the next output bytes will be placed.

So the next output section begins at address zero unless that section explicitly specifies another address.

---

### `.vectors :`

Create an output section named:

```text
.vectors
```

Because the current location counter is `0x000000`, this output section starts there.

---

### `KEEP(*(.vectors))`

Collect every input section named:

```text
.vectors
```

from all input object files and place them here.

In our case, `start.S` creates one with:

```asm
.section .vectors,"a"
```

The wildcard:

```text
*
```

means:

> take matching sections from any input file.

The outer `KEEP(...)` tells the linker not to remove this section even when section garbage collection is enabled.

Our Makefile uses:

```text
-Wl,--gc-sections
```

so without `KEEP`, an apparently unreferenced vector table could potentially be discarded.

This is why the reset vectors remain in the ROM image even though normal C code does not reference them.

---

### `. = 0x000100;`

Move the location counter forward to:

```text
0x000100
```

The executable code therefore starts at or after this address.

This leaves the range:

```text
0x000008 - 0x0000FF
```

unused for now.

We deliberately leave this gap because the first eight bytes hold the two reset vectors, and starting code at `0x100` makes the layout obvious while we are learning.

There is nothing architecturally special about `0x100`; it is our chosen layout.

---

### `.text :`

Create an output section named:

```text
.text
```

This will contain executable code and read-only constants.

Because the location counter was just set to `0x000100`, this section starts there.

---

### `*(.text.start)`

First, collect input sections named:

```text
.text.start
```

Our `start.S` uses:

```asm
.section .text.start,"ax"
```

Placing this first guarantees that startup code comes before ordinary generated code.

That is why Lab00 resolves:

```text
_start = 0x000100
```

---

### `*(.text*)`

Collect all input sections whose names begin with:

```text
.text
```

Examples can include:

```text
.text
.text.main
.text.foo
.text.startup
```

Compilers often place functions into separate `.text.<name>` sections when options such as:

```text
-ffunction-sections
```

are enabled.

The wildcard ensures all such code sections are included.

---

### `*(.rodata*)`

Collect all read-only-data sections.

Typical examples include:

```text
.rodata
.rodata.str1.1
.rodata.constants
```

These contain things such as:

- string literals
- constant lookup tables
- compiler-generated read-only constants

For our simple ROM model, placing `.rodata` immediately after code means both execute directly from ROM.

---

### `. = ALIGN(2);`

Advance the location counter if necessary so the next address is aligned to a 2-byte boundary.

For the original 68000, word and longword accesses must begin on even addresses.

So 2-byte alignment is the natural minimum alignment for our data layout.

For example:

```text
current address 0x000123
ALIGN(2)
    -> 0x000124
```

If the address is already even, nothing changes.

---

### `.data :`

Create the output section for initialized writable data.

---

### `*(.data*)`

Collect input sections beginning with:

```text
.data
```

Normally these are C variables with an explicit nonzero initial value, for example:

```c
int count = 5;
```

There is an important limitation in our current minimal startup:

`start.S` does **not** copy initialized data from ROM into RAM.

Therefore, although this linker script can place a `.data` section into the image, we should avoid relying on initialized writable globals until we deliberately add C-runtime initialization.

Lab00 does not use any.

---

### `.bss 0x010000 (NOLOAD) :`

Create the `.bss` output section beginning explicitly at:

```text
0x010000
```

This is the start of our RAM region.

`.bss` is conventionally used for writable objects that begin as zero.

For example:

```c
int counter;
static char buffer[128];
```

The qualifier:

```text
NOLOAD
```

means the linker assigns addresses to these objects but does not place their bytes into the load image.

That makes sense because RAM does not need to be stored in `rom.hex`.

However, our current `start.S` also does **not** clear `.bss` to zero.

Our simulation RAM model happens to initialize RAM to zero, so simple tests may appear to work, but software should not rely on that as a general C-runtime guarantee until we explicitly add BSS initialization.

---

### `*(.bss*)`

Collect all input sections whose names begin with:

```text
.bss
```

This includes compiler-generated variants such as:

```text
.bss
.bss.counter
.bss.buffer
```

---

### `*(COMMON)`

Collect old-style linker "common" symbols.

Historically, uninitialized global variables could be emitted as common symbols instead of regular `.bss` sections.

Modern GCC options often place them directly in `.bss`, but including `COMMON` is a conventional safety measure.

---

### `/DISCARD/ :`

Create the linker script's special discard output section.

Anything placed inside it is omitted from the final linked image.

---

### `*(.comment*)`

Discard compiler/toolchain comment metadata.

This does not contain executable program state.

---

### `*(.note*)`

Discard ELF note sections.

These can contain build metadata or ABI information that our bare-metal ROM does not need.

---

### `*(.eh_frame*)`

Discard exception-unwinding metadata normally produced for languages/toolchains that support stack unwinding.

Our minimal bare-metal labs do not use this runtime mechanism, so keeping it would only enlarge the image.

---

## Resulting Lab00 Layout

Conceptually, the linker creates:

```text
0x000000  +---------------------------+
          | reset vector: initial SP  |
0x000004  | reset vector: initial PC  |
0x000008  |                           |
          | unused                    |
0x000100  +---------------------------+
          | _start                    |
          | program .text             |
          | .rodata                   |
          | .data image if any        |
          | ...                       |
0x00FFFF  +---------------------------+

0x010000  +---------------------------+
          | .bss / RAM                |
          | stack grows downward      |
          |                           |
0x01FFFF  +---------------------------+
0x020000    initial SP
```

The monitor at:

```text
0xF00000
```

is not represented in the linker script because it does not store program sections.

It is simply a memory-mapped address that software accesses explicitly.

## Assembler vs Linker

A useful distinction is:

```text
start.S
    decides what belongs to sections

link.ld
    decides where those sections live
```

For example:

```asm
.section .vectors,"a"
```

says:

> these bytes belong to the input section `.vectors`

while:

```ld
. = 0x000000;

.vectors :
{
    KEEP(*(.vectors))
}
```

says:

> place those `.vectors` bytes at address `0x000000`
```

That separation between **section creation** and **section placement** is the main idea behind this linker script.
