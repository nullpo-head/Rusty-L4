ENTRY(_start)

SECTIONS {
    . = 1M;

    .text : 
    {
        *(.multiboot_header)
        *(.text)
        *(.text*)
    }

    .data :
    {
        *(.data)
        *(.data*)
    }

    .bss :
    {
        *(.bss)
        *(.bss*)
    }
}
