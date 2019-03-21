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
	.data
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


###
# The multiboot entry point
###
	.text
	.globl _start
.code32
_start:
	cli
	cld
	movl $_mini_stack, %esp
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
	.ascii "\nNo, huge page support. halting..\n\0"
1:
	/* Make pml4 point to pdp */
	movl $_boot_pml4, %ebx
	movl $_boot_pdp, %eax
	orl $0x3, %eax              /* Present and RW */
	movl %eax, 0(%ebx)
	xorl %eax, %eax
	movl %eax, 4(%ebx)
	/* Put an indentity-mapping pdp entry */
	movl $_boot_pdp, %ebx
	movl $0x83, %eax            /* Present, RW, and Page Size */
	movl %eax, 0(%ebx)
	xorl %eax, %eax
	movl %eax, 4(%ebx)
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

_puts_serial:
	movl $0x3f8, %edx
	movl %eax, %ebx
1:
	movb (%ebx), %al
	testb %al, %al
	jz 2f
	outb %al, %dx
	incl %ebx
	jmp 1b
2:
	ret

_putc_serial:
	movl $0x3f8, %edx
	outb %al, %dx
	ret


###
# Long mode entry point
###
	.text
	.globl rust_start
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
	jmp rust_start
	hlt


###
# Paging Structures
###
	.globl _boot_pml4
.comm _boot_pml4, 4096, 4096
	.globl _boot_pdp
.comm _boot_pdp, 4096, 4096
	.globl _boot_pd
.comm _boot_pd, 4096, 4096


###
# Stack
###
	.data
	.space	1024
_mini_stack:
