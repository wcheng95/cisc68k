# Lab08 — Interrupt Architecture

## Goal

Study interrupt levels, SR masking, interrupt acknowledge, autovectors, exception entry, and `RTE`.

Expected output:

```text
08
```

## Interrupt Source

The testbench now contains one deliberately small interrupt source at:

```text
0xF00010   write-only IRQ trigger
```

Any write raises one fixed level-3 interrupt.

The request stays asserted until the 68000 performs an interrupt-acknowledge cycle. During acknowledge, the source asserts `VPA`, so the CPU uses the autovector.

## Interrupt Mask

The SR contains the interrupt mask in bits I2:I0.

Lab08 begins with:

```asm
move.w  #0x2300,%sr
```

Relevant fields:

```text
S = 1
I2:I0 = 3
```

A level-3 interrupt is not accepted while the mask is also 3. The interrupt level must be higher than the current mask.

Then the lab raises level 3:

```asm
move.b  #1,0x00f00010
```

and immediately writes:

```asm
move.b  #0x11,0x0100e0
```

Seeing `0x11` proves execution continued while level 3 was masked.

## Unmask

Next:

```asm
andi.w  #0xf8ff,%sr
```

clears I2:I0 to zero while preserving supervisor mode.

The already-pending level-3 interrupt is now higher than the mask and can be accepted.

## Interrupt Acknowledge

When the CPU accepts the request, it performs a special interrupt-acknowledge bus cycle.

The function codes are:

```text
FC2 FC1 FC0 = 111
```

This should stand out clearly in the default `.trace` file.

The interrupt source responds by asserting `VPA`, requesting an autovector.

## Autovector

68000 autovectors are:

```text
level 1 -> vector 25
level 2 -> vector 26
level 3 -> vector 27
...
level 7 -> vector 31
```

So level 3 uses:

```text
vector 27
address = 27 × 4 = 0x00006C
```

Lab08 places `irq3_handler` at vector 27.

## Handler

The handler records:

```text
0x0100E4   saved pre-interrupt SR
0x0100E6   saved PC
0x0100EA   current SR inside handler
0x0100E2 = 0xA3   handler marker
```

The interesting SR comparison is:

```text
saved SR      interrupt mask = 0
handler SR    interrupt mask = 3
```

The CPU automatically raises its interrupt mask to the accepted interrupt level while servicing it.

This prevents equal or lower interrupt levels from interrupting the current handler.

## Return

The handler ends with:

```asm
rte
```

No PC adjustment is needed for a normal interrupt.

`RTE` restores the interrupted SR and PC, including the previous interrupt mask.

The main code waits until the handler marker appears, then writes:

```text
0x0100E1 = 0x22
```

and prints `08`.

## Trace

Default:

```bash
make clean
make LAB=lab08
cat logs/lab08/lab08.trace
```

Look for this sequence:

```text
write 0xF00010        raise level-3 request
write 0x0100E0        masked code still runs
...
FC=111                interrupt acknowledge
read vector 0x00006C
read vector 0x00006E
...
handler stack traffic
...
RTE
```

The compact trace format is:

```text
<cycle> <R|W> [<addr>] <data> <UDS><LDS> <FC>
```

Use VCD only if timing/internal RTL detail is needed:

```bash
make LAB=lab08 MODE=vcd
```

## Questions

- Why is a level-3 interrupt masked when SR.I=3?
- What changes when SR.I becomes 0?
- What does `FC=111` mean?
- Why does level 3 use vector 27?
- What is the role of `VPA` in this lab?
- Why does the handler SR have interrupt mask 3?
- Why does `RTE` restore the old mask?
