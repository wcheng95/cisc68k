# Common Startup

This directory contains the startup pieces shared by the cisc68k labs.

The main goal of this README is to distinguish four things that often look similar in startup code:

- what the 68000 architecture defines
- what GNU assembler defines
- what GNU linker defines
- what is merely a convention or project choice

It also distinguishes what we need now from what belongs later.

---

# Legend

## Source of the rule

\`\`\`text
[68K]   Motorola 68000 architecture

[ASM]   GNU assembler syntax/directive

[LD]    GNU linker-script syntax/command

[CONV]  Convention or project choice
        The name/value could change if all dependent pieces changed with it
\`\`\`

## When we need it

\`\`\`text
[NOW]    Required by the current labs

[LATER]  Not required yet; likely useful in later labs

[OPT]    Optional convenience
\`\`\`

Example:

\`\`\`text
.long _start

.long      [ASM]
_start     [CONV]
PC vector  [68K] [NOW]
\`\`\`

The CPU does not know what \`.long\` or \`_start\` means. It only sees four bytes at address \`0x000004\`, interprets them as the initial PC, and begins executing there.

---

# Big Picture

\`\`\`text
RESET                                      [68K]
  |
  +--> longword at 0x000000 -> initial SP [68K] [NOW]
  |
  +--> longword at 0x000004 -> initial PC [68K] [NOW]
                                   |
                                   v
                                _start     [CONV] [NOW]
                                   |
                                   v
                                jsr main   [68K] [NOW]
                                   |
                                   v
                                main()     [CONV] [NOW]
                                   |
                                   v
                                  RTS      [68K]
                                   |
                                   v
                               bra.s 1b    [68K]
\`\`\`

Assembler and linker syntax exists only to arrange bytes so the 68000 sees the required values at the required addresses.

---

# start.S

Current file:

\`\`\`asm
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
\`\`\`

## \`.section .vectors,"a"\`

\`\`\`text
.section   [ASM]
.vectors   [CONV]
"a"        [ASM]
            [NOW]
\`\`\`

\`.section\` tells the assembler to put following bytes into an input section.

The name \`.vectors\` is ours. The 68000 does not know that name. We could rename it if the linker script changed too.

The \`a\` flag means allocatable: this section occupies space in the final image.

We need a dedicated section now because we must place the reset-vector bytes at address zero.

---

## \`.long 0x00020000\`

\`\`\`text
.long          [ASM]
0x00020000     [CONV]
vector #0 role [68K]
                [NOW]
\`\`\`

The 68000 defines:

\`\`\`text
longword at 0x000000 -> initial supervisor SP
\`\`\`

We chose the value:

\`\`\`text
0x00020000
\`\`\`

because RAM occupies:

\`\`\`text
0x010000 - 0x01FFFF
\`\`\`

and the stack grows downward.

The initial SP may sit one address above RAM because a push decrements SP before storing.

For a longword push:

\`\`\`text
SP = 0x020000
SP = SP - 4
   = 0x01FFFC
\`\`\`

The stored longword occupies \`0x01FFFC-0x01FFFF\`.

Architecture requirement:

\`\`\`text
initial SP comes from 0x000000   [68K]
\`\`\`

Our choice:

\`\`\`text
SP value = 0x00020000            [CONV]
\`\`\`

---

## \`.long _start\`

\`\`\`text
.long       [ASM]
_start      [CONV]
vector #1   [68K]
             [NOW]
\`\`\`

The 68000 defines:

\`\`\`text
longword at 0x000004 -> initial PC
\`\`\`

We chose the symbol name \`_start\`.

The linker replaces that symbol with its numeric address. In Lab00:

\`\`\`text
_start = 0x00000100
\`\`\`

Observed reset-vector words:

\`\`\`text
000000 -> 0002
000002 -> 0000
000004 -> 0000
000006 -> 0100
\`\`\`

which reconstruct:

\`\`\`text
SP = 0x00020000
PC = 0x00000100
\`\`\`

---

## \`.section .text.start,"ax"\`

\`\`\`text
.section       [ASM]
.text.start    [CONV]
"a" / "x"      [ASM]
                [NOW]
\`\`\`

Switch to an input section named \`.text.start\`.

Flags:

\`\`\`text
a   allocatable
x   executable
\`\`\`

The section name is our convention.

The linker places this section before ordinary program text so the startup entry is easy to find and control.

---

## \`.global _start\`

\`\`\`text
.global   [ASM]
_start    [CONV]
           [NOW]
\`\`\`

Make \`_start\` visible to the linker.

The name is arbitrary. We could use \`reset_entry\` if the vector and linker script used the same symbol.

---

## \`.extern main\`

\`\`\`text
.extern   [ASM]
main      [CONV]
           [NOW]
\`\`\`

Declare that \`main\` is defined elsewhere.

For Lab00 it comes from:

\`\`\`text
labs/lab00/lab00.c
\`\`\`

\`main\` is a C/toolchain convention, not a 68000 requirement.

---

## \`_start:\`

\`\`\`text
_start   [CONV]
:        [ASM syntax]
          [NOW]
\`\`\`

Define the symbol \`_start\` at the current location.

Because the linker places \`.text.start\` at \`0x000100\`:

\`\`\`text
_start = 0x000100
\`\`\`

---

## \`jsr main\`

\`\`\`text
jsr    [68K]
main   [CONV]
        [NOW]
\`\`\`

\`JSR\` is a 68000 instruction: Jump to SubRoutine.

It saves a return address on the stack and transfers control to \`main\`.

Lab00 observed the return address written near:

\`\`\`text
0x01FFFC
0x01FFFE
\`\`\`

The CPU does not require startup to call \`main\`; that is our software design.

---

## \`1:\`

\`\`\`text
1:   [ASM]
     [OPT]
\`\`\`

A GNU assembler numeric local label.

It has no CPU meaning.

It may be referenced as:

\`\`\`text
1b   nearest label 1 backward
1f   nearest label 1 forward
\`\`\`

---

## \`bra.s 1b\`

\`\`\`text
bra    [68K]
.s     [ASM syntax selecting short encoding]
1b     [ASM local-label syntax]
        [NOW]
\`\`\`

\`BRA\` is an unconditional 68000 branch.

This loops forever if \`main()\` returns:

\`\`\`asm
1:
    bra.s 1b
\`\`\`

There is no OS or caller above \`_start\`, so we need a safe destination after \`main\`.

---

# What start.S Does Not Do Yet

\`\`\`text
clear .bss                     [LATER]
copy initialized .data to RAM  [LATER]
install exception handlers     [LATER]
configure interrupts           [LATER]
switch to user mode            [LATER]
create a separate user stack   [LATER]
initialize libc/Newlib         [LATER]
run C++ constructors           [LATER]
\`\`\`

These are common startup responsibilities in larger systems, but they would hide the basic reset path if added now.

---

# link.ld

Current file:

\`\`\`ld
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
\`\`\`

## \`OUTPUT_ARCH(m68k)\`

\`\`\`text
OUTPUT_ARCH   [LD]
m68k          [LD target identifier]
               [OPT]
\`\`\`

Tell GNU ld that the output ELF targets m68k.

Useful for ELF metadata and compatibility checking.

The 68000 itself never sees this text.

---

## \`ENTRY(_start)\`

\`\`\`text
ENTRY    [LD]
_start   [CONV]
          [OPT for CPU reset]
\`\`\`

Set the ELF entry point to \`_start\`.

Important:

\`\`\`text
ENTRY(_start)                 -> ELF/tool metadata [LD]
.long _start at 0x000004      -> actual reset PC   [68K]
\`\`\`

The 68000 starts from the reset vector, not from the ELF header.

---

## \`SECTIONS\`

\`\`\`text
SECTIONS   [LD]
            [NOW]
\`\`\`

Begin the linker-script block that controls section placement.

---

## \`. = 0x000000;\`

\`\`\`text
.          [LD location counter]
0x000000   [CONV chosen to satisfy 68K reset]
            [NOW]
\`\`\`

Set the linker location counter to zero.

The next output section begins there.

Why zero? Because the 68000 reset definition requires:

\`\`\`text
0x000000   initial SP
0x000004   initial PC
\`\`\`

So the syntax is GNU ld-specific, but the address is driven by the CPU architecture.

---

## \`.vectors :\`

\`\`\`text
.vectors   [CONV]
:          [LD syntax]
            [NOW]
\`\`\`

Create an output section called \`.vectors\`.

Because the location counter is zero, it starts at \`0x000000\`.

The section name is our choice; the address is architecture-driven.

---

## \`KEEP(*(.vectors))\`

\`\`\`text
KEEP       [LD]
*          [LD wildcard]
.vectors   [CONV]
            [NOW because --gc-sections is enabled]
\`\`\`

Collect every input section named \`.vectors\` and prevent linker garbage collection from removing it.

Our Makefile uses:

\`\`\`text
-Wl,--gc-sections
\`\`\`

So \`KEEP\` explicitly protects the vector table.

---

## \`. = 0x000100;\`

\`\`\`text
.          [LD]
0x000100   [CONV]
            [NOW]
\`\`\`

Move the location counter to \`0x000100\`.

This gives:

\`\`\`text
0x000000-0x000007   reset vectors
0x000008-0x0000FF   unused for now
0x000100...          startup/program code
\`\`\`

There is nothing architecturally special about \`0x100\`.

---

## \`.text :\`

\`\`\`text
.text   [CONV]
:       [LD syntax]
         [NOW]
\`\`\`

Create the final executable-code output section.

\`.text\` is a toolchain convention, not a CPU concept.

---

## \`*(.text.start)\`

\`\`\`text
*             [LD wildcard]
.text.start   [CONV]
               [NOW]
\`\`\`

Place startup code first.

This is why \`_start\` lands at the beginning of the code region.

---

## \`*(.text*)\`

\`\`\`text
*        [LD wildcard]
.text*   [CONV pattern]
          [NOW]
\`\`\`

Collect all executable input sections whose names begin with \`.text\`.

Examples:

\`\`\`text
.text
.text.main
.text.foo
\`\`\`

Our compiler uses \`-ffunction-sections\`, so functions may appear in separate \`.text.<name>\` sections.

---

## \`*(.rodata*)\`

\`\`\`text
.rodata*   [CONV]
            [NOW]
\`\`\`

Collect read-only data such as string literals and constant tables.

We place it in ROM after code.

---

## \`. = ALIGN(2);\`

\`\`\`text
ALIGN   [LD]
2       [CONV driven by 68K alignment]
         [NOW]
\`\`\`

Move the location counter to the next even address if necessary.

The original 68000 requires word and longword accesses to begin on even addresses.

---

## \`.data :\`

\`\`\`text
.data   [CONV]
         [LATER]
\`\`\`

Conventional section for initialized writable data, for example:

\`\`\`c
int count = 5;
\`\`\`

Our current startup does not copy initialized data from ROM to RAM, so we should not rely on normal writable \`.data\` semantics yet.

---

## \`*(.data*)\`

\`\`\`text
.data*   [CONV]
          [LATER]
\`\`\`

Collect initialized-data input sections.

The linker can place them now, but the startup runtime behavior needed to make them useful is still missing.

---

## \`.bss 0x010000 (NOLOAD) :\`

\`\`\`text
.bss       [CONV]
0x010000   [CONV memory-map choice]
NOLOAD     [LD]
            [LATER]
\`\`\`

Place \`.bss\` at the start of RAM.

\`NOLOAD\` assigns addresses but does not put bytes into the ROM image.

Typical BSS objects:

\`\`\`c
int counter;
static char buffer[128];
\`\`\`

A normal C startup clears BSS before calling \`main\`.

We do not do that yet.

The testbench RAM happens to initialize to zero, but that is a simulation convenience, not yet a software guarantee.

---

## \`*(.bss*)\`

\`\`\`text
.bss*   [CONV]
         [LATER]
\`\`\`

Collect BSS-family input sections.

---

## \`*(COMMON)\`

\`\`\`text
COMMON   [LD/toolchain convention]
          [OPT]
\`\`\`

Collect old-style common symbols.

Modern GCC often emits uninitialized variables directly into BSS, but handling COMMON is conventional and harmless.

---

## \`/DISCARD/ :\`

\`\`\`text
/DISCARD/   [LD]
             [OPT]
\`\`\`

Anything assigned here is omitted from the final linked image.

---

## \`*(.comment*)\`

\`\`\`text
.comment*   [toolchain metadata]
             [OPT]
\`\`\`

Discard compiler/tool metadata.

---

## \`*(.note*)\`

\`\`\`text
.note*   [ELF/toolchain metadata]
          [OPT]
\`\`\`

Discard ELF note sections.

---

## \`*(.eh_frame*)\`

\`\`\`text
.eh_frame*   [toolchain/runtime metadata]
              [OPT for our labs]
\`\`\`

Discard stack-unwinding metadata.

Our current bare-metal labs do not use runtime unwinding.

---

# Current Memory Layout

\`\`\`text
0x000000  +---------------------------+
          | initial SP vector         | [68K] [NOW]
0x000004  | initial PC vector         | [68K] [NOW]
0x000008  |                           |
          | unused                    | [CONV]
0x000100  +---------------------------+
          | _start                    | [CONV] [NOW]
          | program .text             |
          | .rodata                   |
          |                           |
0x00FFFF  +---------------------------+

0x010000  +---------------------------+
          | RAM                       | [CONV] [NOW]
          | future .bss/.data use     | [LATER]
          |                           |
          | stack grows downward      | [68K behavior]
0x01FFFF  +---------------------------+
0x020000    initial SP                 [CONV] [NOW]

0xF00000    monitor register           [CONV] [NOW]
\`\`\`

The monitor has no linker section because no program bytes live there. Software accesses it explicitly as a memory-mapped device.

---

# Required Now vs Later

## Required now

\`\`\`text
[68K]
- initial SP fetch from 0x000000
- initial PC fetch from 0x000004
- valid instructions
- working stack for JSR/RTS

[ASM/LD]
- emit the two reset-vector longwords
- place them at address zero
- place executable code at a valid address
- resolve _start and main

[CONV]
- _start naming
- main naming
- code at 0x000100
- RAM at 0x010000
- monitor at 0xF00000
\`\`\`

## Later

\`\`\`text
- BSS clearing
- ROM-to-RAM DATA copying
- exception vectors beyond reset
- interrupt initialization
- user mode
- separate user/supervisor stack handling
- libc/Newlib startup
- constructors/destructors
\`\`\`

Do not add these until a lab actually needs them.

---

# Reusable Reading Template

Use these same questions for every unfamiliar construct in later labs.

## 1. What is it?

\`\`\`text
CPU instruction?
assembler directive?
linker command?
label/symbol?
project convention?
\`\`\`

## 2. Who defines it?

\`\`\`text
[68K]
[ASM]
[LD]
[CONV]
\`\`\`

## 3. Is it required?

\`\`\`text
required by hardware?
required by our current software design?
optional convenience?
\`\`\`

## 4. When do we need it?

\`\`\`text
[NOW]
[LATER]
[OPT]
\`\`\`

## 5. What happens if we remove or rename it?

This is often the fastest way to distinguish an architectural requirement from a convention.

---

# Core Principle

When reading startup code, do not treat every line as equally fundamental.

Always separate:

\`\`\`text
what the CPU requires
from
what the toolchain requires
from
what programmers commonly do
from
what we chose for this lab
\`\`\`

This classification is intended to become the documentation pattern for later labs as well.
