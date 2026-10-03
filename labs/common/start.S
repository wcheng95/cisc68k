.section .vectors,"a"
    .long   0x00020000
    .long   _start

.section .text.start,"ax"
.global _start
.extern main

_start:
    jsr     main

1:
    bra.s   1b
