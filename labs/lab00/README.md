# Lab00 — Standalone Sanity Check

## Goal

Prove the smallest useful standalone 68000 simulation path:

```text
reset
  -> startup
  -> C main()
  -> memory-mapped monitor write
  -> host console
```

Expected output:

```text
Hi
RESULT: lab00 PASS
```

Lab00 is intentionally simple. Its purpose is to make the complete startup and execution path understandable before adding more 68000 features.

---

## Program

```c
#define MONITOR (*(volatile unsigned char *)0x00f00000UL)

int main(void)
{
    MONITOR = 'H';
    MONITOR = 'i';
    MONITOR = '\n';

    return 0;
}
```

The monitor is a write-only testbench peripheral at:

```text
0xF00000
```

Each byte write is printed directly by the testbench.

It is not a UART.

---

## Build and Run

From the repository root:

```bash
make clean
make
```

The build flow is:

```text
start.S + lab00.c
        ↓
compiler / assembler
        ↓
object files
        ↓
link.ld
        ↓
lab00.elf
        ↓
objcopy
        ↓
lab00.bin
        ↓
helper.py
        ↓
lab00.hex
        ↓
Verilator
        ↓
Hi + VCD
```

Generated files are build artifacts and are not committed.

---

## Memory Map

```text
0x000000 - 0x00FFFF   ROM
0x010000 - 0x01FFFF   RAM
0xF00000               MONITOR
```

Reset state:

```text
initial SP = 0x00020000
initial PC = 0x00000100
```

The initial SP sits just above RAM because the 68000 stack grows downward.

---

## What Lab00 Uses

Shared startup files:

```text
labs/common/start.S
labs/common/link.ld
```

Their detailed explanation is in:

```text
labs/common/README.md
```

Lab00 adds only:

```text
main()
monitor writes
```

---

## MONITOR Expression

```c
#define MONITOR (*(volatile unsigned char *)0x00f00000UL)
```

Read it from right to left:

```text
0x00f00000UL
    address value

(volatile unsigned char *)
    treat the address as a pointer to a volatile byte

*
    dereference the pointer

MONITOR
    the byte-sized object at 0xF00000
```

Therefore:

```c
MONITOR = 'H';
```

means:

> perform an actual byte write of `'H'` to address `0xF00000`.

`volatile` matters because each write is an externally visible hardware event and must not be optimized away as an ordinary memory store.

---

## What We Observed

During bring-up, the temporary bus trace showed:

```text
0x000000 -> initial SP high word
0x000002 -> initial SP low word
0x000004 -> initial PC high word
0x000006 -> initial PC low word
```

which reconstructed:

```text
SP = 0x00020000
PC = 0x00000100
```

Other observations:

- supervisor program fetches used `FC=110`
- supervisor data accesses used `FC=101`
- `JSR` pushed its return address near `0x01FFFC`
- `RTS` read that return address back
- writes reached `0xF00000`
- byte data appeared duplicated on the 16-bit data bus; `UDS/LDS` select the active byte lane

The temporary console bus trace was removed after validation.

The normal inspection path is now:

```text
simulation
   ↓
VCD
   ↓
Surfer
```

The Lab00 VCD is about 122 kB, so full waveform tracing is practical.

---

## Lab00 Concepts

By the end of Lab00, the important ideas are:

```text
68000 reset vectors
initial SP / PC
stack grows downward
JSR / RTS
assembly sections
object-file sections
linker section placement
ELF -> BIN -> HEX
ROM vs RAM
memory-mapped I/O
pointer dereference
volatile
```

The goal is not to memorize every syntax detail, but to know which layer owns each behavior:

```text
68000 architecture
assembler
linker
compiler
testbench
our conventions
```

---

## Completion

Lab00 is complete when the full path can be explained without treating any line as magic:

```text
RESET
  -> vectors
  -> _start
  -> main
  -> monitor
  -> Hi
```

Next labs can now focus on the 68000 itself rather than simulator infrastructure.
