	.section .multiboot_header, "ax" # "ax" to prevent lld from mapping failure
	.balign 16
_mb_header:
	.long 0xe85250d6			/* magic */
	.long 0x00000000			/* flags */
	.long _mb_header_end - _mb_header	/* header length */
	.long 0x100000000 - (0xe85250d6 + 0 + (_mb_header_end - _mb_header))
	.word 0x0
	.word 0x0
	.long 0x8
_mb_header_end:


###
# GDT
###
	.section .data.init
	.align 4096
_boot_gdt:
	.set _boot_gdt_null, . - _boot_gdt
    /* null */
	.short 0xffff               /* Limit (low) */
	.short 0x0000               /* Base (low) */
	.byte  0x00                 /* Base (middle) */
	.byte  0x00                 /* Access */
	.byte  0x01                 /* Granularity */
	.byte  0x00                 /* Base (high) */
    /* code */
	.set _boot_gdt_code, . - _boot_gdt
	.short 0x0000               /* Limit (low) */
	.short 0x0000               /* Base (low) */
	.byte  0x00                 /* Base (middle) */
	.byte  0b10011010           /* Access; E/R */
	.byte  0b10101111           /* Granularity; 64 bits flag, limit19:16 */
	.byte  0x00                 /* Base (high) */
    /* data */
	.set _boot_gdt_data, . - _boot_gdt
	.short 0x0000               /* Limit (low) */
	.short 0x0000               /* Base (low) */
	.byte  0x00                 /* Base (middle) */
	.byte  0b10010010           /* Access; R/W */
	.byte  0x00                 /* Granularity */
	.byte  0x00                 /* Base (high) */
	.quad 0
_boot_gdtr:
	.word . - _boot_gdt - 1
	.quad _boot_gdt


#define KERNEL_BASE 0xffffffffc0000000ULL
#define PT_INDEX(addr, level) ((addr >> (12 + (level - 1) * 9)) & ((1 << 9) - 1))

###
# The multiboot entry point
###
	.section .text.init
	.globl _start
.code32
_start:
	cli
	cld
	movl $_mini_stack, %esp
	call _init_serial
	movl %ebx, %edi             /* to be passed to Rust's main; Multiboot info  */
# Debug
	movb $'A', %al
	call _putc_serial
# Setting up the initial paging
	/* Set PAE */
	movl %cr4, %eax
	orl $1 << 5, %eax            /* PAE */
	movl %eax, %cr4
	movl $0x80000001, %eax       /* implicit argument for cpuid */
	cpuid
	andl $1 << 26, %edx          /* Test if it supports giga byte page */
	jnz 1f
	movl $_nohugepage_msg, %eax
	call _puts_serial
	hlt
	_nohugepage_msg:
	.ascii "\nNo huge page support. halting..\n\0"
1:
	/* Make huge-page pdp entreis */
	movl $_boot_pdp, %ebx
	xorl %ecx, %ecx
	movl $0x83, %eax            /* Present, RW, and Page Size */
	/*   - the 0th entry to map [0, 1G) to [0, 1G) */
	movl %eax, 0(%ebx)
	movl %ecx, 4(%ebx)
	/*   - the 511th entry to map [0xffff_ffff_c000_0000, +1G) to [0, 1G) */
	movl %eax, 8*PT_INDEX(KERNEL_BASE,3)(%ebx)
	movl %ecx, 4+8*PT_INDEX(KERNEL_BASE,3)(%ebx)
	/* Make pml4 entries. */
	movl $_boot_pml4, %ebx
	movl $_boot_pdp, %eax
	orl $0x3, %eax              /* Present and RW */
	xorl %ecx, %ecx
	/*   - Let the 0th entry point to the pdpe to map [0, 1G) to [0, 1G) */
	movl %eax, 0(%ebx)
	movl %ecx, 4(%ebx)
	/*   - Let the 511th entry point to the pdpe to map [0xffff_ffff_c000_0000, +1G) to [0, 1G) */
	movl %eax, 8*PT_INDEX(KERNEL_BASE,4)(%ebx)
	movl %ecx, 4+8*PT_INDEX(KERNEL_BASE,4)(%ebx)
	/* Set them to cr3 */
	movl $_boot_pml4, %eax
	movl %eax, %cr3
# Debug
	movb $'B', %al
	call _putc_serial
# Enter Long mode
	movl $0xc0000080, %ecx  /* EFER MSR */
	rdmsr
	orl $1 << 8, %eax       /* Set LME */
	wrmsr
	movl %cr0, %eax
	orl $1 << 31, %eax      /* Enable paging */
	movl %eax, %cr0
# Debug
	movb $'C', %al
	call _putc_serial
# Load GDT
	movl $_boot_gdtr, %eax
	lgdt (%eax)
    # Debug
	movb $'D', %al
	call _putc_serial
	ljmp $_boot_gdt_code, $_jump_to_rust
	hlt

_init_serial:
    /* wrt xv6 */
	/* Turn off the FIFO */
	movl $(0x3f8 + 2), %edx
	movb $0, %al
	outb %al, %dx
	/* Configuration; 9600, 8 data bits, 1 stop bits, parity off */
	movl $(0x3f8 + 3), %edx
	movb $0x80, %al
	outb %al, %dx
	movl $(0x3f8 + 0), %edx
	movb $(11520/9600), %al
	outb %al, %dx
	movl $(0x3f8 + 1), %edx
	movb $0, %al
	outb %al, %dx
	movl $(0x3f8 + 3), %edx
	movb $0x03, %al
	outb %al, %dx
	movl $(0x3f8 + 4), %edx
	movb $0, %al
	outb %al, %dx
	movl $(0x3f8 + 1), %edx
	movb $0x01, %al
	outb %al, %dx
	movl $_init_serial_msg, %eax
	call _puts_serial
	ret
	_init_serial_msg:
	.ascii "serial initialization done\n\0"


_puts_serial:
	movl %eax, %ebx
1:
	movb (%ebx), %al
	testb %al, %al
	jz 2f
	call _putc_serial
	incl %ebx
	jmp 1b
2:
	ret

_putc_serial:
	movl %eax, %ecx
	movl $(0x3f8 + 5), %edx
1:
	inb %dx, %al
	testb $0x20, %al
	jnz 2f
	nop
	jmp 1b
2:
	movl %ecx, %eax
	movl $0x3f8, %edx
	outb %al, %dx
	ret


###
# Long mode entry point
###
	.section .text.init
	.globl _jmp_to_rust
.code64
_jump_to_rust:
	cli
	cld
# Debug
	movb $'E', %al
	call _putc_serial
# Set data segment
	movw $_boot_gdt_data, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs
	movw %ax, %ss
	movq %rdi, %r8                        /* Save Multiboot info */
# Fill the screen with blue
	movl $0xB8000, %edi
	movq $0x1F201F201F201F20, %rax
	movl $500, %ecx
	rep stosq
# Debug
	movb $'F', %al
	call _putc_serial
	movb $'\n', %al
	call _putc_serial
	movq %r8, %rdi                        /* Restore Multiboot info */
	movabsq $rust_start, %rax
	jmpq *%rax
	hlt



###
# Stack
###
	.section .data.init
	.space	1 << 21
_mini_stack:

###
# Paging Structures
###
	.align 4096
	.globl _boot_pml4
_boot_pml4:
# .space _boot_pml4, 4096, 4096
	.space 4096, 0
	.globl _boot_pdp
#.comm _boot_pdp, 4096, 4096
_boot_pdp:
	.space 4096, 0
	.globl _boot_pd
_boot_pd:
	.space 4096, 0