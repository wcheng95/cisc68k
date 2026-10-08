.global main

/*
 * Lab06 adds vector 4 (illegal instruction) and vector 32 (TRAP #0).
 *
 * labs/common/start.S already emitted vectors 0 and 1, so this input
 * section starts at vector 2 when link.ld appends .vectors.*.
 */
.section .vectors.lab06,"a"
    .long   0
    .long   0
    .long   illegal_handler

    .space  27*4

    .long   trap0_handler

.section .text.lab06,"ax"

main:
    /*
     * TRAP #0 saves the PC of the following instruction, so RTE
     * returns here normally.
     */
    trap    #0
    move.b  #0x11,0x0100c0

    /*
     * ILLEGAL saves the address of the offending opcode itself on
     * this original-68000 path. The handler advances the saved PC
     * by one word before RTE.
     */
    illegal
    move.b  #0x22,0x0100c1

    move.b  #'0',0x00f00000
    move.b  #'6',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts

trap0_handler:
    move.w  (%sp),0x0100c4
    move.l  2(%sp),0x0100c6
    move.b  #0xa0,0x0100c2
    rte

illegal_handler:
    move.w  (%sp),0x0100ca
    move.l  2(%sp),0x0100cc
    move.b  #0xa4,0x0100c3

    addq.l  #2,2(%sp)
    rte
