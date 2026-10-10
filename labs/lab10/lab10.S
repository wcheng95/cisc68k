.global main

.section .text.lab10,"ax"

main:
    /*
     * Write a full 16-bit value to the peripheral register.
     */
    move.w  #0x1234,0x00f00020

    /*
     * Read it back through the same memory-mapped address.
     */
    move.w  0x00f00020,%d0
    cmpi.w  #0x1234,%d0
    bne.s   fail

    /*
     * Byte writes use the normal 68000 byte lanes.
     * Even byte address -> upper byte, odd byte address -> lower byte.
     */
    move.b  #0xab,0x00f00020
    move.b  #0xcd,0x00f00021

    move.w  0x00f00020,%d1
    cmpi.w  #0xabcd,%d1
    bne.s   fail

    move.b  #0x11,0x0100f0
    bra.s   done

fail:
    move.b  #0xee,0x0100f0

done:
    move.b  #'1',0x00f00000
    move.b  #'0',0x00f00000
    move.b  #10,0x00f00000

    moveq   #0,%d0
    rts
