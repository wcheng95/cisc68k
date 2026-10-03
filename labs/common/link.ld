OUTPUT_ARCH(m68k)             /* [LD][OPT] ELF architecture metadata */
ENTRY(_start)                 /* [LD][OPT] ELF entry; reset PC comes from vector */

SECTIONS
{
    /* [68K][NOW] reset vectors must begin at address 0 */
    . = 0x000000;

    .vectors :
    {
        KEEP(*(.vectors))     /* keep reset vectors even with --gc-sections */
    }

    /* [CONV][NOW] place startup/program code at an easy-to-see address */
    . = 0x000100;

    .text :
    {
        *(.text.start)        /* startup first */
        *(.text*)             /* program code */
        *(.rodata*)           /* read-only constants */
    }

    /* [68K][NOW] word/longword data must begin on even addresses */
    . = ALIGN(2);

    /* [LATER] initialized writable data; startup does not copy it yet */
    .data :
    {
        *(.data*)
    }

    /* [LATER] zero-initialized data in RAM; startup does not clear it yet */
    .bss 0x010000 (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    }

    /* [OPT] metadata not needed by these bare-metal labs */
    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
    }
}
