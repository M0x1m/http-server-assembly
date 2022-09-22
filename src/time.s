.text

.globl time
.globl asctime
.globl ascdate
.globl cpustr
.globl getloctime

ntohl:
	push %rbp
	mov %rsp, %rbp
	movb $0, -5(%rbp)
	mov $24, %cl
	xor %eax, %eax
	mov %edi, -4(%rbp)
	sub $5, %rsp
.ntohl:
	movzxb -5(%rbp), %rbx
	movzxb -4(%rbp, %rbx), %ebx
	shl %cl, %ebx
	or %ebx, %eax
	sub $8, %cl
	incb -5(%rbp)
	cmpb $4, -5(%rbp)
	jb .ntohl
	leave
	ret

getloctime:
	push %rbp
	mov %rsp, %rbp
	cmpl $~0, (loc)
	je .getloctime.0
	movslq (loc), %rax
	leave
	ret
.getloctime.0:
	sub $20, %rsp
	mov $Locf, %rdi
	xor %rsi, %rsi
	call buffopen
	mov %rax, -8(%rbp)
	lea -12(%rbp), %rdi
	mov %rax, %rsi
	mov $4, %rdx
	call buffread
	cmpl $1718180436, -12(%rbp) # Checking for 'TZif' format indentificator
	jne .getloctime.err
	mov -8(%rbp), %rdi
	mov $28, %rsi
	xor %rdx, %rdx
	call buffseek
	lea -20(%rbp), %rdi
	mov -8(%rbp), %rsi
	mov $4, %rdx
	call buffread
	mov -20(%rbp), %rdi
	call ntohl
	mov %eax, -20(%rbp)
	lea -12(%rbp), %rdi
	mov -8(%rbp), %rsi
	mov $4, %rdx
	call buffread
	mov -12(%rbp), %rdi
	call ntohl
	mov $5, %ebx
	xor %rdx, %rdx
	mul %ebx
	mov %eax, -16(%rbp)
	lea -12(%rbp), %rdi
	mov -8(%rbp), %rsi
	mov $4, %rdx
	call buffread
	mov -12(%rbp), %rdi
	call ntohl
	dec %eax
	mov $6, %ebx
	xor %rdx, %rdx
	mul %ebx
	movsxd %eax, %rsi
	movsxd -16(%rbp), %rax
	lea 44(%rsi, %rax), %rsi
	mov -8(%rbp), %rdi
	xor %rdx, %rdx
	call buffseek
	lea -12(%rbp), %rdi
	mov -8(%rbp), %rsi
	mov $4, %rdx
	call buffread
	mov -12(%rbp), %rdi
	call ntohl
	add -20(%rbp), %eax
	mov %eax, (loc)
.getloctime.ret:
	push %rax
	mov -8(%rbp), %rdi
	call buffclose
	pop %rax
	leave
	ret
.getloctime.err:
	mov $0, %rax
	jmp .getloctime.ret

time:
	xor %rdi, %rdi
	mov $201, %rax
	syscall
	push %rax
	call getloctime
	pop %rbx
	add %rbx, %rax
	ret

.equ DAY,  86400
.equ HOUR, 3600
.equ MIN,  60

cpustr:
# rdi - dest
# rsi - num
# rdx - max number of possible non-significant zeros
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %dl, -17(%rbp)
	movb $0, -18(%rbp)
	sub $18, %rsp
	mov -16(%rbp), %rdi
	call utostr
	mov %rax, %rsp
	mov %rax, %rdi
	call strlen
	mov %rdi, %rsi
	mov %rax, %rdx
	mov -8(%rbp), %rdi
	movzxb -17(%rbp), %rbx
	cmp %rax, %rbx
	jb .cpustr
	push %rdx
	push %rsi
	sub %rax, %rbx
	mov %rbx, %rdx
	mov $48, %sil
	call memset
	add %rdx, %rdi
	mov %dl, -18(%rbp)
	pop %rsi
	pop %rdx
.cpustr:
	call memcpy
	mov %rdx, %rax
	add -18(%rbp), %al
	mov -8(%rbp), %rdi
	leave
	ret

cdate:
# rdi - time
# ret rax - first 5 bits - day (1 - 31,30,28,29(depends on month and year))
#			next 4 bits  - month (1 - 12)
#			next 24 bits - year (0-...)
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movw $0, -10(%rbp)
	movl $0, -14(%rbp)
	sub $14, %rsp
.cdate:
	incb -9(%rbp)
	cmpb $1, -9(%rbp)
	je .cdate.0
	cmpb $12, -9(%rbp)
	je .cdate.0
	cmpb $8, -9(%rbp)
	je .cdate.0
	cmpb $7, -9(%rbp)
	je .cdate.0
	cmpb $5, -9(%rbp)
	je .cdate.0
	cmpb $3, -9(%rbp)
	je .cdate.0
	cmpb $10, -9(%rbp)
	je .cdate.0
	cmpb $2, -9(%rbp)
	je .cdate.3
	lea -8(%rbp), %rdi
	mov $30, %sil
	lea -10(%rbp), %rdx
	call cdm
	cmp $-1, %rax
	je .cdate.2
	jmp .cdate.1
