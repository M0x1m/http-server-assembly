.text

# struct types {
#   uint32_t typsnum;    // Number of types in structure
#   struct type typs[typsnum];
# };

# Single type structure
# struct type {
#   char typ[];          // NULL-terminated string of type
#   uint16_t extnn;      // Number of extensions for this type
#   char extns[extnn][]; // NULL-terminated strings of extensions for the type above
# };

.ifndef _procret
_procret:
	leave
	ret
.endif

.globl loadmtypes
.globl findtype
.globl getext

getext:
# rdi - file name
# ret rax - ext str
	push %rdi
	call strlen
	mov %rax, %rcx
	lea -1(%rdi, %rax), %rdi
.getext.0:
	cmp %rdi, (%rsp)
	ja .getext.2
	dec %rdi
	cmpb $46, (%rdi)
	je .getext.1
	cmpb $47, (%rdi)
	je .getext.2
	loop .getext.0
	jmp .getext.2
.getext.1:
	lea 1(%rdi), %rax
	pop %rdi
	ret
.getext.2:
	pop %rdi
	xor %rax, %rax
	ret

findtype:
# rdi - extension str
# rsi - loaded types struct ptr
# ret rax - ptr to type str
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	sub $20, %rsp
	mov (%rsi), %eax
	mov %eax, -20(%rbp)
.findtype.0:
	mov -20(%rbp), %esi
	dec %esi
	mov -16(%rbp), %rdi
	call movtoidx
	cmp $0, %rax
	jle _procret
	push %rax
	mov %rax, %rdi
	call strlen
	lea 1(%rdi, %rax), %rdi
	movzxw (%rdi), %rcx
	add $2, %rdi
.findtype.1:
	push %rcx
	mov -8(%rbp), %rsi
	call streq
	cmp $1, %al
	je .findtype.f
	call strlen
	lea 1(%rdi, %rax), %rdi
	pop %rcx
	loop .findtype.1
	pop %rdi
	decl -20(%rbp)
	cmpl $0, -20(%rbp)
	ja .findtype.0
	xor %rax, %rax
	jmp _procret
.findtype.f:
	mov 8(%rsp), %rax
	jmp _procret

movtoidx:
# Returns the pointer to indexed type in array
# rdi - types struct ptr
# esi - idx
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %esi, -12(%rbp)
	sub $12, %rsp
	cmp %esi, (%rdi)
	jbe .movtoidx.er
	cmp $0, %esi
	je .movtoidx.2
	addq $4, -8(%rbp)
.movtoidx.0:
	mov -8(%rbp), %rdi
	call strlen
	lea 1(%rdi, %rax), %rdi
	movzxw (%rdi), %rcx
	add $2, %rdi
.movtoidx.1:
	call strlen
	lea 1(%rdi, %rax), %rdi
	loop .movtoidx.1
	mov %rdi, -8(%rbp)
	decl -12(%rbp)
	cmpl $0, -12(%rbp)
	ja .movtoidx.0
	mov -8(%rbp), %rax
	jmp _procret
.movtoidx.er:
	mov $-1, %rax
	jmp _procret
.movtoidx.2:
	lea 4(%rdi), %rax
	jmp _procret

loadmtypes:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $16, %rsp
	xor %rsi, %rsi
	call buffopen
	cmp $0, %rax
	jle _procret
	mov %rax, -16(%rbp)
	sub $8, %rsp
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	cmp $0, %rax
	jle _procret
	mov %rax, -24(%rbp)
	sub $48, %rsp
	movq $1, -32(%rbp)
	movq $0, -40(%rbp)
	movq $65536, -48(%rbp)
