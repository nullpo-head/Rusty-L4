
	.globl _start

.code32
_start:
	cli
	cld
	movb $'B', %al
	movl $0x3f8, %edx
	outb %al, %dx
	hlt

	.align  16
_mb_header:
	.long   0x1BADB002			/* magic */
	.long   0x00000000			/* flags */
	.long   - 0x00000000 - 0x1BADB002	/* check */
