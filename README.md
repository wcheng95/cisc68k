# cisc68k

Study the Motorola 68000 as a classic CISC architecture using a cycle-visible RTL environment.

The goal is architectural understanding: programming model, instruction encoding, addressing modes, calls, exceptions, interrupts, and the external bus. Mackerel-F + fx68k provide the reference system; RTL internals are not the subject unless needed to answer an architectural question.

## Roadmap

1. Programming model — D0-D7, A0-A7, PC, SR, operand sizes
2. Instruction encoding — variable-length opcodes and extension words
3. Addressing modes — direct, indirect, indexed, PC-relative, immediate
4. Calls and stack — JSR/BSR/RTS, LINK/UNLK, ABI basics
5. Condition codes and control flow
6. Exceptions, vectors, supervisor/user mode
7. Interrupts and interrupt acknowledge
8. External bus — AS, UDS/LDS, R/W, DTACK, BERR, FC
9. Memory-mapped I/O and UART output
10. C compiler/ABI examples
11. Concrete CISC vs RISC comparison with LX7 and RISC-V

## Docs

- [Mission and scope](docs/mission-scope.md)
- [Survey roadmap](docs/roadmap.md)
- [Reference RTL environment](docs/environment.md)
- [macOS toolchain build](docs/macos-toolchain.md)
- [Simulation checkpoint](docs/simulation-checkpoint.md)
