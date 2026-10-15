# Lab12 — CISC vs RISC

## Goal

Finish the 68000 survey by comparing it with the RV32I/PicoRV32 survey using observations from the two lab series.

This is not a performance benchmark and not a claim that one ISA is universally better. The comparison is about where each architecture places work:

```text
instruction set
compiler
CPU implementation
external bus / system
```

The comparison is deliberately limited to the two systems actually studied:

- Motorola 68000 using fx68k
- RV32I using PicoRV32

Xtensa/LX7 is omitted because it was not surveyed with the same experiments.

## Evidence Base

### cisc68k

Labs 01–11 covered:

- D0–D7 and A0–A7 register model
- variable-length instruction encoding
- rich effective-address modes
- stack calls, `JSR/RTS`, `LINK/UNLK`
- CCR condition codes
- exceptions, privilege and vector table
- external interrupts and interrupt acknowledge
- 68000 external bus
- memory-mapped I/O
- GCC ABI output at `-O0` and `-Os`

### riscv32

Labs 00–11 and 13 covered:

- x0–x31 register model
- fixed 32-bit RV32I R/I/S/B/U/J formats
- ALU shifts and signed/unsigned operations
- explicit loads/stores and byte strobes
- branches, `jal`, and `jalr`
- PicoRV32 native `mem_valid/mem_ready` interface and wait states
- cycle versus retired-instruction observation
- register-file implementation tradeoffs
- traps
- PicoRV32 custom IRQ/EOI mechanism
- PCPI coprocessor interface
- GCC ILP32 ABI output at `-O0` and `-Os`

## 1. Register Model

### 68000

The programmer sees two register classes:

```text
D0–D7   data registers
A0–A7   address registers
A7      stack pointer
```

Instruction semantics depend on the class. Address registers participate naturally in address generation and stack operations.

### RV32I

The programmer sees one mostly uniform integer register file:

```text
x0      hard-wired zero
x1–x31  general integer registers
```

ABI names such as `ra`, `sp`, `a0`, and `s0` are conventions layered on the ISA.

### Observation

The 68000 encodes more architectural intent into register classes. RV32I provides more general integer registers and lets software/ABI assign roles.

## 2. Instruction Encoding

### 68000

Instructions are variable length. The survey observed opcode words plus extension words for immediates, addresses and effective-address information.

Examples ranged from compact one-word operations to multiword instructions such as absolute `JSR`.

### RV32I

Every base instruction studied was one 32-bit word using one of six regular formats:

```text
R I S B U J
```

Register fields stay in regular positions; immediates are sometimes split to preserve that regularity.

### Observation

The 68000 spends encoding complexity to describe richer operations and addressing forms.

RV32I spends more instructions when necessary, but keeps base instruction decode much more regular.

## 3. Memory Operands and Addressing

A strong 68000 example from Lab11 was:

```asm
addq.l #3,-4(%a6)
```

This directly modifies a stack local in memory.

The equivalent RV32I style requires the value to pass through a register:

```asm
lw   t0,-4(s0)
addi t0,t0,3
sw   t0,-4(s0)
```

The exact compiler sequence can differ, but RV32I arithmetic itself does not take a memory operand.

### 68000 addressing observed

- register direct
- address indirect
- postincrement
- predecrement
- displacement
- indexed
- absolute
- PC-relative
- immediate

### RV32I addressing observed

Loads and stores use:

```text
base register + signed immediate
```

More complicated addresses are built explicitly with integer instructions.

### Observation

This is one of the clearest places where the word **CISC** was visible in our experiments.

The 68000 lets one instruction combine:

```text
address calculation + memory access + arithmetic
```

RV32I separates those jobs.

## 4. Condition Handling

### 68000

Arithmetic and compare operations update the CCR:

```text
X N Z V C
```

Branches then interpret those stored flags.

Examples:

```asm
cmp
blt
bhi
```

Signed and unsigned branches interpret different combinations of N/V/C/Z.

### RV32I

The RV32I ALU lab found no CCR-like arithmetic flag register.

Branches directly compare registers:

```asm
blt
bltu
bgeu
beq
```

Signedness belongs directly to the chosen operation.

### Observation

68000 separates:

```text
produce condition flags
then consume them
```

RV32I generally expresses the comparison at the branch itself.

