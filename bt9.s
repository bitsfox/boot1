.code16
.data
.text
	jmp $0x7c0,$go
go:
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%es
	lss stk,%sp
	mov $0x200,%bx
	mov $0,%dx
	mov $2,%cx
	mov $0x0208,%ax
	int $0x13
	jnc 1f
	jmp .
1:
	call cls
	nop
	call disp_1
	lgdt l_gdt
	cli
	mov $1,%ax
	lmsw %ax
	jmp $8,$0

//{{{disp_1
disp_1:
	lea msg,%ax
	mov %ax,%bp
	mov $4,%dx
	mov $len,%cx
	mov $0x0c,%bx
	mov $0x1301,%ax
	int $0x10
	ret
//}}}
//{{{cls
cls:
	push %es
	mov $0xb800,%ax
	mov %ax,%es
	mov $0x7d0,%cx
	mov $0x20,%ax
	mov $0,%di
	rep stosw
	pop %es
	ret
//}}}

stk:	.word	0x200,0x2000,0
msg:	.ascii "booting...............................................[ok]"
len=.-msg
l_gdt:
		.word	56
		.word	0x7c00+gdt,0
gdt:
		.word	0,0,0,0
		.word	2,0x7e00,0x9a00,0x00c0			#8		text
		.word	2,0x7e00,0x9200,0x00c0			#0x10	data
		.word	2,0xf000,0x9204,0x00c0			#0x18	stack
		.word	10,0x000,0x9220,0x00c0			#0x20	new gdt/idt
		.word	4,0x0000,0x9210,0x00c0			#0x28	new interrupt process
		.word	0,0,0,0

.org	510
.word	0xaa55

