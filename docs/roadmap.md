# Survey Roadmap

## 01 — Programming Model

Study D0-D7, A0-A7, stack pointer, PC, SR/CCR, supervisor state, and byte/word/long operands.

Questions:

- Why separate data and address registers?
- Which instructions use each class?
- How does the register model differ from LX7 and RISC-V?

Experiment: tiny assembly sequences with register-state inspection.

## 02 — Instruction Encoding

Study variable-length instructions, opcode words, extension words, immediates, and effective-address fields.

Decode representative instructions manually:

```asm
MOVE.L
MOVE.W
ADD.L
LEA
JSR
RTS
BRA
```

## 03 — Addressing Modes

Study:

- data-register direct
- address-register direct
- address-register indirect
- post-increment
- pre-decrement
- displacement
- indexed
- absolute
- PC-relative
- immediate

Compare instruction count and bus activity for equivalent operations.

## 04 — Stack and Calls

Study A7, JSR, BSR, RTS, LINK, UNLK, parameters, locals, and basic ABI behavior.

Compare directly with Xtensa register windows.

## 05 — Condition Codes and Control Flow

Study N/Z/V/C/X, compares, signed/unsigned branches, and loops.

## 06 — Exceptions and Vector Table

Study reset, bus/address error, illegal instruction, privilege violation, traps, and exception stack frames.

## 07 — Supervisor and User Mode

Study privileged instructions, supervisor state, and what protection mechanisms the original 68000 does and does not provide.

## 08 — Interrupt Architecture

Study IPL levels, masking, acknowledge cycles, autovectors, supplied vectors, nesting, and RTE.

## 09 — External Bus

Observe:

- address/data buses
- AS
- UDS/LDS
- R/W
- DTACK
- BERR
- function codes
- IPL inputs

Capture instruction fetches, byte/word/long reads and writes, stack traffic, interrupt acknowledge, and wait states.

## 10 — Memory-Mapped I/O

Use a deliberately simple write-only monitor register as the baseline peripheral.

Standalone milestone:

```text
68000 program
  -> memory-mapped monitor write
  -> testbench/host console
  -> Hi
```

The earlier Mackerel-F 16550 UART experiment remains useful as proof that the full reference system works, but the standalone survey machine does not need UART behavior.

Any later peripheral should exist only to expose a specific 68000 mechanism. Its internals may be simplified; its behavior at the 68000 boundary must remain correct for the experiment.

## 11 — C Compiler and ABI

Compile tiny C functions and inspect argument passing, return values, register allocation, stack frames, addressing modes, and optimization effects.

## 12 — CISC vs RISC

Compare observed behavior, not slogans.

| Topic | 68000 | Xtensa LX7 | RISC-V |
| --- | --- | --- | --- |
| ISA style | classic CISC | configurable RISC | load/store RISC |
| registers | D/A classes | windowed address registers | flat integer registers |
| instruction length | variable | variable/configurable | regular base + compressed |
| memory operands | rich | more restricted | explicit load/store |
| addressing modes | rich | comparatively limited | simple |
| calls | stack/register ABI | register windows | register ABI |
| exceptions | vector table | Xtensa model | trap model |
| bus visibility | classic MPU bus | SoC fabric | implementation dependent |

Final question:

> What does the richer 68k ISA buy, and what complexity does it move into the processor?
