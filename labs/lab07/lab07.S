.global main

/*
 * Lab07 adds vector 8: privilege violation.
 *
 * start.S already provides vectors 0 and 1. Fill vectors 2..7,
 * then install vector 8.
 */
.section .vectors.lab07,"a"
    .space  6*4
    .long   privilege_handler

.section .text.lab07,"ax"

main:
    /*
     * Start in supervisor mode after reset.
     * Clear SR.S (bit 13) to enter user mode.
     */
    andi.w  #0xdfff,%sr

    /*
     * Ordinary memory-mapped writes still work in user mode on this
     * simple 68000 system; there is no MMU/protection hardware here.
     */
    move.b  #0x11,0x0100d0

    /*
     * RESET is privileged. In user mode this causes vector 8 instead
     * of executing RESET.
     */
    reset

    /*
     * The handler advances the saved PC over RESET and RTE returns
     * here, back in user mode.
     */
    move.b  #0x22,0x0100d1

    move.b  #'0',0x00f00000
    move.b  #'7',0x00f00000
    move.b  #10,0x00f00000

1:
    bra.s   1b

privilege_handler:
    /*
     * Exception entry switches to supervisor mode and uses the
     * supervisor stack. The stacked SR is the pre-exception user SR.
     */
    move.w  (%sp),0x0100d4
    move.l  2(%sp),0x0100d6
    move.w  %sr,0x0100da
    move.b  #0xa8,0x0100d2

    /*
     * Saved PC points at the offending 2-byte RESET opcode.
     * Skip it before returning.
     */
    addq.l  #2,2(%sp)
    rte
