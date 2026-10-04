.global main

.section .text.lab03,"ax"

main:
    /* Base address for the RAM test table. */
    lea     0x010040,%a0

    /* Immediate source + address-register indirect destination. */
    move.w  #0x1111,(%a0)
    move.w  #0x2222,2(%a0)
    move.w  #0x3333,4(%a0)

    /* 1. Address-register indirect: (A0) */
    move.w  (%a0),%d0
    move.w  %d0,0x010060

    /* 2. Post-increment: (A1)+ */
    movea.l %a0,%a1
    move.w  (%a1)+,%d1
    move.w  %d1,0x010062

    /* 3. Pre-decrement: -(A2) */
    movea.l %a0,%a2
    addq.l  #6,%a2
    move.w  -(%a2),%d2
    move.w  %d2,0x010064

    /* 4. Displacement: 2(A0) */
    move.w  2(%a0),%d3
    move.w  %d3,0x010066

    /* 5. Indexed: 0(A0,D4.W) */
    moveq   #4,%d4
    move.w  0(%a0,%d4.w),%d5
    move.w  %d5,0x010068

    /* 6. Absolute address. */
    move.w  0x010040,%d6
    move.w  %d6,0x01006a

    /* 7. PC-relative source in ROM. */
    move.w  rom_word(%pc),%d7
    move.w  %d7,0x01006c

    /* Minimal completion marker. */
    move.b  #'0',0x00f00000
    move.b  #'3',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts

.section .rodata.lab03,"a"
.align 2
rom_word:
    .word   0x4444
