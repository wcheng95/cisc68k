// Minimal 68000 reset/startup for the survey labs.
//
// [68K] Reset reads:
//   0x000000 -> initial supervisor SP
//   0x000004 -> initial PC
//
// [CONV] Our RAM is 0x010000-0x01FFFF, so SP starts one
// address above RAM and grows downward.

.section .vectors,"a"          // [ASM][CONV] reset-vector section
    .long   0x00020000        // [68K][NOW] initial supervisor SP
    .long   _start            // [68K][NOW] initial PC

// [CONV] Keep startup code in its own executable section so
// the linker can place it before normal program text.
.section .text.start,"ax"

.global _start                // [ASM] export startup symbol
.extern main                  // [ASM] main() is defined by the lab

_start:
    jsr     main              // [68K] call C entry point; pushes return PC

// No OS/caller exists above _start. If main returns, park here.
1:
    bra.s   1b                // [68K][ASM] short branch to local label 1
