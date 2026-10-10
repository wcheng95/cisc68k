.global main

/*
 * Level-3 autovector is vector 24+3 = 27.
 *
 * start.S already provides vectors 0 and 1, so skip vectors 2..26.
 */
.section .vectors.lab08,"a"
    .space  25*4
    .long   irq3_handler

.section .text.lab08,"ax"

main:
    /*
     * Stay in supervisor mode, but set the interrupt mask to level 3.
     * A level-3 request is masked because only a higher level is accepted.
     */
    move.w  #0x2300,%sr

    /*
     * Any write to 0xF00010 raises the testbench's fixed level-3 IRQ.
     */
    move.b  #1,0x00f00010

    /*
     * If masking works, normal code reaches here before the IRQ handler.
     */
    move.b  #0x11,0x0100e0

    /*
     * Lower interrupt mask I2:I0 from 3 to 0 while keeping supervisor mode.
     * The already-pending level-3 request can now be accepted.
     */
    andi.w  #0xf8ff,%sr

1:
    cmpi.b  #0xa3,0x0100e2
    bne.s   1b

    /*
     * Handler has run and RTE has restored the interrupted context.
     */
    move.b  #0x22,0x0100e1

    move.b  #'0',0x00f00000
    move.b  #'8',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts

irq3_handler:
    /*
     * Short interrupt exception frame.
     * Saved SR shows the pre-interrupt mask; current SR shows the
     * processor-raised mask while servicing level 3.
     */
    move.w  (%sp),0x0100e4
    move.l  2(%sp),0x0100e6
    move.w  %sr,0x0100ea

    move.b  #0xa3,0x0100e2
    rte
