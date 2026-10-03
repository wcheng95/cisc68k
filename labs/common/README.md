# Common Startup

This directory contains the minimal startup pieces shared by the labs:

```text
start.S   reset vectors + entry code
link.ld   memory/section placement
```

The main goal is to distinguish **architecture**, **toolchain syntax**, and **our conventions**.

## Legend

```text
[68K]   defined by the Motorola 68000 architecture
[ASM]   GNU assembler syntax/directive
[LD]    GNU linker-script syntax/command
[CONV]  convention or project choice

[NOW]   needed by current labs
[LATER] not needed yet
[OPT]   optional
```

---

# start.S

Current role:

```text
reset
  -> load SP from 0x000000
  -> load PC from 0x000004
  -> enter _start
  -> call main()
  -> park if main returns
```

## Key lines

### `.section .vectors,"a"`

```text
.section   [ASM]
.vectors   [CONV]
"a"        [ASM]
            [NOW]
```

Creates an allocatable input section named `.vectors`.

The name is ours; the 68000 only cares that the bytes eventually land at address 0.

### `.long 0x00020000`

```text
.long          [ASM]
0x00020000     [CONV]
initial SP     [68K] [NOW]
```

The 68000 loads the longword at `0x000000` as the initial supervisor SP.

We choose `0x00020000` because RAM is `0x010000-0x01FFFF` and the stack grows downward.

### `.long _start`

```text
.long       [ASM]
_start      [CONV]
initial PC  [68K] [NOW]
```

The 68000 loads the longword at `0x000004` as the initial PC.

The linker resolves `_start` to its numeric address.

### `.section .text.start,"ax"`

```text
.section      [ASM]
.text.start   [CONV]
"a","x"       [ASM]
               [NOW]
```

Places startup code in a dedicated executable section so the linker can put it first.

### `.global _start`

```text
.global   [ASM]
_start    [CONV]
           [NOW]
```

Exports `_start` so the linker can resolve it.

### `.extern main`

```text
.extern   [ASM]
main      [CONV]
           [NOW]
```

Declares that `main` is defined in the lab C file.

### `jsr main`

```text
jsr    [68K]
main   [CONV]
        [NOW]
```

Calls `main` and pushes the return address onto the stack.

### `1:` / `bra.s 1b`

```text
1:       [ASM] [OPT]
bra      [68K]
.s, 1b   [ASM]
          [NOW]
```

Creates an infinite loop if `main` returns.

---

# link.ld

Its job is simple:

> decide where the sections created by the assembler/compiler live in the 68000 address space.

## Key lines

### `OUTPUT_ARCH(m68k)`

```text
OUTPUT_ARCH   [LD] [OPT]
```

Marks the ELF output as m68k.

Useful to tools; invisible to the CPU.

### `ENTRY(_start)`

```text
ENTRY    [LD]
_start   [CONV]
          [OPT for CPU reset]
```

Sets the ELF entry point.

This is **not** what starts the 68000. The real reset PC comes from address `0x000004`.

### `. = 0x000000;`

```text
.          [LD]
0x000000   [CONV chosen to satisfy 68K reset]
            [NOW]
```

Sets the linker location counter to zero.

### `.vectors { KEEP(*(.vectors)) }`

```text
.vectors   [CONV]
KEEP, *    [LD]
            [NOW]
```

Places all input `.vectors` sections at address 0 and prevents garbage collection from removing them.

### `. = 0x000100;`

```text
0x000100   [CONV] [NOW]
```

Chooses where program code begins.

The 68000 does not require `0x100`; we use it because it makes the layout easy to see.

### `.text { ... }`

```text
.text        [CONV]
.text.start  [CONV]
.text*       [CONV]
.rodata*     [CONV]
*            [LD wildcard]
              [NOW]
```

Places startup code first, followed by normal code and read-only data.

### `ALIGN(2)`

```text
ALIGN   [LD]
2       [CONV driven by 68K alignment]
         [NOW]
```

Keeps following data on an even address.

### `.data`

```text
.data   [CONV] [LATER]
```

For initialized writable data.

A proper startup must eventually copy its initial contents from ROM to RAM.

We do not need that yet.

### `.bss 0x010000 (NOLOAD)`

```text
.bss       [CONV]
0x010000   [CONV]
NOLOAD     [LD]
            [LATER]
```

Places BSS at the beginning of RAM without storing it in the ROM image.

A proper C startup normally clears BSS to zero. We do not do that yet.

### `/DISCARD/`

```text
/DISCARD/   [LD] [OPT]
```

Drops metadata such as `.comment`, `.note`, and `.eh_frame` that our bare-metal labs do not need.

---

# Current Layout

```text
0x000000  initial SP vector      [68K] [NOW]
0x000004  initial PC vector      [68K] [NOW]
0x000008  unused
...
0x000100  _start + program code  [CONV] [NOW]
...
0x010000  RAM                    [CONV] [NOW]
...
0x01FFFF  top byte of RAM
0x020000  initial SP             [CONV] [NOW]

0xF00000  monitor register       [CONV] [NOW]
```

---

# Now vs Later

## Now

```text
- reset vectors
- initial stack pointer
- _start
- main()
- JSR / RTS stack behavior
- ROM/RAM placement
- monitor output
```

## Later

```text
- clear .bss
- copy .data ROM -> RAM
- exception vectors beyond reset
- interrupts
- user mode
- separate user/supervisor stack handling
- libc/Newlib startup
- constructors
```

Do not add these until a lab actually needs them.

---

# Reading Rule

For any unfamiliar startup line, ask:

```text
1. Is this [68K], [ASM], [LD], or [CONV]?
2. Is it [NOW], [LATER], or [OPT]?
3. What breaks if I remove or rename it?
```

That is the template we should reuse in later labs.