The 68000 flags can be reused by following instructions, but they also create implicit architectural state. RV32I keeps this dependency explicit in register operands.

## 5. Calls and Return Addresses

### 68000

`JSR` pushes the return PC onto the memory stack.

Our bus trace showed the target instruction stream being prefetched while the JSR microsequence was still performing the return-address stack writes.

`RTS` reads the return PC from the stack.

### RV32I

`jal` and `jalr` write the link address to a register.

By ABI convention:

```text
ra = x1
```

A leaf function can return with:

```asm
ret
```

which is an assembler alias for a `jalr` using `ra`.

### Observation

The 68000 call instruction has an architecturally defined memory-stack side effect.

RV32I makes the link register explicit. Memory stack traffic occurs only when software needs to save that register or other state.

## 6. C ABI

The two compiler labs used essentially the same function:

```c
int add3(int a, int b)
{
    int sum = a + b;
    sum += 3;
    return sum;
}
```

### 68000 ABI observed

Arguments were passed on the stack:

```text
SP+4   a
SP+8   b
```

after the return address.

Integer return value:

```text
D0
```

At `-O0`, GCC used a frame pointer and:

```asm
link
...
unlk
rts
```

At `-Os`, `add3` collapsed to:

```asm
move.l 4(%sp),%d0
add.l  8(%sp),%d0
addq.l #3,%d0
rts
```

### RV32I ABI observed

The first scalar arguments arrived in:

```text
a0
a1
```

and the result returned in:

```text
a0
```

At `-O0`, GCC created a stack frame and spilled state.

At `-Os`, `add3` became only:

```text
add
addi
ret
```

with no stack frame.

The measured whole-program RV32I results were:

| Build | .text | Testbench cycles |
| --- | ---: | ---: |
| `-O0` | 208 bytes | 262 |
| `-Os` | 100 bytes | 121 |

These RV32I numbers show optimization effects within that experiment. They must **not** be compared numerically with cisc68k cycle counts because the CPUs, memory systems and testbenches differ.

### Observation

The ABI matters almost as much as the ISA when reading compiler output.

The 68000 ABI in our toolchain naturally exposed its memory stack at every call.

The RV32I ABI used the larger flat register file to pass the simple arguments without memory traffic.

## 7. Stack Frames

The 68000 has dedicated frame instructions:

```asm
link %a6,#-N
...
unlk %a6
```

RV32I does not need dedicated frame instructions. GCC constructs a frame using ordinary arithmetic and stores/loads involving `sp` and, when desired, `s0` as a frame pointer.

### Observation

Again the 68000 places a common software pattern directly into the ISA.

RV32I builds the same abstraction from simpler instructions.

## 8. Exceptions and Traps

### 68000

The architecture provides a vector table and defined exception entry behavior.

The labs directly observed:

- `TRAP #0`
- illegal instruction
- privilege violation
- saved SR and PC
- supervisor entry
- `RTE`

A useful detail from Lab06:

```text
TRAP:
    saved PC = next instruction

ILLEGAL:
    saved PC = offending instruction
```

### PicoRV32/RV32I survey

Lab09 used PicoRV32's terminal `trap` output for illegal instruction and misaligned load.

That core/configuration did **not** implement the conventional privileged RISC-V Machine-mode `mtvec/mepc/mcause/mret` exception machinery.

### Observation

This is not a clean CISC-versus-RISC distinction.

The 68000 survey included a complete architectural exception mechanism.

The PicoRV32 lab intentionally studied a very small RV32I implementation whose default trap behavior is much simpler.

Do not generalize PicoRV32's terminal trap signal to all RISC-V CPUs.

## 9. Interrupts

### 68000

Interrupt handling is architecturally integrated with:

```text
IPL levels
SR interrupt mask
interrupt acknowledge bus cycle
VPA/autovector
external vector supply
exception stack frame
RTE
```

Lab08 observed a pending level-3 interrupt remain masked until the SR interrupt mask was lowered, followed by an IACK cycle and autovector entry.

### PicoRV32

Lab10 studied PicoRV32's optional **custom** IRQ system:

```text
irq
maskirq
eoi
retirq
```

This is explicitly not the standard RISC-V privileged interrupt architecture.

### Observation

This experiment compares two CPU implementations, not CISC versus RISC in general.

The 68000 interrupt mechanism is part of the architecture studied.

