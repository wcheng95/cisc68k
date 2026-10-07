.global main

/*
 * Lab06 adds vector 4 (illegal instruction) and vector 32 (TRAP #0).
 *
 * labs/common/start.S already emitted vectors 0 and 1, so this input
 * section starts at vector 2 when link.ld appends .vectors.*.
 */
.section .vectors.lab06,"a"
    .long   0                       /* vector 2: bus error */
    .long   0                       /* vector 3: address error */
    .long   illegal_handler         /* vector 4: illegal instruction */

    /* Skip vectors 5..31. */
    .space  27*4

    .long   trap0_handler           /* vector 32: TRAP #0 */

.section .text.lab06,"ax"

main:
    /*
     * TRAP #0 enters through vector 32.
     * Its stacked PC already points to the instruction after TRAP,
     * so RTE can return normally.
     */
    trap    #0
    move.b  #0x11,0x0100c0

    /*
     * ILLEGAL enters through vector 4.
     * The handler advances the stacked PC by one opcode word before RTE
     * so execution resumes here instead of taking the same exception again.
     */
    illegal
    move.b  #0x22,0x0100c1

    move.b  #'0',0x00f00000
    move.b  #'6',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts

trap0_handler:
    /* Original 68000 normal exception frame: SR at (SP), PC at 2(SP). */
    move.w  (%sp),0x0100c4
    move.l  2(%sp),0x0100c6
    move.b  #0xa0,0x0100c2
    rte

illegal_handler:
    move.w  (%sp),0x0100ca
    move.l  2(%sp),0x0100cc
    move.b  #0xa4,0x0100c3

    /* Skip the 2-byte ILLEGAL opcode before returning. */
    addq.l  #2,2(%sp)
    rte
