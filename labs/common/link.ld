OUTPUT_ARCH(m68k)
ENTRY(_start)

SECTIONS
{
    . = 0x000000;

    .vectors :
    {
        KEEP(*(.vectors))
    }

    . = 0x000100;

    .text :
    {
        *(.text.start)
        *(.text*)
        *(.rodata*)
    }

    . = ALIGN(2);

    .data :
    {
        *(.data*)
    }

    .bss 0x010000 (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    }

    /DISCARD/ :
    {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
    }
}
