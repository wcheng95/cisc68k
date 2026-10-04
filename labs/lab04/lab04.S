.global main

.section .text.lab04,"ax"

main:
    /*
     * Push one longword argument manually.
     * A7 is the stack pointer and the stack grows downward.
     */
    move.l  #0x00001234,-(%a7)

    /*
     * BSR is a PC-relative subroutine call.
     * It pushes the return PC, then branches to frame_demo.
     */
    bsr.w   frame_demo

    /* Caller removes the 4-byte argument after return. */
    addq.l  #4,%a7

    /* Save the returned D0 value where it is easy to inspect. */
    move.l  %d0,0x010080

    /*
     * JSR also pushes a return PC, but here the destination is encoded
     * as an absolute address rather than a relative BSR displacement.
     */
    jsr     leaf_demo
    move.l  %d0,0x010084

    /* Minimal completion marker. */
    move.b  #'0',0x00f00000
    move.b  #'4',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts


/*
 * Stack on entry:
 *
 *   0(A7)   return PC
 *   4(A7)   argument = 0x00001234
 *
 * LINK A6,#-4 creates:
 *
 *  -4(A6)   one 4-byte local variable
 *   0(A6)   saved old A6
 *   4(A6)   return PC
 *   8(A6)   argument
 */
frame_demo:
    link.w  %a6,#-4

    move.l  8(%a6),%d0
    addq.l  #1,%d0
    move.l  %d0,-4(%a6)

    /* Return the local value in D0. */
    move.l  -4(%a6),%d0

    unlk    %a6
    rts


/*
 * Simple leaf routine: no local stack frame needed.
 * D0 return value is an ABI convention, not a 68000 hardware rule.
 */
leaf_demo:
    move.l  #0x89abcdef,%d0
    rts
