# Lab11 — C Compiler and ABI

## Goal

Use one tiny C program to observe how GCC maps C onto the 68000 ABI.

Focus:

```text
function arguments
return value
stack frame
register use
optimization
generated addressing modes
```

Expected output:

```text
11
```

## C Program

The function under test is:

```c
__attribute__((noinline))
int add3(int a, int b)
{
    int sum = a + b;
    sum += 3;
    return sum;
}
```

`main` calls it with:

```text
a = 5
b = 7
```

Expected result:

```text
15
```

The lab writes:

```text
0x0100F2 = 0x11   PASS
0x0100F2 = 0xEE   FAIL
```

## Why a and b Are volatile

```c
volatile int a = 5;
volatile int b = 7;
```

This prevents GCC from replacing the entire call with a compile-time constant result.

The goal is to force a real function call so we can inspect the ABI.

## Build at -Os

Default:

```bash
make clean
make LAB=lab11
make disasm LAB=lab11
```

The Makefile default is:

```text
OPT=s
```

so this builds with:

```text
-Os
```

## Build at -O0

For a less optimized version:

```bash
make clean
make LAB=lab11 OPT=0
make disasm LAB=lab11 OPT=0
```

Now compare the two disassemblies.

## What to Look For

### Arguments

Inspect how `main` passes:

```text
5
7
```

to `add3`.

For this toolchain/ABI, scalar C arguments are expected on the stack.

Look for pushes before the call and stack cleanup afterward.

### Return Value

The integer return value is expected in:

```text
D0
```

This is ABI convention, not a property of the 68000 ISA itself.

### Stack Frame

At `-O0`, GCC will typically make the C stack frame explicit, often using:

```asm
link
...
unlk
rts
```

At `-Os`, GCC may simplify or omit parts of the frame if they are unnecessary.

The exact generated code is the experiment; do not assume both builds must look the same.

### Local Variable

The source contains:

```c
int sum = a + b;
sum += 3;
```

At `-O0`, `sum` may live in a stack slot.

At `-Os`, the compiler may keep the value entirely in a register and eliminate the stack local.

That is an important compiler distinction:

```text
C local variable
    does not necessarily mean
runtime stack storage
```

### Rich 68k Addressing

Watch for forms such as:

```text
offset(A6)
(SP)
(SP)+
-(SP)
```

The compiler can directly use the 68000's addressing modes for arguments, locals, pushes, and pops.

## Trace

The default bus trace is also useful:

```bash
cat logs/lab11/lab11.trace
```

Look near the function call for:

```text
stack writes     arguments / return address
stack reads      function access / return
program fetches  FC=110
stack/data       FC=101
```

The disassembly explains *what instructions GCC chose*.

The trace shows *what those instructions caused on the external bus*.

## Questions

- Where are the two integer arguments placed?
- Which register carries the integer return value?
- Does `add3` use `LINK/UNLK` at `-O0`?
- Does it still need a frame at `-Os`?
- Does the C local `sum` really occupy memory in both builds?
- Which parts are 68000 ISA behavior and which parts are ABI/compiler convention?