PicoRV32 deliberately provides a compact implementation-specific mechanism.

## 10. External Memory Interface

### 68000 / fx68k boundary

The survey observed the classic processor bus:

```text
address
16-bit data
AS
UDS/LDS
R/W
DTACK
FC
IPL
```

A longword transfer requires two 16-bit bus transactions.

Byte lane selection uses UDS/LDS, with A0 effectively represented by the lane choice.

### PicoRV32 boundary

The native interface uses:

```text
mem_valid
mem_ready
mem_addr
mem_wdata
mem_rdata
mem_wstrb
mem_instr
```

Instruction fetches and data transfers use the same native interface.

Lab06 measured:

```text
WAIT=0 -> 37 cycles
WAIT=3 -> 67 cycles
```

for the same program, adding 30 cycles across ten handshakes.

### Common lesson

Despite very different signal sets, both interfaces support the same fundamental idea:

```text
CPU presents a transfer
memory/peripheral may delay completion
CPU waits until the transfer is acknowledged
```

For fx68k the completion mechanism is DTACK.

For PicoRV32 it is the `mem_valid && mem_ready` handshake.

## 11. Memory-Mapped I/O

The two surveys agree strongly here.

Neither CPU needs a special I/O instruction.

Software performs an ordinary memory access to an address decoded by external logic.

For the 68000 Lab10:

```text
MOVE -> 0xF00020 -> MMIO register
```

For a RISC-V system the same principle appears as an ordinary load/store to the peripheral address.

### Observation

Memory-mapped I/O is a system organization choice shared comfortably by both ISA styles.

## 12. Fetch Does Not Mean Execute

Both projects exposed an important microarchitectural lesson.

The 68000 trace showed target prefetch activity during the JSR microsequence before all JSR stack writes had completed.

The PicoRV32 trace showed instruction fetches from paths later skipped by taken branches.

Therefore:

```text
external instruction fetch != instruction retirement
```

This is true regardless of CISC or RISC.

The bus trace tells us what crossed the memory interface, not necessarily which instructions retired.

## 13. Where the Complexity Goes

The experiments support a more useful statement than:

```text
CISC complex
RISC simple
```

### 68000 places more work inside an instruction

Examples observed:

- memory operands in arithmetic
- many effective-address modes
- implicit condition-code updates
- stack side effect built into JSR
- dedicated LINK/UNLK
- variable instruction length

This can reduce the number of explicit instructions needed to express some operations.

But the CPU must handle:

- variable-length decode
- extension words
- effective-address calculation
- memory operands inside instructions
- implicit CCR state
- multi-step instruction microsequences

### RV32I exposes more of the work as instructions/register operations

Examples observed:

- arithmetic operates on registers
- loads/stores explicitly move values between registers and memory
- branches compare register operands directly
- link address is written to a register
- stack frames are synthesized from ordinary instructions
- fixed 32-bit base instruction formats

The CPU sees simpler individual architectural operations, while compilers/software compose more of them.

## Final Answer

> What does the richer 68k ISA buy, and what complexity does it move into the processor?

From these labs, the richer 68000 ISA buys **expressiveness per instruction**.

One instruction can often describe more:

```text
where the operand is
how the address changes
whether memory is accessed
what arithmetic occurs
what condition state is produced
```

That can make assembly compact and can directly encode common software patterns such as stack frames and memory arithmetic.

The cost is that more work must happen behind the instruction boundary: decoding is less regular, operands can require multiple bus operations, instruction length varies, and execution often becomes a microsequence.

RV32I makes the opposite trade more aggressively. Its base instructions describe smaller, more regular operations. More sequencing is visible in software and compiler output, while the architectural operations presented to the CPU are comparatively uniform.

The most important conclusion from both projects is therefore not that one side is simply "better":

```text
68000:
    richer architectural vocabulary per instruction

RV32I:
    smaller and more regular architectural primitives
```

Both still require sophisticated implementations to become fast CPUs, and both can expose prefetch, stalls, wait states and other behavior below the ISA level.

## Completion

**CLOSED — 2026-10-14.**

The cisc68k architectural survey is complete through Lab12.

The final comparison is based on the completed cisc68k Labs 01–11 and riscv32 Labs 00–11 and 13. No additional RTL or synthetic benchmark was required for this capstone.
