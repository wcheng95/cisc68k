.global main

.section .text.lab02,"ax"

main:
    /* Same CPU, now study how different instructions are encoded. */
    moveq   #5,%d0
    move.w  #0x1234,%d1
    add.w   %d1,%d0

    lea     0x010020,%a0
    move.w  %d0,(%a0)

    bra.s   1f
    nop

1:
    /* Minimal completion marker. */
    move.b  #'0',0x00f00000
    move.b  #'2',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts
