.global main

.section .text.lab09,"ax"

main:
    /*
     * Fixed register value makes byte/word/long bus behavior easy to read.
     */
    move.l  #0x12345678,%d0

    /*
     * Byte writes:
     *   even address -> upper data lane (UDS)
     *   odd address  -> lower data lane (LDS)
     */
    move.b  %d0,0x010100
    move.b  %d0,0x010101

    /*
     * One 16-bit word transfer on the original 68000 bus.
     */
    move.w  %d0,0x010102

    /*
     * One 32-bit MOVE.L becomes two 16-bit bus cycles.
     */
    move.l  %d0,0x010104

    /*
     * Read the same sizes back so trace shows both R and W cycles.
     */
    move.b  0x010100,%d1
    move.w  0x010102,%d2
    move.l  0x010104,%d3

    /*
     * JSR/RTS adds visible supervisor-data stack traffic.
     */
    jsr     bus_subroutine

    move.b  #'0',0x00f00000
    move.b  #'9',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts

bus_subroutine:
    nop
    rts
