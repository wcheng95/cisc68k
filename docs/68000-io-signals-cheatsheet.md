# 68000 I/O and Bus Signals Cheat Sheet

Practical reference for the original Motorola 68000 external interface as used in the cisc68k survey.

## Address Space

The 68000 has a 24-bit byte address space:

```text
2^24 bytes = 16 MiB
```

Address range:

```text
0x000000 - 0xFFFFFF
```

The external address pins are:

```text
A1-A23
```

There is no external `A0` pin.

Byte selection is encoded with the upper/lower data strobes:

```text
UDS
LDS
```

So the CPU can still address individual bytes across the 16 MB byte-addressed space.

---

## Main Bus Signals

### Address bus

```text
A1-A23
```

23 physical address pins.

Together with `UDS/LDS`, they identify the addressed byte or word.

### Data bus

```text
D0-D15
```

16-bit bidirectional data bus.

Used for:

- instruction fetches
- memory reads
- memory writes
- peripheral accesses
- vector fetches

---

## Bus Control

### AS — Address Strobe

```text
AS
```

Active low.

Indicates that the address bus and function-code outputs contain a valid bus-cycle address/type.

In waveforms, `AS` is usually the first signal to watch when identifying a bus transaction.

### R/W — Read / Write

```text
R/W = 1   read
R/W = 0   write
```

Direction of the current bus transfer.

### UDS — Upper Data Strobe

Active low.

Selects the upper byte lane:

```text
D15-D8
```

### LDS — Lower Data Strobe

Active low.

Selects the lower byte lane:

```text
D7-D0
```

### Byte-lane interpretation

Conceptually:

```text
UDS  LDS
 0    0    word transfer
 0    1    upper byte
 1    0    lower byte
 1    1    no byte selected
```

Which strobe corresponds to an even/odd byte follows the 68000 big-endian bus convention.

---

## Handshake and Error Signals

### DTACK — Data Transfer Acknowledge

Active low.

Asserted by memory or a peripheral when the transfer can complete.

Conceptually:

```text
CPU asserts AS
    ->
device decodes address
    ->
device supplies/accepts data
    ->
device asserts DTACK
    ->
CPU completes cycle
```

Keeping `DTACK` inactive inserts wait states.

For our standalone peripherals, internal behavior may be trivial, but `DTACK` behavior at the 68000 boundary should match the experiment.

### BERR — Bus Error

Active low.

Used to terminate a bus cycle with an error rather than a successful acknowledgement.

Useful for studying:

- bus-error exception entry
- stack frame generation
- vector fetch
- recovery behavior

### VPA — Valid Peripheral Address

Active low.

Used for 6800-style peripheral cycles and autovector-related behavior.

Most basic RAM/ROM experiments do not need it.

### VMA — Valid Memory Address

Output used with 6800-compatible peripherals.

Not required for the minimal ROM/RAM/monitor environment.

### E — Enable Clock

6800-compatible peripheral timing output.

Again, not needed for the baseline machine.

---

## Function Codes

```text
FC2 FC1 FC0
```

These indicate the type of address space being accessed.

Common values:

| FC2:FC0 | Meaning |
| --- | --- |
| `001` | User data |
| `010` | User program |
| `101` | Supervisor data |
| `110` | Supervisor program |
| `111` | CPU space |

CPU space is important for interrupt acknowledge cycles.

The function-code outputs are especially useful in VCD traces because they distinguish instruction fetches, data accesses, supervisor accesses, and interrupt-related cycles.

---

## Interrupt Inputs

### IPL0-IPL2

```text
IPL2 IPL1 IPL0
```

Interrupt Priority Level inputs.

They encode levels 0-7.

Level 0 means no interrupt request.

Higher levels represent higher interrupt priority.

These inputs are asynchronous from the architectural point of view; the CPU samples them according to its internal timing.

The current interrupt mask is held in the status register.

---

## Interrupt Acknowledge

During interrupt processing, the CPU performs a special bus cycle.

A useful waveform signature is:

```text
FC2:FC0 = 111
AS asserted
interrupt level encoded on address-related signals
```

The interrupting system may then provide:

- an externally supplied vector
- an autovector response

For the survey, the interrupt peripheral itself can be extremely simple as long as the 68000-visible acknowledge/vector behavior is correct.

---

## Reset and Halt

### RESET

Bidirectional/open-drain-style reset signal in the original system interface.

Used to reset the processor and external system.

### HALT

Used both as an input and as part of processor error/retry behavior.

For the initial standalone simulator, normal reset handling is enough.

---

## Bus Arbitration

### BR — Bus Request

External bus master requests ownership of the bus.

### BG — Bus Grant

CPU grants bus ownership.

### BGACK — Bus Grant Acknowledge

External master acknowledges that it has taken control of the bus.

These are not needed for the initial survey.

Only add a bus-master experiment if we explicitly decide to study arbitration.

---

## Clock

### CLK

Main processor clock input.

The original 68000 external bus timing is synchronous to this clock even though transfer completion depends on the asynchronous `DTACK` handshake.

---

## Minimal Signals for Our Standalone Machine

For most early experiments, focus on:

```text
A1-A23
D0-D15
AS
R/W
UDS
LDS
DTACK
RESET
FC0-FC2
```

Then add only when needed:

```text
BERR       bus-error study
IPL0-IPL2  interrupt study
VPA        autovector / peripheral study
BR/BG/...  arbitration study
```

This keeps the environment aligned with the project rule:

> Peripheral internals may be simple; behavior visible at the 68000 boundary must be correct.

---

## Typical Read Cycle

Conceptually:

```text
CPU drives address + FC
CPU asserts AS
CPU asserts UDS/LDS
R/W = 1

device decodes address
device drives D0-D15
device asserts DTACK

CPU samples data
CPU deasserts AS/strobes
device releases DTACK/data
```

---

## Typical Write Cycle

Conceptually:

```text
CPU drives address + FC
CPU drives D0-D15
CPU asserts AS
CPU asserts UDS/LDS
R/W = 0

device decodes address
device captures selected byte(s)
device asserts DTACK

CPU completes cycle
CPU deasserts AS/strobes
device releases DTACK
```

---

## Waveform Checklist

When looking at a transaction in Surfer, ask:

1. What address is on `A1-A23`?
2. Which byte lanes are selected by `UDS/LDS`?
3. Is it a read or write?
4. What do `FC2:FC0` say about the access type?
5. When does `DTACK` arrive?
6. What data is transferred?
7. Is `BERR` involved?
8. If interrupt-related, what are `IPL`, `FC`, and acknowledge behavior doing?

That set of questions is enough to explain most early 68000 bus activity.
