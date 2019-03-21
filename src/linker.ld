ENTRY(_start)

SECTIONS {
    . = 1M;

    .text : 
    {
        *(.multiboot_header)
        *(.text*)
    }

    .data :
    {
        *(.data*)
    }

    .bss :
    {
        *(.bss*)
    }
}
