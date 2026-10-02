# Mission and Scope

## Mission

Use the Motorola 68000 as a clean classic-CISC reference and compare what it exposes architecturally with modern RISC machines such as Xtensa LX7 and RISC-V.

The project is about understanding the CPU and its visible system boundary, not about retro-computing for its own sake.

## Why 68k

The 68000 is attractive because it combines:

- separate data and address registers
- rich addressing modes
- variable-length instructions
- a clean supervisor/user model
- vectored exceptions and interrupts
- a conventional external bus
- visible interrupt-acknowledge cycles
- a well-known historical programming model

## In Scope

- programming model
- instruction encoding
- operand sizes
- addressing modes
- stack and subroutine calls
- condition codes
- exceptions and vector table
- supervisor and user state
- interrupts and interrupt acknowledge
- external bus protocol
- DTACK, wait states, and BERR
- memory-mapped I/O
- tiny bare-metal programs
- compiler-generated assembly
- cycle-level waveform observation
- comparison with LX7 and RISC-V

## Out of Scope

- designing a new 68k CPU
- studying fx68k RTL internals in detail
- writing a custom emulator
- Atari/Amiga/Macintosh recreation
- Linux porting
- graphics/audio/storage/networking projects
- FPGA deployment as a requirement
- physical bus probing
- custom PCB design

## Scope Rule

The environment exists to support the survey.

Before adding anything, ask:

1. Which architecture question requires it?
2. Can the existing environment answer the question already?
3. Are we drifting into building a retro computer instead of studying the CPU?

A TX-only UART is enough for most survey experiments. Interactive RX is not a requirement.
