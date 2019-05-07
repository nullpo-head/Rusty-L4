ENTRY(_start)

KERNEL_OFFSET = 0xFFFFFFFFC0000000;

_start_text = 1M + KERNEL_OFFSET;

SECTIONS {
    . = 1M;

    .text.init :
    {
        *(.multiboot_header)
        *(.text.init)
    }

    .data.init :
    {
        *(.data.init)
    }

    .bss.init :
    {
        startup(.bss*)
    }

    . = ALIGN(0x1000);
    . = . + KERNEL_OFFSET;

    .text : AT (ADDR(.text) - KERNEL_OFFSET)
    {
        *(.text*)
    }

    .rodata : AT(ADDR(.rodata) - KERNEL_OFFSET)
    {
        *(.rodata*)
    }

    .got : AT(ADDR(.got) - KERNEL_OFFSET)
    {
        *(.got*)
    }

    .data : AT(ADDR(.data) - KERNEL_OFFSET)
    {
        *(.data*)
    }

    .bss : AT(ADDR(.bss) - KERNEL_OFFSET)
    {
        *(.bss*)
    }

}
