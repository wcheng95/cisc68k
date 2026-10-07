.global main

.section .text.lab05,"ax"

main:
    /*
     * Case 1: zero result.
     * 5 - 5 = 0 -> Z set.
     */
    moveq   #5,%d0
    subq.l  #5,%d0
    move.w  %sr,0x0100a0

    /*
     * Case 2: negative result.
     * 0 - 1 = -1 -> N set.
     */
    moveq   #0,%d1
    subq.l  #1,%d1
    move.w  %sr,0x0100a2

    /*
     * Case 3: signed overflow.
     * 0x7fff + 1 = 0x8000 -> V set, N set.
     */
    move.w  #0x7fff,%d2
    addq.w  #1,%d2
    move.w  %sr,0x0100a4

    /*
     * Case 4: unsigned carry.
     * 0xffff + 1 = 0x0000 -> C/X set, Z set.
     */
    move.w  #0xffff,%d3
    addq.w  #1,%d3
    move.w  %sr,0x0100a6

    /*
     * Same bit pattern, different signed/unsigned interpretation:
     * 0xffff is -1 signed, 65535 unsigned.
     */
    move.w  #0xffff,%d4
    moveq   #1,%d5
    cmp.w   %d5,%d4

    /*
     * Signed: -1 < 1, so BLT must be taken.
     * Store 0x11 if taken, 0xee if not.
     */
    blt.s   1f
    move.b  #0xee,0x0100b0
    bra.s   2f
1:
    move.b  #0x11,0x0100b0
2:

    /*
     * Re-run CMP because branches do not modify CCR, but keeping each
     * check independent makes the intent obvious.
     *
     * Unsigned: 65535 > 1, so BHI must be taken.
     */
    cmp.w   %d5,%d4
    bhi.s   3f
    move.b  #0xee,0x0100b1
    bra.s   4f
3:
    move.b  #0x22,0x0100b1
4:

    /*
     * DBRA loop.
     * D6.W starts at 2 and the body executes 3 times:
     * 2 -> 1 -> 0 -> -1 (stop).
     */
    moveq   #2,%d6
    moveq   #0,%d7
5:
    addq.l  #1,%d7
    dbra    %d6,5b
    move.l  %d7,0x0100b4

    /* Minimal completion marker. */
    move.b  #'0',0x00f00000
    move.b  #'5',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts
