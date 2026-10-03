.global main

.section .text.lab01,"ax"

main:
    /* Data register: one 32-bit value, observed at three operand sizes. */
    move.l  #0x12345678,%d0

    move.b  %d0,0x010000
    move.w  %d0,0x010002
    move.l  %d0,0x010004

    /* Address register: point A0 at RAM, then write through it. */
    movea.l #0x010010,%a0
    move.l  #0x89abcdef,(%a0)

    /* Minimal completion marker. */
    move.b  #'0',0x00f00000
    move.b  #'1',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts
