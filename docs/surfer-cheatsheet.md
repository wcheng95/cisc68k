# Surfer Cheat Sheet

Practical waveform-viewer reference for cisc68k.

## Open a VCD

```bash
surfer mackerel_f_tb.vcd
```

For unit tests:

```bash
surfer timer.vcd
```

## Commands and Shortcuts

Surfer has both direct keyboard shortcuts and a command prompt.

Press **Space** to open the command prompt, then type a command name. Fuzzy matching is supported, so partial names are often enough.

### Zoom and horizontal navigation

| Action | Shortcut | Command |
| --- | --- | --- |
| Zoom in | `+` or `=` | `zoom_in` |
| Zoom out | `-` | `zoom_out` |
| Zoom to fit entire trace | `Shift+F` | `zoom_fit` |
| Zoom toward cursor | `Shift+Z` | — |
| Go to start | `S` | `goto_start` |
| Go to end | `E` | `goto_end` |
| Go to exact time | `Command+G` | `goto_time <TIME>` |
| Zoom to exact range | — | `zoom_to <START> <END>` |

Examples:

```text
Space
goto_time 100us
```

```text
Space
zoom_to 10us 20us
```

Mouse/trackpad:

- ordinary horizontal scroll pans the waveform
- **Ctrl + scroll** zooms the waveform
- cursor position is set by clicking in the waveform area

### Cursor and transitions

By default, Surfer can use the arrow keys to move between transitions of the focused signal. This behavior is configurable.

Useful commands:

```text
transition_next
transition_previous
goto_cursor
cursor_set 125us
```

For architecture work, focusing a bus/control signal and stepping transition-by-transition is often the fastest way to inspect one 68000 cycle.

### Markers and measurements

| Action | Shortcut / command |
| --- | --- |
| Add marker at cursor | `M` |
| Set numbered marker 0–9 | `Command+0` … `Command+9` on macOS |
| Center view on numbered marker | `0` … `9` |
| Open marker/delta window | `Space` → `show_marker_window` |
| Set named/numbered marker | `marker_set <NAME>` or `marker_set #N` |
| Go to marker | `goto_marker <NAME>` or `goto_marker #N` |

Markers are useful for measuring:

- AS assertion → DTACK assertion
- start bit → stop bit
- exception entry → vector fetch
- interrupt assertion → acknowledge cycle

### Signal list / hierarchy navigation

| Action | Shortcut |
| --- | --- |
| Focus variable quickly | `F` |
| Focus variable-name filter/search | `V` |
| Toggle selection of focused signal | `A` |
| Select all | `Command+A` |
| Delete selected waveform items | `Delete` or `X` |
| Rename item | `F2` |
| Add divider | `D` |
| Toggle side panel | `B` |
| Scroll signal list up | `PageUp` |
| Scroll signal list down | `PageDown` |

Additional keyboard navigation shown by Surfer's built-in help:

```text
j / Down Arrow       scroll down
k / Up Arrow         scroll up
Alt+j / Alt+Down     move focus down
Alt+k / Alt+Up       move focus up
Ctrl+j / Ctrl+Down   move focused item down
Ctrl+k / Ctrl+Up     move focused item up
```

### File and view controls

| Action | Shortcut |
| --- | --- |
| Open waveform | `Command+O` |
| Switch waveform while keeping view | `Command+Shift+O` |
| Reload waveform | `R` |
| Save state | `Command+S` |
| Undo | `Command+Z` or `U` |
| Redo | `Command+Shift+Z` or `Command+Y` |
| Toggle toolbar | `T` |
| Toggle menu | `Alt+M` |

### Built-in help

From the command prompt:

```text
show_controls
show_mouse_gestures
show_quick_start
```

These are useful because Surfer's shortcuts are configurable, and the built-in help reflects the current configuration.

### Handy command-prompt examples

```text
zoom_fit
zoom_in
zoom_out
goto_start
goto_end
goto_time 250us
zoom_to 100us 120us
cursor_set 110us
transition_next
transition_previous
show_marker_window
```

## What to Look At First

For 68000 architecture work, useful signal groups include:

### CPU bus

```text
ADDR_BUS
DATA_BUS_IN
DATA_BUS_OUT
ASn
UDSn
LDSn
RWn
DTACKn
BERRn
FC0
FC1
FC2
IPL0n
IPL1n
IPL2n
```

### UART

```text
uart_tx
uart_rx
cs_uart_n
dtack_uart
uart_dout
```

### ROM / decode

```text
address
cs_rom_n
cs_sdram_n
cs_bsram_n
cs_periph_n
BOOT
```

### Timing

```text
clk_soc
enPhi1
enPhi2
rst_cpu
```

## Recommended Viewing Order

For a tiny ROM test:

1. reset
2. first ROM fetch
3. CPU address/data bus
4. UART register write
5. UART TX waveform

This gives a clean path from instruction execution to external behavior.

## Useful Waveform Questions

### Is the CPU running?

Look for activity on:

```text
ASn
ADDR_BUS
RWn
```

If these never change after reset, the CPU did not start.

### Did the bus cycle complete?

Look at:

```text
ASn
DTACKn
BERRn
```

A normal access should assert AS and eventually receive DTACK.

### Was it a read or write?

```text
RWn = 1  read
RWn = 0  write
```

### Which byte lane was used?

```text
UDSn
LDSn
```

Useful for understanding 68000 byte/word transfers.

### Which address space is active?

Look at:

```text
FC2:FC0
```

These function-code outputs help distinguish user/supervisor program/data space and CPU space.

### Did UART output really come from the CPU?

Follow:

```text
ADDR_BUS
  ->
cs_uart_n
  ->
DATA_BUS_OUT
  ->
dtack_uart
  ->
uart_tx
```

## UART Timing

For 115200-ish UART output:

- idle is high
- start bit is low
- 8 data bits follow LSB first
- stop bit is high

A transmitted byte should look like:

```text
idle  start  d0 d1 d2 d3 d4 d5 d6 d7  stop
 1      0     .  .  .  .  .  .  .  .    1
```

For ASCII `H` = 0x48:

```text
0x48 = 01001000
```

UART sends least-significant bit first.

## Reduce Noise

Dumping the entire hierarchy is convenient initially:

```systemverilog
$dumpvars(0, mackerel_f_tb);
```

If the VCD becomes too large, restrict tracing to useful hierarchy levels.

Examples:

```systemverilog
$dumpvars(1, mackerel_f_tb.dut);
$dumpvars(1, mackerel_f_tb.dut.cpu);
$dumpvars(1, mackerel_f_tb.dut.u);
```

Use the smallest dump that still answers the current architecture question.

## Suggested Signal Groups for Survey Labs

### Programming model / instruction fetch

```text
PC-related internal trace if exposed
ADDR_BUS
DATA_BUS_IN
ASn
DTACKn
```

### Addressing modes

```text
ADDR_BUS
DATA_BUS_IN
DATA_BUS_OUT
RWn
UDSn
LDSn
ASn
DTACKn
```

### Stack / calls

Focus on accesses near A7/SP and look for descending writes/ascending reads.

### Exceptions

Add:

```text
BERRn
FC*
IPL*
VPAn
```

and watch vector fetches plus stack-frame writes.

### Interrupt acknowledge

Look for:

```text
FC2:FC0 = CPU space
ASn
IPL*
VPAn
DTACKn
```

## Practical Habit

For each lab:

1. run the program
2. confirm textual PASS over UART TX
3. open the VCD
4. inspect only the bus cycles that explain the result
5. capture one or two representative observations in the lab notes

The waveform is evidence, not the project itself.
