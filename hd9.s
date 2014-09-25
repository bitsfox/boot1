.data
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	lss  stk,%esp
	call setup_8253
	nop
	call move_int
	nop
	call setup_idt
	nop
	call setup_task0
	nop
	call setup_gdt
	nop
	lidt l_idt
	lgdt l_gdt
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	lss	 stk,%esp
	call disp_1
	nop
	movl $0x40,%eax
	ltr %ax
	movl $0x48,%eax
	lldt %ax
	sti
	call setup_pdt
#	xorl %eax,%eax
	movl $0x0010a000,%eax
	movl %eax,%cr3
	movl %cr0,%eax
	orl  $0x80000000,%eax
	movl %eax,%cr0
	jmp .+2
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	lss stk,%esp
	nop
	pushfl
	andl $0xffffbfff,(%esp)
	popfl
	pushl $0x1f
	pushl $0x200
	pushfl
	pushl $0xf
	pushl $task0
	iret
	jmp .

//{{{setup_8253
setup_8253:
	pushl %eax
	pushl %edx
	movl $0x36,%eax
	movl $0x43,%edx
	outb %al,%dx
	movl $11930,%eax
	movl $0x40,%edx
	outb %al,%dx
	xchgb %al,%ah
	outb %al,%dx
	popl %edx
	popl %eax
	ret
//}}}
//{{{nor_int
nor_int:
	pusha
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $0,%edi
	movl $0x0a41,%eax
	stosw
	pop %es
	popa
	iret
nor_len=.-nor_int	
//}}}
//{{{time_int
time_int:
	pushl %eax
	movl $0x20,%eax
	outb %al,$0x20
	movl count,%eax
	cmpl $1000,%eax
	ja	 1f
	incl %eax
	jmp 2f
1:
	movl $0,%eax
2:
	movl %eax,count
	popl %eax
	iret
time_len=.-time_int	
//}}}
//{{{sys_int
sys_int:
	pusha

	popa
	iret
sys_len=.-sys_int	
//}}}
//{{{move_int
move_int:
	push %ds
	push %es
	movl $0x10,%eax
	movw %ax,%ds
	movl $0x28,%eax
	movw %ax,%es
	leal nor_int,%esi
	movl %esi,%edi
	movl $nor_len,%ecx
	rep movsb				#move done nor_int
	leal sys_int,%esi
	movl %esi,%edi
	movl $sys_len,%ecx
	rep movsb				#move done sys_int
	leal time_int,%esi
	movl %esi,%edi
	movl $time_len,%ecx
	rep movsb				#move done time_int
	pop %es
	pop %ds
	ret
//}}}
//{{{setup_idt
setup_idt:
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $nor_int,%edx
	movl $0x00380000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx				# interrupt gate
	movl $0,%edi
	movl $256,%ecx
1:
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	addl $8,%edi
	loop 1b
	movl $0x400,%edi
	movl $sys_int,%edx
	movl $0x00380000,%eax
	movw %dx,%ax
	movw $0xef00,%dx				#trap gate
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	movl $64,%edi
	movl $time_int,%edx
	movl $0x00380000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	pop %es
	ret
//}}}	
//{{{setup_task0
setup_task0:
	push %ds
	push %es
	movl $0x10,%eax
	movw %ax,%ds
	movl $0x20,%eax
	movw %ax,%es
	movl $0x1000,%edi
	leal tss0,%esi
	movl $104,%ecx
	rep movsb
	leal ldt0,%esi
	movl $0x2000,%edi
	movl $48,%ecx
	rep movsb
	pop %es
	pop %ds
	ret
//}}}
//{{{setup_gdt
setup_gdt:
	push %ds
	push %es
	movl $0x10,%eax
	movw %ax,%ds
	movl $0x20,%eax
	movw %ax,%es
	movl $0xa00,%edi
	leal tgdt,%esi
	xorl %ecx,%ecx
	movw $l_gdt,%cx
	rep movsb
	pop %es
	pop %ds
	ret
//}}}
//{{{disp_1
disp_1:
	push %es
	movl $0x20,%eax
	movw %ax,%es
	leal msg,%esi
	movl $len,%ecx
	movl $168,%edi
	movl $0x0c00,%eax
1:
	lodsb
	stosw
	loop 1b
	pop %es
	ret
//}}}
//{{{task0
task0:
	movl $0x17,%eax
	movw %ax,%ds
	movw %ax,%fs
	movl $0x27,%eax
	movw %ax,%es
	movl $480,%edi
	movl $0x0a41,%ebx
1:
	movl count,%eax
	cmpl $0,%eax
	jne  1b
	incl %eax
	movl %eax,count
	movl $0x20,%eax
	stosw
	cmpl $640,%edi
	jb	 2f
	movl $480,%edi
2:
	cmpb $'Z,%bl
	jae  3f
	incl %ebx
	jmp  4f
3:
	movl $0x0a41,%ebx
4:
	movw %bx,%es:(%edi)
	jmp 1b
	ret
//}}}
//{{{setup_pdt
setup_pdt:
	push %es
	movl $0x30,%eax
	movw %ax,%es
	movl $0x1007,%eax
	addl $0x0010a000,%eax
	movl $0,%edi
	stosl
	movl $1023,%ecx
	xorl %eax,%eax
	rep stosl
	movl $7,%eax
	movl $1024,%ecx
1:
	stosl
	addl $0x1000,%eax
	loop 1b
	pop %es
	ret
//}}}

stk:
	.long	0x200,0x18
l_idt:
	.word	0x800
	.long	0x00200000
l_gdt:
	.word	88
	.long	0x00200a00
tgdt:	
	.word	0,0,0,0
	.word	2,0x7e00,0x9a00,0x00c0			#8			text
	.word	2,0x7e00,0x9200,0x00c0			#x010		data
	.word	2,0xf000,0x9204,0x00c0			#0x18		stack
	.word	4,0x8000,0x920b,0x00c0			#0x20		disp
	.word	2,0xe000,0x9204,0x00c0			#0x28		task0's sys stack
	.word	4,0xa000,0x9210,0x00c0			#0x30		pdt/pt
	.word	4,0x0000,0x9a10,0x00c0			#0x38		new interrupt process
	.word	104,0x1000,0xe920,0				#0x40		tss0
	.word	48,0x2000,0xe220,0				#x048		ldt0
	.word	0,0,0,0
tss0:
	.long	0,0x200,0x28
	.space	92,0
ldt0:
	.word	0,0,0,0
	.word	2,0x7e00,0xfa00,0x00c0			#0xf		text
	.word	2,0x7e00,0xf200,0x00c0			#0x17		data
	.word	2,0xd000,0xf204,0x00c0			#0x1f		stack
	.word	4,0x8000,0xf20b,0x00c0			#0x27		disp
	.word	0,0,0,0

count:	.long 0
msg:	.ascii "heading...............................................[ok]"
len=.-msg

.org	4092
.ascii	"ttyy"

