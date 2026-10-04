# Lab04 — Stack and Calls

## Goal

Study the 68000 call stack directly.

Lab04 focuses on:

```text
A7 / SP
JSR
BSR
RTS
LINK
UNLK
stack arguments
local variables
D0 return value convention
```

Expected output:

```text
04
```

No new hardware is added.

## First Call: BSR + Stack Frame

The caller pushes one longword argument:

```asm
move.l #0x00001234,-(%a7)
bsr.w  frame_demo
```

Before `BSR`:

```text
A7 -> argument
```

`BSR` then pushes the return PC.

On entry to `frame_demo`:

```text
0(A7)   return PC
4(A7)   argument = 0x00001234
```

## LINK

```asm
link.w %a6,#-4
```

`LINK` creates a stack frame using A6 as a frame pointer.

Conceptually:

```text
push old A6
A6 = A7
A7 = A7 - 4
```

After `LINK`:

```text
-4(A6)   local variable
 0(A6)   saved old A6
 4(A6)   return PC
 8(A6)   argument
```

The routine reads its argument with:

```asm
move.l 8(%a6),%d0
```

increments it:

```asm
addq.l #1,%d0
```

and stores the result in its local slot:

```asm
move.l %d0,-4(%a6)
```

Expected value:

```text
0x00001235
```

## UNLK + RTS

```asm
unlk %a6
rts
```

`UNLK` reverses the frame setup:

```text
A7 = A6
restore old A6 from stack
```

Then `RTS` pops the return PC.

Back in the caller:

```asm
addq.l #4,%a7
```

removes the argument.

This lab therefore uses the convention:

> caller pushes arguments and caller removes them.

That is a software calling convention, not a 68000 hardware rule.

## Return Value

The routine leaves:

```text
D0 = 0x00001235
```

and the caller stores it at:

```text
0x010080
```

Using D0 for an integer return value is an ABI/calling-convention choice.

## Second Call: JSR

```asm
jsr leaf_demo
```

`JSR` also pushes a return PC.

This routine needs no locals, so it does not create a frame:

```asm
leaf_demo:
    move.l #0x89abcdef,%d0
    rts
```

The returned value is stored at:

```text
0x010084 = 0x89ABCDEF
```

This shows that a stack frame is optional. A routine only needs one when it needs the structure it provides.

## BSR vs JSR

Both are subroutine calls and both save a return PC.

In this lab:

```text
BSR   PC-relative destination
JSR   absolute destination
```

Use:

```bash
make disasm LAB=lab04
```

to compare their encodings.

## Build

```bash
make clean
make LAB=lab04
```

Open:

```bash
surfer logs/lab04/lab04.vcd
```

## What to Watch in Surfer

Useful signals:

```text
byte_addr
iEdb
oEdb
ASn
UDSn
LDSn
eRWn
DTACKn
```

Watch the area near the top of RAM:

```text
0x020000
0x01FFFC
0x01FFF8
0x01FFF4
...
```

You should be able to identify:

1. argument push
2. BSR return-PC push
3. LINK old-A6 push
4. local-variable write
5. UNLK restoration
6. RTS return-PC read
7. caller argument removal
8. JSR return-PC push/read

## Questions

- Why is the argument at `8(A6)` after `LINK`?
- What exactly does `LINK A6,#-4` put on the stack?
- What does `UNLK` undo?
- Why does `RTS` work whether or not a routine used `LINK`?
- What is hardware-defined about a call, and what is calling convention?
- Why can a leaf routine avoid creating a stack frame?