.loadmtypes.0:
	mov -16(%rbp), %rdi
	lea -32(%rbp), %rsi
	call skip_sts
	cmp $0, %rax
	jl .loadmtypes.ret
	mov -32(%rbp), %rax
	mov %rax, -56(%rbp)
	mov %rsp, -64(%rbp)
	mov -16(%rbp), %rdi
	lea -32(%rbp), %rsi
	call getval
	cmp $0, %rax
	jl .loadmtypes.ret
	mov %rax, %rsp
	mov -16(%rbp), %rdi
	lea -32(%rbp), %rsi
	call skip_sts
	cmp $0, %rax
	jl .loadmtypes.ret
	lea -32(%rbp), %rdi
	lea -56(%rbp), %rsi
	cmpsq
	jne .loadmtypes.noext
	jmp .loadmtypes.1
.loadmtypes.notyp:
	mov -8(%rbp), %rdi
	call .perror.print
	mov $ERR_notyps, %rdi
	call .perror.fprint
	mov -24(%rbp), %rax
	jmp _procret
.loadmtypes.noext:
	mov -8(%rbp), %rdi
	call .perror.print
	mov (stderr), %rdi
	mov $58, %sil
	call bputc
	mov -56(%rbp), %rsi
	call bsndustr
	mov $ERR_noexts, %rdi
	call .perror.print
	mov %rsp, %rdi
	call .perror.print
	mov (stderr), %rdi
	mov $ERR_noexts, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	jmp .loadmtypes.0
.loadmtypes.1:
	mov -24(%rbp), %rdi
	incl (%rdi)
	mov -40(%rbp), %rax
	lea 4(%rdi, %rax), %rdi
	push %rdi
	lea 8(%rsp), %rdi
	call strlen
	lea 1(%rax), %rdx
	mov %rdi, %rsi
	push %rsi
	lea -24(%rbp), %rdi
	lea 8(%rsp), %rsi
	lea 1(%rax), %r10
	push %rdx
	lea -48(%rbp), %rdx
	call _chkappend
	pop %rdx
	pop %rsi
	pop %rdi
	call memcpy
	add %rdx, -40(%rbp)
	mov -64(%rbp), %rsp
	sub $10, %rsp
	movw $0, -66(%rbp)
	movq $0, -74(%rbp)
.loadmtypes.2:
	mov -16(%rbp), %rdi
	lea -32(%rbp), %rsi
	call skip_sts
	cmp $0, %rax
	jl .loadmtypes.ret
	lea -32(%rbp), %rdi
	lea -56(%rbp), %rsi
	cmpsq
	je .loadmtypes.4
	lea -66(%rbp), %rsi
	mov -24(%rbp), %rdi
	mov -40(%rbp), %rax
	lea 4(%rdi, %rax), %rdi
	movsw
	mov -74(%rbp), %rax
	add $2, %rax
	add %rax, -40(%rbp)
	add $10, %rsp
	jmp .loadmtypes.0
.loadmtypes.4:
	mov -16(%rbp), %rdi
	lea -32(%rbp), %rsi
	call getval
	cmp $0, %rax
	jl .loadmtypes.ret
	mov %rsp, -64(%rbp)
	mov %rax, %rsp
	mov %rsp, %rdi
	call strlen
	lea 1(%rax), %rdx
	push %rdx
	lea 2(%rdx), %r10
	lea -24(%rbp), %rdi
	mov (%rdi), %rsi
	mov -40(%rbp), %rax
	add -74(%rbp), %rax
	lea 6(%rsi, %rax), %rsi
	push %rsi
	mov %rsp, %rsi
	lea -48(%rbp), %rdx
	call _chkappend
	add $8, %rsp
	pop %rdx
	mov %rsp, %rsi
	mov -24(%rbp), %rdi
	mov -40(%rbp), %rax
	add -74(%rbp), %rax
	lea 6(%rdi, %rax), %rdi
	call memcpy
	mov -64(%rbp), %rsp
	add %rdx, -74(%rbp)
	incw -66(%rbp)
	jmp .loadmtypes.2
.loadmtypes.ret:
	mov -16(%rbp), %rdi
	call buffclose
	mov -24(%rbp), %rax
	cmpl $0, (%rax)
	je .loadmtypes.notyp
	jmp _procret

.data
ERR_noexts: .asciz ": Extensions for the type `\0' are not provided.\n"
ERR_notyps: .asciz ": File has no any types.\n"