.cdate.3:
	lea -8(%rbp), %rdi
	mov $28, %sil
	lea -10(%rbp), %rdx
	call cdm
	cmp $-1, %rax
	je .cdate.2
	mov -14(%rbp), %eax
	add $2, %eax
	mov $4, %ebx
	xor %edx, %edx
	div %ebx
	cmp $0, %edx
	jne .cdate.1
	lea -8(%rbp), %rdi
	mov $1, %sil
	lea -10(%rbp), %rdx
	call cdm
	cmp $-1, %rax
	je .cdate.2
	jmp .cdate.1
.cdate.0:
	lea -8(%rbp), %rdi
	mov $31, %sil
	lea -10(%rbp), %rdx
	call cdm
	cmp $-1, %rax
	je .cdate.2
	cmpb $12, -9(%rbp)
	jne .cdate.1
	movb $0, -9(%rbp)
	incl -14(%rbp)
.cdate.1:
	cmpq $0, -8(%rbp)
	jge .cdate
.cdate.2:
	movzxb -9(%rbp), %rax
	shl $5, %rax
	orb -10(%rbp), %al
	movl -14(%rbp), %ebx
	shl $9, %ebx
	or %ebx, %eax
	mov $0x1ffffffff, %rbx
	and %rbx, %rax
	leave
	ret

cdm:
# rdi - time ptr
# rsi - num of days
# rdx - days ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rdx, -16(%rbp)
	mov %sil, -17(%rbp)
.cdm:
	mov -8(%rbp), %rdi
	subq $DAY, (%rdi)
	mov -16(%rbp), %rsi
	incb (%rsi)
	cmpq $0, (%rdi)
	jl .cdm.0
	mov -17(%rbp), %dl
	cmp (%rsi), %dl
	jne .cdm
	mov $0, %rax
	mov -16(%rbp), %rsi
	movb $0, (%rsi)
	jmp .cdm.1
.cdm.0:
	mov $-1, %rax
.cdm.1:
	leave
	ret

ascdate:
# rdi - time
# rsi - str_ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movl $0, -12(%rbp)
	cmp $0, %rsi
	jne .ascdate
	movq $ascdate_buf, -28(%rbp)
	jmp .ascdate.0
.ascdate:
	mov %rsi, -28(%rbp)
.ascdate.0:
	sub $28, %rsp
	mov -8(%rbp), %rdi
	call cdate
	mov %rax, -20(%rbp)
	shr $9, %rax
	lea 1970(%rax), %rsi
	mov -28(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	add %eax, -12(%rbp)
	movsxd -12(%rbp), %rax
	movb $45, (%rdi, %rax)
	addl $1, -12(%rbp)
	mov -20(%rbp), %rsi
	shr $5, %rsi
	and $0xf, %rsi
	mov -28(%rbp), %rdi
	movsxd -12(%rbp), %rax
	lea (%rdi, %rax), %rdi
	mov $2, %dl
	call cpustr
	add %eax, -12(%rbp)
	movb $45, (%rdi, %rax)
	addl $1, -12(%rbp)
	mov -8(%rbp), %rdi
	mov $2, %dl
	mov -20(%rbp), %rsi
	and $0x1f, %rsi
	mov -28(%rbp), %rdi
	movsxd -12(%rbp), %rax
	lea (%rdi, %rax), %rdi
	call cpustr
	add %eax, -12(%rbp)
	movb $32, (%rdi, %rax)
	mov -28(%rbp), %rax
	leave
	ret

asctime:
# rdi - time
# rsi - dest_str_ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movl $0, -12(%rbp)
	cmp $0, %rsi
	je .asctime
	mov %rsi, -20(%rbp)
	jmp .asctime.0
.asctime:
	movq $asctime_buf, -20(%rbp)
.asctime.0:
	sub $20, %rsp
	mov -8(%rbp), %rax
	mov $HOUR, %rbx
	xor %rdx, %rdx
	div %rbx
	mov $24, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rdx, %rsi
	mov -20(%rbp), %rdi
	movsxd -12(%rbp), %rax
	lea (%rdi, %rax), %rdi
	mov $2, %dl
	call cpustr
	add %eax, -12(%rbp)
	movb $58, (%rdi, %rax)
	addl $1, -12(%rbp)
	mov -8(%rbp), %rax
	mov $MIN, %rbx
	xor %rdx, %rdx
	div %rbx
	mov $60, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rdx, %rsi
	mov -20(%rbp), %rdi
	movsxd -12(%rbp), %rax
	lea (%rdi, %rax), %rdi
	mov $2, %dl
	call cpustr
	add %eax, -12(%rbp)
	movb $58, (%rdi, %rax)
	addl $1, -12(%rbp)
	mov -8(%rbp), %rax
	mov $60, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rdx, %rsi
	mov -20(%rbp), %rdi
	movsxd -12(%rbp), %rax
	lea (%rdi, %rax), %rdi
	mov $2, %dl
	call cpustr
	mov -20(%rbp), %rax
	leave
	ret

.bss
	.comm asctime_buf, 64
	.comm ascdate_buf, 64

.data
	Locf: .asciz "/etc/localtime"
	loc: .long ~0
