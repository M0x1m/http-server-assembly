.global _start
.global memcpy
.global getstrbyidx
.global strlen
.global strlenbyidx
.global skip_sts
.global stderr
.global .perror.print
.global .perror.fprint
.global bputc
.global streq
.global bsndustr
.global getval
.global fls
.global bsndstrbyidx
.global min
.global memmovp

.text
strlen:
	xor %rax, %rax
.strlen.0:
	cmpb $0, (%rdi, %rax)
	ja .strlen.1
	ret
.strlen.1:
	inc %rax
	jmp .strlen.0

new_thr:
	push %rbp
	mov %rsp, %rbp
	push %rdi
	push %rsi

	mov $9, %rax
	xor %rdi, %rdi
	mov $65536, %rsi			# THREAD STACK SIZE declared here
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	syscall

	pop 65536-8(%rax)
	pop 65536-16(%rax)

	lea 65536-16(%rax), %rax
	mov %rax, -8(%rbp)

	mov $56, %rax
	mov $0x00010f00, %rdi
	mov -8(%rbp), %rsi
	xor %rdx, %rdx
	xor %r10, %r10
	xor %r8, %r8
	syscall

	cmp $0, %rax
	je .new_thr.0

	pop %rbp
	ret
.new_thr.0:
	pop %rax
	jmp *%rax

strtou:
	push %rbp
	mov %rsp, %rbp
	sub $8, %rsp
	xor %rax, %rax
	cmp $0, %rsi
	jle .strtou.0
	mov %rsi, -8(%rbp)
	jne .strtou.1
.strtou.0:
	call strlen
	mov %rax, %rsi
	mov %rax, -8(%rbp)
	xor %rax, %rax
.strtou.1:
	cmp $0, %rsi
	ja .strtou.2
	jmp .strtou.3
.strtou.2:
	cmpb $0x30, -1(%rdi, %rsi)
	jb .strtou.3
	cmpb $0x39, -1(%rdi, %rsi)
	ja .strtou.3
	movzxb -1(%rdi, %rsi), %rbx
	sub $0x30, %bl
	push %rax
	mov -8(%rbp), %cx
	sub %si, %cx
	inc %cx
.strtou.4:
	cmp $0, %cx
	dec %cx
	ja .strtou.5
	pop %rax
	add %rbx, %rax
	dec %rsi
	jmp .strtou.1
.strtou.5:
	mov %rbx, %rax
	mov $10, %rbx
	xor %rdx, %rdx
	mul %rbx
	mov %rax, %rbx
	jmp .strtou.4
.strtou.3:
	mov -8(%rbp), %rsi
	leave
	ret

htons:
	mov %di, %ax
	shr $8, %ax
	shl $8, %di
	or %di, %ax
	ret

ulen:
	mov $1, %rax
	push %rdi
.ulen.0:
	cmp $9, %rdi
	ja .ulen.1
	jmp .ulen.2
.ulen.1:
	push %rax
	mov %rdi, %rax
	mov $10, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rax, %rdi
	pop %rax
	inc %rax
	jmp .ulen.0
.ulen.2:
	pop %rdi
	ret

isdigit:
# dil - char
	cmp $0x30, %dil
	jb .isdigit.n
	cmp $0x39, %dil
	ja .isdigit.n
	mov $1, %rax
	ret
.isdigit.n:
	xor %rax, %rax
	ret

strulen:
# Returns number of digits in number in string
# rdi - string
# ret rax - number of digits in the number
	push %rdi
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movq $0, -16(%rbp)
	sub $16, %rsp
	jmp .strulen.0
.strulen.1:
	incq -16(%rbp)
	incq -8(%rbp)
.strulen.0:
	mov -8(%rbp), %rdi
	mov (%rdi), %dil
	call isdigit
	cmp $1, %al
	je .strulen.1
	mov -16(%rbp), %rax
	leave
	pop %rdi
	ret

utostr:
	push %rbp
	mov %rsp, %rbp
	sub $48, %rsp
	call ulen
	cmp $48, %rax
	jae .utostr.ovflw
	movl %eax, -8(%rbp)
	movl %eax, -4(%rbp)
.utostr.0:
	cmpl $0, -4(%rbp)
	ja .utostr.1
	jmp .utostr.2
.utostr.1:
	mov %rdi, %rax
	mov $10, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rax, %rdi
	add $0x30, %rdx
	movl -4(%rbp), %ecx
	subl -8(%rbp), %ecx
	negl %ecx
	neg %rcx
	movb %dl, -10(%rbp, %rcx)
	decl -4(%rbp)
	jmp .utostr.0
.utostr.2:
	movb $0, -9(%rbp)
	movl -8(%rbp), %ecx
	neg %rcx
	lea -9(%rbp, %rcx), %rax
.utostr.ovflw:
	leave
	ret

memcpy:
	mov %rdx, %rcx
	mov %rdi, %rax
	rep movsb
	mov %rax, %rdi
	ret

strslen: # computes NULL-terminated strings's length
# rdi - pointer to NULL-terminated strings; rsi - number of NULL-terminated strings
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movq $0, -16(%rbp)
	sub $16, %rsp
.strslen.0:
	cmp $0, %rsi
	ja .strslen.1
	mov -16(%rbp), %rax
	leave
	ret
.strslen.1:
	dec %rsi
	mov -8(%rbp), %rdi
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	add %rax, -16(%rbp)
	jmp .strslen.0

getcpath:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movb $0, -9(%rbp)
	movl $0, -13(%rbp)
	sub $23, %rsp
.getcpath.1:
	mov -8(%rbp), %rdi
	mov (timeout), %rsi
	call sbuffgetc
	cmp $-1, %rax
	jle .getcpath.fret
	cmpb $0x20, %al
	je .getcpath.ret
	incl -13(%rbp)
	movsxd -13(%rbp), %rbx
	neg %rbx
	mov %al, (%rsp) 
	dec %rsp
	jmp .getcpath.1
.getcpath.ret:
	mov %rsp, %rdi
	movsxd -13(%rbp), %rsi
	movb $0, (%rdi, %rsi)
	dec %rsi
	call memrev
	call unhexhttp
	mov $0x2F, %sil
	call skip_delim
.getcpath.fret:
	leave
	ret

unhexhttp:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movq $0, -16(%rbp)
	sub $16, %rsp
.unhexhttp.0:
	mov -8(%rbp), %rdi
	mov -16(%rbp), %rcx
	cmpb $0, (%rdi, %rcx)
	je .unhexhttp.1 
	cmpb $37, (%rdi, %rcx)
	jne .unhexhttp.2
	lea 1(%rdi, %rcx), %rdi
	call strlen
	cmp $2, %rax
	jb .unhexhttp.1
	call unhexdctob
	mov -16(%rbp), %rcx
	mov -8(%rbp), %rdi
	cmp $0, %rax
	jl .unhexhttp.2
	mov %al, (%rdi, %rcx)
	lea 3(%rdi, %rcx), %rdi
	call strlen
	mov %rax, %rdx
	mov $-2, %rsi
	call memmov
.unhexhttp.2:
	incq -16(%rbp)
	jmp .unhexhttp.0
.unhexhttp.1:
	mov -8(%rbp), %rax
	mov %rax, %rdi
	leave
	ret

memmovp:
# rdi - ptr
# rsi - new ptr
# rdx - size
	sub %rdi, %rsi
	call memmov
	add %rdi, %rsi
	ret

memmov:
# rdi - ptr
# rsi - offt
# rdx - size
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	sub $24, %rsp
	cmp $0, %rsi
	jl .memmov.0
	std
	add %rdx, %rdi
.memmov.0:
	mov %rdi, %rsi
	add -16(%rbp), %rdi
	mov -24(%rbp), %rcx
	inc %rcx
	rep movsb
	cld
	mov -8(%rbp), %rdi
	mov -16(%rbp), %rsi
	leave
	ret

ishexchar:
	cmp $48, %dil
	jb .ishexchar.n
	cmp $57, %dil
	ja .ishexchar.0
	jmp .ishexchar.y
.ishexchar.n:
	xor %rax, %rax
	ret
.ishexchar.y:
	mov $1, %rax
	ret
.ishexchar.0:
	cmp $65, %dil
	jb .ishexchar.n
	cmp $70, %dil
	ja .ishexchar.1
	jmp .ishexchar.y
.ishexchar.1:
	cmp $97, %dil
	jb .ishexchar.n
	cmp $102, %dil
	ja .ishexchar.n
	jmp .ishexchar.y

unhexc:
	mov %dil, %al
	cmp $57, %al
	ja .unhexc.0
	sub $48, %al
	ret
.unhexc.0:
	cmp $70, %al
	ja .unhexc.1
	sub $55, %al
	ret
.unhexc.1:
	sub $87, %al
	ret

unhexdctob:
# rdi - pointer to hex chars
# ret al - decoded byte
	push %rbp
	mov %rsp, %rbp
	sub $1, %rsp
	mov %rdi, %rbx
	mov $2, %rcx
.unhexdctob.l0:
	mov -1(%rbx, %rcx), %dil
	call ishexchar
	cmp $0, %al
	je .unhexdctob.errret
	loop .unhexdctob.l0
	mov $2, %rcx
	movb $0, -1(%rbp)
.unhexdctob.l1:
	mov -1(%rbx, %rcx), %dil
	call unhexc
	cmp $1, %rcx
	jne .unhexdctob.0
	shl $4, %al
.unhexdctob.0:
	or %al, -1(%rbp)
	loop .unhexdctob.l1
	mov -1(%rbp), %al
	jmp .unhexdctob.ret
.unhexdctob.errret:
	mov $-1, %rax
.unhexdctob.ret:
	leave
	ret

_exit: # group exit
	mov $231, %rax
	syscall

sndfd:
	push %rbp
	mov %rsp, %rbp
	mov %esi, -16(%rbp)
	mov %rdx, -12(%rbp)
	mov (%rdi), %eax
	mov %eax, -4(%rbp)
	sub $24, %rsp
.sndfd.2:
	cmpq $65536, -12(%rbp)
	ja .sndfd.0
	jb .sndfd.1
.sndfd.0:
	mov $65536, %r10
	subq $65536, -12(%rbp)
	jmp .sndfd.3
.sndfd.1:
	mov -12(%rbp), %r10
	movq $0, -12(%rbp)
.sndfd.3:
	mov -4(%rbp), %eax
	mov %eax, -24(%rbp)
	movw $8216, -20(%rbp)
	movw $0, -18(%rbp)
	lea -24(%rbp), %rdi
	mov $1, %rsi
	xor %rdx, %rdx
	mov $7, %rax
	syscall
	testw $8216, -18(%rbp)
	jnz .sndfd.disconn
	mov $40, %rax
	mov -4(%rbp), %edi
	mov -16(%rbp), %esi
	xor %rdx, %rdx
	syscall
	cmp $0, %rax
	jl .sndfd.disconn
	je .sndfd.ret
	cmpq $0, -12(%rbp)
	ja .sndfd.2
	xor %rax, %rax
	jmp .sndfd.ret
.sndfd.disconn:
	mov $-1, %rax
.sndfd.ret:
	leave
	ret

sndfdat:
# edi - sending file fd
# rsi - streamb struct ptr
# rdx - offset
# r10 - send len(doesn't trancates to file size)
	push %rbp
	mov %rsp, %rbp
	mov %edi, -32(%rbp)
	mov (%rsi), %eax
	mov %eax, -20(%rbp)
	mov %rdx, -8(%rbp)
	mov %r10, -16(%rbp)
	sub $32, %rsp
	mov %r10, %rax
	xor %rdx, %rdx
	mov $65536, %rbx
	div %rbx
	lea 1(%rax), %rcx
.sndfdat.0:
	push %rcx
	mov -20(%rbp), %eax
	mov %eax, -28(%rbp)
	movw $8216, -24(%rbp)
	movw $0, -22(%rbp)
	lea -28(%rbp), %rdi
	mov $1, %rsi
	xor %rdx, %rdx
	mov $7, %rax
	syscall
	testw $8216, -22(%rbp)
	jnz .sndfdat.dis
	cmpq $65536, -16(%rbp)
	ja .sndfdat.1
	mov -16(%rbp), %r10
	jmp .sndfdat.2
.sndfdat.1:
	mov $65536, %r10
.sndfdat.2:
	movsxd -32(%rbp), %rsi
	movsxd -20(%rbp), %rdi
	lea -8(%rbp), %rdx
	mov $40, %rax
	syscall
	cmp $-1, %rax
	jle .sndfdat.ret
	cmp $0, %rax
	je .sndfdat.ret
	pop %rcx
	loop .sndfdat.0
.sndfdat.ret:
	leave
	ret
.sndfdat.dis:
	mov $-1, %rax
	jmp .sndfdat.ret

bputc:
# Puts single character into the stream buffer
# rdi - STREAMB pointer
# sil - char
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %sil, -9(%rbp)
	sub $9, %rsp
	mov -8(%rbp), %rdi
	lea -9(%rbp), %rsi
	mov $1, %rdx
	call sbuffwrite
	movzxb -9(%rbp), %rax
	mov -8(%rbp), %rsi
	mov %rsi, %rdi
	leave
	ret

bsndstr:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	mov -8(%rbp), %rdi
	call sbuffwrite
	mov -8(%rbp), %rdi
	leave
	ret

bsndstrbyidx:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %edx, -20(%rbp)
	sub $20, %rsp
	mov -16(%rbp), %rdi
	movsxd -20(%rbp), %rsi
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -8(%rbp), %rdi
	call sbuffwrite
	mov -16(%rbp), %rsi
	mov -20(%rbp), %edx
	leave
	ret

bsndustr:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	sub $16, %rsp
	mov %rsi, %rdi
	call utostr
	mov %rax, %rdi
	mov %rax, %rsp
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -8(%rbp), %rdi
	call sbuffwrite
	mov -8(%rbp), %rdi
	leave
	ret

ctolc:
	cmp $65, %dil
	jb .ctolc.0
	cmp $90, %dil
	ja .ctolc.0
	movzx %dil, %rax
	add $32, %al
	ret
.ctolc.0:
	movzx %dil, %rax
	ret

ctouc:
	cmp $97, %dil
	jb .ctouc.0
	cmp $122, %dil
	ja .ctouc.0
	movzx %dil, %rax
	sub $32, %al
	ret
.ctouc.0:
	movzx %dil, %rax
	ret

strtoc:
# string to low case
# rdi - char pointer
# si - 0-low case 1-up case
# rdx - length
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %si, -10(%rbp)
	mov %rdx, -18(%rbp)
	sub $18, %rsp
	mov %rdx, %rcx
.strtoc.l:
	mov -8(%rbp), %rdi
	mov -1(%rdi, %rcx), %dil
	cmp $0, %si
	je .strtoc.0
	call ctouc
	jmp .strtoc.1
.strtoc.0:
	call ctolc
.strtoc.1:
	mov -8(%rbp), %rdi
	mov %al, -1(%rdi, %rcx)
	loop .strtoc.l
	leave
	ret

# struct ranges{
#	char mode; // 0 - from given start to end
#			   // 1 - from given start to given end
#			   //     can be several ranges
#			   // 2 - from given offset off end
#			   // Not implemented:
#			   // 3 - like 1 but last range like 0
#			   // 4 - like 1 but last range like 2
#	long p1;
#	long p2;   // exists only with mode 1
#   ...
# };

getrange:
# Sets the "ranges" structure pointer from the ranges in requests to rsi address
# rdi - client stream
# rsi - address for load structure
# ret rax - number of ranges in structure founded in request
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	movw $0, -30(%rbp)
	sub $630, %rsp
	mov %rsp, %rdi
	xor %sil, %sil
	mov $600, %rdx
	call memset
	mov -8(%rbp), %rdi
	mov %rsp, %rsi
	mov $600, %rdx
	mov $-2, %r10
	call sbuffread
	cmp $0, %rax
	jle .getrange.0
	movsx %eax, %rdx
	mov %rsp, %rdi
	xor %si, %si
	call strtoc
	mov $32, %sil # delete spaces
	call delc
	mov $10, %sil # delete tabs
	call delc
	mov $.getrange.str0, %rsi
	call getstrexpofft
	cmp $0, %rax
	jl .getrange.0
	lea (%rsp, %rax), %rax
	lea -24(%rbp), %rdi
	stosq
	mov $.getrange.str0, %rdi
	call strlen
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	call strlen
	mov %rax, %rdx
	mov %rsp, %rsi
	call memmovp
	mov %rsp, -24(%rbp) 
	mov %rsp, %rdi
	mov $13, %sil
	call offt_to_delim
	push %rax
	mov $10, %sil
	call offt_to_delim
	mov %rax, %rdi
	pop %rsi
	call min
	mov %rsp, %rdi
	movb $0, (%rdi, %rax)
	mov %eax, -28(%rbp)
	call strulen 
	cmp $0, %rax
	jne .getrange.1
	sub $9, %rsp
	incq -24(%rbp)
	movb $2, (%rsp)
	movsxd -28(%rbp), %rsi
	dec %esi
	mov -24(%rbp), %rdi
	call strtou
	mov %rax, 1(%rsp)
.getrange.1.ret:
	mov -16(%rbp), %rax
	lea 9(%rsp), %rdi
	stosq
	mov %rsp, %rdi
	lea -17(%rbp), %rsi
	mov $9, %rdx
	call memmovp
	mov 9(%rsp), %rdi
	lea -17(%rbp), %rax
	stosq
	mov $1, %rax
	jmp .getrange.ret
.getrange.1:
	movsxd -28(%rbp), %rsi
	dec %esi
	cmp %esi, %eax
	jne .getrange.2
	sub $9, %rsp
	movb $0, (%rsp)
	mov -24(%rbp), %rdi
	call strtou
	mov %rax, 1(%rsp)
	jmp .getrange.1.ret
.getrange.2:
	mov -24(%rbp), %rdi
	call strulen
	cmp $0, %rax
	je .getrange.3
	sub $16, %rsp
	movzxw -30(%rbp), %rdx
	lea 16(%rsp), %rdi
	mov %rsp, %rsi
	call memmovp
	mov -24(%rbp), %rdi
	call strulen
	mov %rax, %rsi
	call strtou
	movzxw -30(%rbp), %rdx
	mov %rax, (%rsp, %rdx)
	add %rsi, -24(%rbp)
	incq -24(%rbp)
	mov -24(%rbp), %rdi
	call strulen
	mov %rax, %rsi
	call strtou
	inc %rax
	movzxw -30(%rbp), %rdx
	mov %rax, 8(%rsp, %rdx)
	add %rsi, -24(%rbp)
	addw $16, -30(%rbp)
	call strlen
	cmp $2, %rax
	jb .getrange.3
	incq -24(%rbp)
	jmp .getrange.2
.getrange.3:
	dec %rsp
	pushq -16(%rbp)
	movb $1, 8(%rsp)
	movzxw -30(%rbp), %rbx
	neg %rbx
	lea -18(%rbp, %rbx), %rsi
	neg %rbx
	lea 1(%rbx), %rdx
	lea 8(%rsp), %rdi
	call memmovp
	pop %rdi
	mov %rsi, (%rdi)
	mov %bx, %ax
	xor %dx, %dx
	mov $16, %bx
	div %bx
	jmp .getrange.ret
.getrange.0:
	xor %rax, %rax
.getrange.ret:
	leave
	ret
.data
.getrange.str0:
	.asciz "range:bytes="
.text

delc:
# Deletes characters in strings
# rdi - string
# sil - char
	push %rdi
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %sil, -9(%rbp)
	sub $9, %rsp
.delc.0:
	mov -9(%rbp), %sil
	call offt_to_delim
	add %rax, -8(%rbp)
	mov -8(%rbp), %rdi
	call skip_delim_off
	cmp $0, %rax
	je .delc.ret
	mov %rax, %rsi
	neg %rsi
	add %rax, -8(%rbp)
	mov -8(%rbp), %rdi
	call strlen
	mov %rax, %rdx
	call memmov
	mov -8(%rbp), %rdi
	call strlen
	cmp $0, %rax
	ja .delc.0
.delc.ret:
	leave
	pop %rdi
	ret

getstrexpofft:
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	pop %rdi
	call getexpofft
	ret

getexpofft:
# Returns offset to expression rsi in rdi
# rdi - data ptr
# rsi - expression
# rdx - expression length
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	movq $0, -32(%rbp)
	sub $32, %rsp
	jmp .getexpofft.1
.getexpofft.0:
	incq -8(%rbp)
	incq -32(%rbp)
	mov -8(%rbp), %rdi
	call strlen
	cmp -24(%rbp), %rax
	jb .getexpofft.nf
.getexpofft.1:
	mov -8(%rbp), %rdi
	mov -16(%rbp), %rsi
	mov -24(%rbp), %rdx
	call memcmp
	cmp $0, %rax
	je .getexpofft.0
	mov -8(%rbp), %rdi
	mov -32(%rbp), %rax
	jmp .getexpofft.ret
.getexpofft.nf:
	mov $-1, %rax
.getexpofft.ret:
	leave
	ret

chkmethod:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movw $0, -10(%rbp)
	sub $10, %rsp
	xor %al, %al
.chkmethod.0:
	dec %rsp
	mov %al, (%rsp)
	incw -10(%rbp)
	mov -8(%rbp), %rdi
	mov (timeout), %rsi
	call sbuffgetc
	cmp $-1, %rax
	jle .chkmethod.hup
	cmp $0x20, %al
	je .chkmethod.2
	cmp $10, %al
	je .chkmethod.2
	cmp $13, %al
	je .chkmethod.2
	cmpw $10, -10(%rbp)
	jae .chkmethod.er
	jmp .chkmethod.0
.chkmethod.2:
	mov %rsp, %rdi
	movzxw -10(%rbp), %rsi
	sub $2, %rsi
	call memrev
	mov $HTTP_M, %rsi
	mov $1, %rdx
	call strinstrs
	cmp $0, %al
	je .chkmethod.1
	mov $-1, %rax
.chkmethod.1:
	mov -8(%rbp), %rdi
	leave
	ret
.chkmethod.er:
	mov $-1, %rax
	jmp .chkmethod.1
.chkmethod.hup:
	mov $-3, %rax
	jmp .chkmethod.1

chkprotl:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movw $0, -10(%rbp)
	sub $10, %rsp
	xor %al, %al
.chkprotl.0:
	dec %rsp
	mov %al, (%rsp)
	incw -10(%rbp)
	mov -8(%rbp), %rdi
	mov (timeout), %rsi
	call sbuffgetc
	cmp $-1, %rax
	jle .chkprotl.2
	cmp $0x20, %al
	je .chkprotl.1
	cmp $10, %al
	je .chkprotl.1
	cmp $13, %al
	je .chkprotl.1
	jmp .chkprotl.0
.chkprotl.1:
	mov %rsp, %rdi
	movzxw -10(%rbp), %rsi
	sub $2, %rsi
	call memrev
	mov $HTTPV, %rsi
	call streq
.chkprotl.2:
	leave
	ret

.equ AT_FDCWD, 4294967196

chkroot:
# Checks attachment of path to the server's root
# rdi - path
# ret rax - bool
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $12, %rsp
	mov (fsroot), %rdi
	mov $81, %rax
	syscall
	sub $4096, %rsp
	mov %rsp, %rdi
	mov $4096, %rsi
	mov $79, %rax
	syscall
	mov $AT_FDCWD, %rdi
	mov -8(%rbp), %rsi
	mov $65536, %rdx
	mov $257, %rax
	syscall
	cmp $-20, %rax
	jne .chkroot.1
	mov -8(%rbp), %rdi
	call strlen
.chkroot.0:
	dec %rax
	cmp $0, %rax
	jle .chkroot.2
	cmpb $47, (%rdi, %rax)
	jne .chkroot.0
.chkroot.2:
	add $2, %rax
	sub %rax, %rsp
	mov %rsp, %rdi
	mov -8(%rbp), %rsi
	lea -2(%rax), %rdx
	call memcpy
	cmp $0, %rdx
	jne .chkroot.3
	movb $46, (%rsp)
.chkroot.3:
	movb $0, 1(%rsp, %rdx)
	mov $AT_FDCWD, %rdi
	mov %rsp, %rsi
	lea 2(%rsp, %rdx), %rsp
	mov $65536, %rdx
	mov $257, %rax
	syscall
.chkroot.1:
	mov %eax, -12(%rbp)
	mov %rax, %rdi 
	mov $81, %rax
	syscall
	sub $4096, %rsp
	mov %rsp, %rdi
	mov $4096, %rsi
	mov $79, %rax
	syscall
	mov %rsp, %rsi
	lea 4096(%rsp), %rdi
	call strlen
	mov %rax, %rdx
	call memcmp
	dec %rsp
	movb %al, (%rsp)
.chkroot.ret:
	mov -12(%rbp), %edi
	mov $3, %rax
	syscall
	movzxb (%rsp), %rax
	leave
	ret

client_thr:
	push %rbp
	mov %rsp, %rbp

	sub $183, %rsp
	movw $0, -174(%rbp)
	lea -156(%rbp), %rdi
	mov $156, %rdx
	xor %sil, %sil
	call memset

	mov $1, %rax
	stosq
	mov $0, %rax
	lea -140(%rbp), %rdi
	stosq
	movq $0, -148(%rbp) 
	mov $13, %rdi
	lea -156(%rbp), %rsi
	xor %rdx, %rdx
	mov $8, %r10
	mov $13, %rax
	syscall

	mov 8(%rbp), %rdi
	xor %rsi, %rsi
	call sbuffattach
	mov %rax, %rdi
	mov %rax, -164(%rbp)
	call chkmethod
	cmp $-3, %rax
	je .client_thr.closeconn
	cmp $-1, %rax
	je .client_thr.400.m
	cmp $-2, %rax
	je .client_thr.408
	call getcpath
	cmp $-1, %rax
	je .client_thr.closeconn
	cmp $-2, %rax
	jle .client_thr.408
	mov %rax, %rsp
	mov %rsp, -156(%rbp)	# requested file name pointer to string saved in -156(%rbp)
	mov -164(%rbp), %rdi
	call chkprotl
	cmp $0, %rax
	je .client_thr.400.p
	cmp $-1, %rax
	jle .client_thr.closeconn
	mov -164(%rbp), %rdi
	lea -172(%rbp), %rsi
	call getrange
	cmp $0, %ax
	je .client_thr.nrs
	mov -172(%rbp), %rsp
	mov %ax, -174(%rbp)
.client_thr.nrs:
	mov -156(%rbp), %rdi
	call strlen
	cmp $0, %rax
	je .client_thr.root_dir
	mov -156(%rbp), %rsi
	mov (fsroot), %rdi
	xor %rdx, %rdx
	mov $257, %rax
	syscall
	cmp $-13, %rax
	je .client_thr.403.oer
	cmp $-2, %rax
	je .client_thr.404
	cmp $-1, %rax
	jle .client_thr.404
	movl %eax, -148(%rbp)
	mov -156(%rbp), %rdi
	call chkroot
	cmp $0, %al
	je .client_thr.403
	movl -148(%rbp), %eax
.client_thr.200:
	movl %eax, -148(%rbp)
	mov $5, %rax
	lea -144(%rbp), %rsi
	movl -148(%rbp), %edi
	syscall
	movl -120(%rbp), %eax
	andl $07, %eax
	cmpl (mpermission), %eax
	jl .client_thr.403
	movl -120(%rbp), %eax
	andl $0170000, %eax
	cmpl $040000, %eax
	je .client_thr.dfile
	jmp .client_thr.pfile
.client_thr.dfile:
	testb $8, (fls)
	jnz .client_thr.dfile.1
	testb $128, (fls)
	jz .client_thr.404
	jmp .client_thr.dirlist
.client_thr.dfile.1:
	movl -148(%rbp), %edi
	mov (ddir_filep), %rsi
	xor %rdx, %rdx
	mov $257, %rax
	syscall
	testb $128, (fls)
	jz .client_thr.dfile.0
	cmp $0, %rax
	jl .client_thr.dirlist
.client_thr.dfile.0:
	mov %rax, %r9
	movl -148(%rbp), %edi
	mov $3, %rax
	syscall
	cmp $-13, %r9
	je .client_thr.403
	cmp $-2, %r9
	je .client_thr.404
	movl %r9d, -148(%rbp)
	mov $5, %rax
	lea -144(%rbp), %rsi
	movl -148(%rbp), %edi
	syscall
	mov -120(%rbp), %eax
	andl $07, %eax
	cmpl (mpermission), %eax
	jl .client_thr.403
.client_thr.pfile:
	cmpw $0, -174(%rbp)
	ja .client_thr.206
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $resp_m, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov -96(%rbp), %rsi
	call bsndustr
	mov $resp, %rsi
	mov $3, %edx
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	cmpq $0, -156(%rbp)
	je .client_thr.pfile.4
	mov -156(%rbp), %rdi
	call strlen
	cmpb $47, -1(%rdi, %rax)
	jne .client_thr.pfile.3
.client_thr.pfile.4:
	mov (ddir_filep), %rdi
.client_thr.pfile.3:
	call getext
	cmp $0, %rax
	jle .client_thr.pfile.0
	mov %rax, %rdi
	mov (mtypesp), %rsi
	call findtype
	cmp $0, %rax
	jle .client_thr.pfile.0
	mov %rax, %rsi
	jmp .client_thr.pfile.1
.client_thr.pfile.0:
	mov $types, %rsi
	mov $2, %edx
	mov -164(%rbp), %rdi
	call bsndstrbyidx
	jmp .client_thr.pfile.2
.client_thr.pfile.1:
	mov -164(%rbp), %rdi
	call bsndstr
.client_thr.pfile.2:
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	call sbuffflush
	cmp $-1, %rax
	jle .client_thr.disconn
	mov -148(%rbp), %rsi
	mov -164(%rbp), %rdi
	mov -96(%rbp), %rdx
	call sndfd
	cmp $-1, %rax
	jle .client_thr.disconn
	mov 8(%rbp), %rdi
.client_thr.disconn:
	cmpl $0, -148(%rbp)
	je .client_thr.closeconn
	mov $3, %rax
	mov -148(%rbp), %rdi
	syscall

.client_thr.closeconn:
	mov -164(%rbp), %rdi
	call sbuffclose

	call thread_exit
.client_thr.root_dir:
	mov (fsroot), %rdi
	sub $2, %rsp
	movw $46, (%rsp)
	mov %rsp, %rsi
	mov $65536, %rdx
	mov $257, %rax
	syscall
	add $2, %rsp
	movq $0, -156(%rbp)
	jmp .client_thr.200
.client_thr.404:
	testw $1024, (fls)
	jz .client_thr.404.1
	mov -156(%rbp), %rdi
	mov (caches_struct), %rsi
	mov (fsroot), %edx
	call lookforcache
	cmp $-1, %rax
	jle .client_thr.404.1
	mov %rax, %rdi
	mov (caches_struct), %rsi
	call delcache
.client_thr.404.1:
	testb $32, (fls)
	jnz .client_thr.404.c
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $resp_m, %rsi
	mov $1, %edx
	call bsndstrbyidx
	mov $resp, %rsi
	call bsndstrbyidx

	cmpq $0, -156(%rbp)
	jne .client_thr.404.0
	dec %rsp
	mov %rsp, -156(%rbp)
	mov -156(%rbp), %rdi
	xor %al, %al
	stosb
	jmp .client_thr.404.0
.client_thr.404.0:
	mov $resp, %rsi
	mov -164(%rbp), %rdi
	mov $2, %edx
	call bsndstrbyidx
	mov $d404p, %rdi
	mov $2, %rsi
	call strslen
	mov %rax, %rsi
	mov -156(%rbp), %rdi
	call strlen
	add %rax, %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $resp, %rsi
	mov $3, %edx
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx

	mov $d404p, %rsi
	call bsndstr
	mov -156(%rbp), %rsi
	call bsndstr

	mov $1, %edx
	mov $d404p, %rsi
	call bsndstrbyidx
	call sbuffflush
	mov 8(%rbp), %rdi
	jmp .client_thr.closeconn
.client_thr.404.c:
	mov (p404path), %rdi
	xor %rsi, %rsi
	mov $2, %rax
	syscall

	cmp $0, %rax
	jg .client_thr.404.cc
	mov %rdi, %rdx
	mov $5, %rdi
	xor %sil, %sil
	call perror
.client_thr.404.cc:
	movl %eax, -148(%rbp)
	mov %rax, %rdi
	lea -144(%rbp), %rsi
	mov $5, %rax
	syscall

	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $1, %edx
	mov $resp_m, %rsi
	call bsndstrbyidx
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov -96(%rbp), %rsi
	call bsndustr
	mov $resp, %rsi
	mov $3, %edx
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	call sbuffflush
	movl -148(%rbp), %esi
	mov -164(%rbp), %rdi
	mov -96(%rbp), %rdx
	call sndfd
	mov 8(%rbp), %rdi
	jmp .client_thr.disconn
.client_thr.403.oer:
	movl $0, -148(%rbp)
.client_thr.403:
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $2, %edx
	mov $resp_m, %rsi
	call bsndstrbyidx
	mov $resp, %rsi
	dec %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	testb $64, (fls)
	jnz .client_thr.403.c
	mov $d403p, %rdi
	call strlen
	mov %rax, -8(%rbp)
	cmpq $0, -156(%rbp)
	jne .client_thr.403.up
.client_thr.403.mkr:
	dec %rsp
	mov %rsp, -156(%rbp)
	mov -156(%rbp), %rdi
	xor %al, %al
	stosb
.client_thr.403.up:
	mov -156(%rbp), %rdi
	call strlen
	add %rax, -8(%rbp)
	mov $d403p, %rdi
	mov $1, %rsi
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	add %rax, -8(%rbp)
	mov -8(%rbp), %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $resp, %rsi
	mov $3, %edx
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $7, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov $d403p, %rsi
	call bsndstr
	mov -156(%rbp), %rsi
	call bsndstr
	mov $d403p, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	jmp .client_thr.403.end
.client_thr.403.c:
	mov (p403path), %rdi
	xor %rsi, %rsi
	mov $2, %rax
	syscall
	cmp $0, %rax
	jle .client_thr.403.end
	mov %eax, -148(%rbp)
	mov $5, %rax
	mov -148(%rbp), %edi
	lea -144(%rbp), %rsi
	syscall
	mov -96(%rbp), %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $3, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $7, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	call sbuffflush
	movl -148(%rbp), %esi
	mov -164(%rbp), %rdi
	mov -96(%rbp), %rdx
	call sndfd
.client_thr.403.end:
	mov 8(%rbp), %rdi
	jmp .client_thr.disconn
.client_thr.400.p:
	movb $1, -9(%rbp)
	jmp .client_thr.400
.client_thr.400.m:
	movb $2, -9(%rbp)
.client_thr.400:
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $resp_m, %rsi
	mov $3, %edx
	call bsndstrbyidx
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov $d400p, %rdi
	call strlen
	mov %rax, -8(%rbp)
	movzxb -9(%rbp), %esi
	call strlenbyidx
	add %rax, -8(%rbp)
	mov $3, %esi
	call strlenbyidx
	add %rax, -8(%rbp)
	mov -8(%rbp), %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $3, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov $d400p, %rsi
	call bsndstr
	mov $d400p, %rsi
	movzxb -9(%rbp), %edx
	call bsndstrbyidx
	mov $d400p, %rsi
	mov $3, %edx
	call bsndstrbyidx
	call sbuffflush
	mov 8(%rbp), %rdi
	jmp .client_thr.closeconn
.client_thr.408:
	mov $resp, %rsi
	mov -164(%rbp), %rdi
	call bsndstr
	mov $resp_m, %rsi
	mov $4, %edx
	call bsndstrbyidx
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	mov 8(%rbp), %rdi
	jmp .client_thr.closeconn
.client_thr.206:
	mov -96(%rbp), %rax
	mov -172(%rbp), %rdi
	cmpb $1, (%rdi)
	jne .client_thr.206.2
	movzxw -174(%rbp), %rcx
	inc %rdi
	add %rcx, %rcx
.client_thr.206.0:
	cmp %rax, (%rdi)
	ja .client_thr.416
	add $8, %rdi
	loop .client_thr.206.0
	mov -172(%rbp), %rdi
	movzxw -174(%rbp), %rcx
	inc %rdi
	lea 8(%rdi), %rsi
.client_thr.206.1:
	cmpsq
	jbe .client_thr.416
	add $8, %rdi
	add $8, %rsi
	loop .client_thr.206.1
	jmp .client_thr.206.4
.client_thr.206.2:
	cmp %rax, 1(%rdi)
	jae .client_thr.416
	cmpb $2, (%rdi)
	je .client_thr.206.3
	jmp .client_thr.206.4
.client_thr.206.3:
	cmpq $0, 1(%rdi)
	je .client_thr.416
.client_thr.206.4:
	mov $resp, %rsi
	mov -164(%rbp), %rdi
	call bsndstr
	mov $resp_m, %rsi
	mov $5, %edx
	call bsndstrbyidx
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	cmpw $1, -174(%rbp)
	ja .client_thr.206.5
	mov $4, %edx
	call bsndstrbyidx
	mov -172(%rbp), %rbx
	mov 1(%rbx), %rsi
	cmpb $2, (%rbx)
	jne .client_thr.206.4.2
	mov -96(%rbp), %rax
	sub %rsi, %rax
	mov %rax, %rsi
.client_thr.206.4.2:
	call bsndustr
	mov $45, %sil
	call bputc
	mov -172(%rbp), %rbx
	cmpb $1, (%rbx)
	jne .client_thr.206.4.0
	mov 9(%rbx), %rsi
	jmp .client_thr.206.4.1
.client_thr.206.4.0:
	mov -96(%rbp), %rsi
.client_thr.206.4.1:
	dec %rsi
	call bsndustr
	mov $47, %sil
	call bputc
	mov -96(%rbp), %rsi
	call bsndustr
	mov $5, %edx
	mov $resp, %rsi
	call bsndstrbyidx
.client_thr.206.5:
	mov $2, %edx
	call bsndstrbyidx
	mov -172(%rbp), %rdi
	mov -96(%rbp), %rsi
	mov -174(%rbp), %dx
	call cranges
	mov %rax, -182(%rbp)
	mov %rax, %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $3, %edx
	mov $resp, %rsi
	mov -164(%rbp), %rdi
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	cmpw $1, -174(%rbp)
	je .client_thr.206.6
	mov $1, %edx
	call bsndstrbyidx
	jmp .client_thr.206.7
.client_thr.206.6:
	cmpq $0, -156(%rbp)
	je .client_thr.206.18
	mov -156(%rbp), %rdi
	call strlen
	cmpb $47, -1(%rdi, %rax)
	jne .client_thr.206.12
.client_thr.206.18:
	mov (ddir_filep), %rdi
.client_thr.206.12:
	call getext
	cmp $0, %rax
	jle .client_thr.206.13
	mov %rax, %rdi
	mov (mtypesp), %rsi
	call findtype
	cmp $0, %rax
	jle .client_thr.206.13
	mov -164(%rbp), %rdi
	mov %rax, %rsi
	call bsndstr
	jmp .client_thr.206.7
.client_thr.206.13:
	mov -164(%rbp), %rdi
	mov $types, %rsi
	mov $2, %edx
	call bsndstrbyidx
.client_thr.206.7:
	mov $7, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	mov $8, %edx
	call bsndstrbyidx
	call sbuffflush
	cmp $-1, %rax
	jle .client_thr.disconn
	cmpw $1, -174(%rbp)
	ja .client_thr.206.8
	mov -148(%rbp), %edi
	mov -164(%rbp), %rsi
	mov -182(%rbp), %r10
	mov -172(%rbp), %rbx
	cmpb $2, (%rbx)
	je .client_thr.206.9
	mov 1(%rbx), %rdx
	jmp .client_thr.206.10
.client_thr.206.9:
	mov -96(%rbp), %rdx
	sub 1(%rbx), %rdx
	jmp .client_thr.206.10
.client_thr.206.10:
	call sndfdat
	cmp $-1, %rax
	jg .client_thr.403.end
	jmp .client_thr.disconn
.client_thr.206.8:
	movzxw -174(%rbp), %rcx
.client_thr.206.11:
	push %rcx
	mov $ddash, %rsi
	mov -164(%rbp), %rdi
	call bsndstr
	mov $strsep, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	mov $4, %edx
	call bsndstrbyidx
	movzxw -174(%rbp), %rbx
	mov -172(%rbp), %rdi
	mov (%rsp), %rcx
	sub %rcx, %rbx
	add %rbx, %rbx
	mov 1(%rdi, %rbx, 8), %rsi
	push %rsi
	mov 9(%rdi, %rbx, 8), %rsi
	push %rsi
	mov 8(%rsp), %rsi
	mov -164(%rbp), %rdi
	call bsndustr
	mov $45, %sil
	call bputc
	mov (%rsp), %rsi
	dec %rsi
	call bsndustr
	mov $47, %sil
	call bputc
	mov -96(%rbp), %rsi
	call bsndustr
	mov $5, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	cmpq $0, -156(%rbp)
	je .client_thr.206.19
	mov -156(%rbp), %rdi
	call strlen
	cmpb $47, -1(%rdi, %rax)
	jne .client_thr.206.14
.client_thr.206.19:
	mov (ddir_filep), %rdi
.client_thr.206.14:
	call getext
	cmp $0, %rax
	jle .client_thr.206.15
	mov %rax, %rdi
	mov (mtypesp), %rsi
	call findtype
	cmp $0, %rax
	jle .client_thr.206.15
	mov %rax, %rsi
	jmp .client_thr.206.16
.client_thr.206.15:
	mov $types, %rsi
	mov $2, %edx
	mov -164(%rbp), %rdi
	call bsndstrbyidx
	jmp .client_thr.206.17
.client_thr.206.16:
	mov -164(%rbp), %rdi
	call bsndstr
.client_thr.206.17:
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	call bsndstrbyidx
	call sbuffflush
	cmp $-1, %rax
	jle .client_thr.disconn
	mov -148(%rbp), %edi
	mov -164(%rbp), %rsi
	pop %r10
	pop %rdx
	sub %rdx, %r10
	call sndfdat
	cmp $-1, %rax
	jle .client_thr.disconn
	mov -164(%rbp), %rdi
	mov $1, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	pop %rcx
	dec %rcx
	cmp $0, %rcx
	ja .client_thr.206.11
	mov $ddash, %rsi
	mov -164(%rbp), %rdi
	call bsndstr
	mov $strsep, %rsi
	call bsndstr
	mov $ddash, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	cmp $-1, %rax
	jle .client_thr.disconn
	jmp .client_thr.403.end
.client_thr.416:
	mov $resp, %rsi
	mov -164(%rbp), %rdi
	call bsndstr
	mov $resp_m, %rsi
	mov $6, %edx
	call bsndstrbyidx
	mov $1, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	mov $4, %edx
	call bsndstrbyidx
	mov $42, %sil
	call bputc
	mov $47, %sil
	call bputc
	mov -96(%rbp), %rsi
	call bsndustr
	mov $5, %edx
	mov $resp, %rsi
	call bsndstrbyidx
	call sbuffflush
	jmp .client_thr.403.end
.client_thr.dirlist:
	cmpq $0, -156(%rbp)
	jne .client_thr.dirlist.0
	dec %rsp
	movb $0, (%rsp)
	mov %rsp, -156(%rbp)
.client_thr.dirlist.0:
	testw $1024, (fls)
	jz .client_thr.dirlist.3
	sub $3, %rsp
	andb $0, -185(%rbp)
	mov -156(%rbp), %rdi
	mov (caches_struct), %rsi
	movsxd (fsroot), %rdx
	call lookforcache
	cmp $-1, %rax
	jle .client_thr.dirlist.3
	mov %rax, -184(%rbp)
	mov (caches_struct), %rdi
	movsxd (%rdi), %rdi 
	mov %rax, %rsi
	mov $0, %rdx
	mov $257, %rax
	syscall
	cmp $-1, %rax
	jg .client_thr.dirlist.9
	mov -184(%rbp), %rdi 
	mov (caches_struct), %rsi
	call delcache
	jmp .client_thr.dirlist.3
.client_thr.dirlist.9:
	mov %eax, -168(%rbp)
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $2, %r10
	mov %rax, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -176(%rbp)
	orb $1, -185(%rbp)
.client_thr.dirlist.3:
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $resp_m, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	mov $6, %edx
	call bsndstrbyidx
	mov $types, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $7, %edx
	call bsndstrbyidx
	inc %edx
	call bsndstrbyidx
	mov $dirlistp, %rsi
	call bsndstr
	mov -156(%rbp), %rsi
	call bsndstr
	mov $dirlistp, %rsi
	mov $1, %edx
	call bsndstrbyidx
	mov -156(%rbp), %rsi
	call bsndstr
	mov $dirlistp, %rsi
	mov $2, %edx
	call bsndstrbyidx
	call sbuffflush
	cmp $-1, %rax
	jle .client_thr.disconn
	testw $1024, (fls)
	jz .client_thr.dirlist.5
	testb $1, -185(%rbp)
	jz .client_thr.dirlist.5
	mov -176(%rbp), %rdi
	call strlen
	lea 9(%rax), %rbx
	mov 1(%rdi, %rax), %rax
	cmp %rax, -56(%rbp)
	je .client_thr.dirlist.6
	mov -176(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	movsxd -168(%rbp), %rdi
	mov $3, %rax
	syscall
.client_thr.dirlist.5:
	mov -148(%rbp), %edi
	call fdiropen
	cmp $-1, %rax
	jle .client_thr.disconn
	push %rax
	testw $512, (fls)
	jz .client_thr.dirlist.1
	mov %rsp, %rdi
	call dirfload
	mov (%rsp), %rdi
	call sortdir 
.client_thr.dirlist.1:
	sub $8, %rsp
	mov 8(%rsp), %rdi
	mov %rsp, %rsi
	call genpage
	push %rax
	mov -164(%rbp), %rdi
	mov %rax, %rsi
	call bsndstr
	testw $1024, (fls)
	jz .client_thr.dirlist.2
	mov -56(%rbp), %rax
	cmp %rax, -72(%rbp)
	je .client_thr.dirlist.2
	testb $1, -185(%rbp)
	jnz .client_thr.dirlist.8
	mov $caches_struct, %rdi
	mov (%rsp), %rsi
	mov -56(%rbp), %rdx
	mov 16(%rsp), %r10
	mov (%r10), %r10d
	call mkcache
	jmp .client_thr.dirlist.2
.client_thr.dirlist.8:
	mov -184(%rbp), %rdi
	mov (caches_struct), %rsi
	mov (%rsp), %rdx
	mov -56(%rbp), %r10
	call updcache
.client_thr.dirlist.2:
	mov 8(%rsp), %rsi
	pop %rdi
	mov $11, %rax
	syscall
	add $8, %rsp
	mov -164(%rbp), %rdi
	call sbuffflush
	pop %rdi
	call dirclose
	mov 8(%rbp), %rdi
	jmp .client_thr.closeconn
.client_thr.dirlist.6:
	push %rbx
.client_thr.dirlist.7:
	mov (%rsp), %r10
	mov -176(%rbp), %rsi
	movsxd -168(%rbp), %rdi
	mov $65536, %rdx
	mov $17, %rax
	syscall
	push %rax
	add %rax, 8(%rsp)
	mov %rax, %rdx
	mov -176(%rbp), %rsi
	mov -164(%rbp), %rdi
	call sbuffwrite
	add $8, %rsp
	cmpq $65536, -8(%rsp)
	je .client_thr.dirlist.7
	mov -164(%rbp), %rdi
	call sbuffflush
	mov -176(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	movsxd -168(%rbp), %rdi
	mov $3, %rax
	syscall
	mov 8(%rbp), %rdi
	jmp .client_thr.disconn

cranges:
# Computes total length of ranges
# rdi - ranges ptr
# rsi - file length
# dx - number of ranges
# ret rax - total length
	cmpb $2, (%rdi)
	je .cranges.2
	cmpb $1, (%rdi)
	je .cranges.1
	mov %rsi, %rax
	sub 1(%rdi), %rax
	jmp .cranges.ret
.cranges.2:
	mov 1(%rdi), %rax
	jmp .cranges.ret
.cranges.1:
	movzx %dx, %rcx
	xor %rax, %rax
.cranges.1l:
	mov 9(%rdi), %rbx
	mov 1(%rdi), %rdx
	sub %rdx, %rbx
	add %rbx, %rax
	add $16, %rdi
	loop .cranges.1l
.cranges.ret:
	ret

thread_exit:
	cmp $0x401000, %rbp
	ja .thread_exit.0
	jmp .thread_exit.1
.thread_exit.0:
	leave
	add $8, %rsp
.thread_exit.1:
	lea -65536(%rsp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	xor %rdi, %rdi
	jmp exit

skip_delim_off:
	push %rdi
	call skip_delim
	pop %rdi
	sub %rdi, %rax
	ret

skip_delim:
	mov %rdi, %rax
	cmpb $0, (%rdi)
	je .skip_delim.ret
	cmpb %sil, (%rdi)
	je .skip_delim.1
.skip_delim.ret:
	ret
.skip_delim.1:
	inc %rdi
	jmp skip_delim

strlenbyidx:
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	ret

getstrbyidx:
	push %rbp
	mov %rsp, %rbp
	movl %esi, -4(%rbp)
	mov %rdi, -12(%rbp)
.getstrbyidx.1:
	cmpl $0, -4(%rbp)
	ja .getstrbyidx.0
	je .getstrbyidx.3
.getstrbyidx.0:
	decl -4(%rbp)
.getstrbyidx.4:
	inc %rdi
.getstrbyidx.2:
	cmpb $0, -1(%rdi)
	ja .getstrbyidx.4
	jmp .getstrbyidx.1
.getstrbyidx.3:
	mov %rdi, %rax
	mov -12(%rbp), %rdi
	pop %rbp
	ret

memrev:
	push %rbp
	mov %rsp, %rbp
	mov %rsi, %rax
	mov $2, %rbx
	xor %rdx, %rdx
	div %rbx
	incl %eax
	movl %eax, -4(%rbp)
.memrev.0:
	cmpl $0, -4(%rbp)
	ja .memrev.1
	jmp .memrev.2
.memrev.1:
	decl -4(%rbp)
	movl -4(%rbp), %eax
	movb (%rdi, %rax), %cl
	neg %rax
	add %rsi, %rax
	movb (%rdi, %rax), %bl
	movb %cl, (%rdi, %rax)
	movl -4(%rbp), %eax
	movb %bl, (%rdi, %rax)
	jmp .memrev.0
.memrev.2:
	pop %rbp
	ret

memset:
	push %rdi
	mov %sil, %al
	mov %rdx, %rcx
	rep stosb
	pop %rdi
	mov %rdi, %rax
	ret

memcmp:
	lea 1(%rdx), %rcx
	repe cmpsb
	jrcxz .memcmp.e 
	xor %rax, %rax
	ret
.memcmp.e:
	mov $1, %rax
	ret

streq:
	call strlen
	mov %rax, %rbx
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rcx
	cmp %rbx, %rcx
	jne .streq.ne
	je .streq.0
.streq.0:
	pop %rdi
	mov %rbx, %rdx
	call memcmp
	ret
.streq.ne:
	pop %rdi
	xor %rax, %rax
	ret

skip_sts:
	push %rbp
	mov %rsp, %rbp
	movb $0, -9(%rbp)
	mov %rsi, -8(%rbp)
	sub $9, %rsp
.skip_sts.0:
	call buffgetc
	cmp $-1, %rax
	jle .skip_sts.ret
	cmpb $1, -9(%rbp)
	je .skip_sts.2	
	cmpb $35, %al
	je .skip_sts.1
	cmpb $0x20, %al
	je .skip_sts.0
	cmpb $10, %al
	je .skip_sts.3
	cmpb $0x9, %al
	je .skip_sts.0
	mov $-1, %rsi
	mov $1, %edx
	call buffseek
.skip_sts.ret:
	leave
	ret
.skip_sts.1:
	movb $1, -9(%rbp)
	mov -8(%rbp), %rax
	incq (%rax)
	jmp .skip_sts.0
.skip_sts.2:
	cmpb $10, %al
	jne .skip_sts.0
	movb $0, -9(%rbp)
	jmp .skip_sts.0
.skip_sts.3:
	mov -8(%rbp), %rax
	incq (%rax)
	jmp .skip_sts.0

getvar:
	push %rbp
	mov %rsp, %rbp
	mov %rsi, -16(%rbp)
	sub $16, %rsp
	call skip_sts
	movq $0, -8(%rbp)
.getvar.0:
	call buffgetc
	cmp $-1, %rax
	jle .getvar.err
	mov -8(%rbp), %rcx
	neg %rcx
	incq -8(%rbp)
	mov %al, -90(%rbp, %rcx)
	cmpb $0x20, %al
	je .getvar.2
	cmpb $10, %al
	je .getvar.3
	cmpb $9, %al
	je .getvar.2
	cmpb $61, %al
	jne .getvar.0
	je .getvar.1
.getvar.3:
	push %rcx
	mov $-1, %rsi
	mov $1, %edx
	call buffseek
	pop %rcx
.getvar.2:
	decq -8(%rbp)
	inc %rcx
.getvar.1:
	cmpq $0, -8(%rbp)
	je .getvar.err
	movb $0, -89(%rbp)
	lea -90(%rbp, %rcx), %rsp
	mov %rsp, %rdi
	mov -8(%rbp), %rsi
	sub $1, %rsi
	call memrev
	mov %rdi, %rax
	jmp .getvar.pass
.getvar.err:
	mov $-1, %rax
.getvar.pass:
	leave
	ret

unexp_word:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
.unexp_word.0:
	mov (cfgpath), %rdi
	call .perror.print
	call .unexp_word.2
	mov (stderr), %rdi
	mov -16(%rbp), %rsi
	call bsndustr
	call .unexp_word.2
	mov $ERR_unexp_word, %rdi
	mov $1, %rsi
	call getstrbyidx
	mov %rax, %rdi
	call .perror.print
	mov -8(%rbp), %rdi
	call .perror.print
	mov $2, %rsi
	mov $ERR_unexp_word, %rdi
	call getstrbyidx
	mov %rax, %rdi
	call .perror.fprint
	leave
	ret
.unexp_word.2:
	mov $ERR_unexp_word, %rdi
	call .perror.print
	ret

offt_to_delim:
	xor %rax, %rax
.offt_to_delim.1:
	cmpb $0, (%rdi, %rax)
	je .offt_to_delim.ret
	cmpb %sil, (%rdi, %rax)
	jne .offt_to_delim.0
.offt_to_delim.ret:
	ret
.offt_to_delim.0:
	inc %rax
	jmp .offt_to_delim.1 

min:
	cmp %rdi, %rsi
	jb .min.g
	mov %rdi, %rax
	ret
.min.g:
	mov %rsi, %rax
	ret

.ifdef DBG

println:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	call strlen
	add $2, %rax
	movw $2560, -3(%rsp)
	sub %rax, %rsp
	mov -8(%rbp), %rsi
	mov %rsp, %rdi
	lea -2(%rax), %rdx
	call memcpy
	mov %rsp, %rdi
	call strlen
	mov %rdi, %rsi
	mov %rax, %rdx
	mov $1, %rdi
	mov $1, %rax
	syscall
	mov -8(%rbp), %rdi
	mov %rbp, %rsp 
	pop %rbp
	ret

.endif

inet_addr:
	push %rbp
	mov %rsp, %rbp
	sub $14, %rsp
	mov %rdi, -8(%rbp)
	movb $0, -9(%rbp)
	movl $0, -13(%rbp)
	movb $0, -14(%rbp)
.inet_addr.0:
	mov -8(%rbp), %rdi
	mov %rdi, %rsi
	movb $0x2E, %sil
	call offt_to_delim
	mov -8(%rbp), %rdi
	mov %rax, %rsi
	movb %al, -14(%rbp)
	call strtou
	movzxb -14(%rbp), %rbx
	add %rbx, -8(%rbp)
	incq -8(%rbp)
	movzxb -9(%rbp), %rbx
	movb %al, -13(%rbp, %rbx)
	incb -9(%rbp)
	cmpb $4, -9(%rbp)
	jb .inet_addr.0
.inet_addr.ret:
	movsxd -13(%rbp), %rax
	leave
	ret

getval:
	push %rbp
	mov %rsp, %rbp
	movl $0, -4(%rbp)
	mov %rsi, -12(%rbp)
	sub $12, %rsp
.getval.0:
	call buffgetc
	cmp $-1, %rax
	jle .getval.1
	movsxd -4(%rbp), %rcx
	lea -14(%rbp, %rcx), %rsp
	cmp $92, %al
	je .getval.3
	mov %al, (%rsp)
	decl -4(%rbp)
	cmpb $35, %al
	je .getval.1
	cmpb $0x20, %al
	je .getval.1
	cmpb $10, %al
	je .getval.2
	cmpb $9, %al
	je .getval.1
	jmp .getval.0
.getval.ret:
	leave
	ret
.getval.2:
	mov $1, %edx
	mov $-1, %rsi
	call buffseek
.getval.1:
	movb $0, -13(%rbp)
	lea 1(%rsp), %rdi
	neg %rcx
	lea -1(%rcx), %rsi
	call memrev
	mov %rdi, %rax
	jmp .getval.ret
.getval.3:
	call buffgetc
	cmp $-1, %rax
	jle .getval.1
	movsxd -4(%rbp), %rcx
	decl -4(%rbp)
	mov %al, -14(%rbp, %rcx)
	lea -14(%rbp, %rcx), %rsp
	cmp $10, %al
	jne .getval.0
	mov -12(%rbp), %rax
	incq (%rax)
	jmp .getval.0

strinstrs:
	push %rbp
	mov %rsp, %rbp
	sub $24, %rsp
	movq %rsi, -8(%rbp)
	movq %rdi, -16(%rbp)
	movl %edx, -20(%rbp)
	movl $0, -24(%rbp)
.strinstrs.0:
	movl -24(%rbp), %eax
	cmpl %eax, -20(%rbp)
	jbe .strinstrs.ret
	movl -24(%rbp), %esi
	movq -8(%rbp), %rdi
	call getstrbyidx
	mov %rax, %rdi
	mov -16(%rbp), %rsi
	call streq
	incl -24(%rbp)
	cmpb $0, %al
	je .strinstrs.0
	decl -24(%rbp)
	movsxd -24(%rbp), %eax
.strinstrs.ret:
	leave
	ret

parse_cfg:
	push %rbp
	mov %rsp, %rbp
	movq $1, -24(%rbp)
	sub $32, %rsp
	mov %rsp, -32(%rbp)
	mov (cfgpath), %rdi
	xor %rsi, %rsi
	xor %rdx, %rdx
	call buffopen
	cmp $-1, %rax
	jle .parse_cfg.oerr
	mov %rax, -8(%rbp)
	jmp .parse_cfg.opts
.parse_cfg.oerr:
	mov $5, %rdi
	mov $1, %rsi
	mov (cfgpath), %rdx
	call perror
	jmp .parse_cfg.errret
.parse_cfg.opts:
	mov -32(%rbp), %rsp
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getvar
	cmp $0, %rax
	jl .parse_cfg.ret
	mov %rax, %rdi
	mov %rdi, -16(%rbp)
	mov %rdi, %rsp
	mov $CFG_KEYWORDS, %rsi
	mov $17, %rdx
	call strinstrs
	cmp $0, %rax
	je .parse_cfg.port
	cmp $1, %rax
	je .parse_cfg.addr
	cmp $2, %rax
	je .parse_cfg.root
	cmp $3, %rax
	je .parse_cfg.ddir_file
	cmp $4, %rax
	je .parse_cfg.do_ddir_files
	cmp $5, %rax
	je .parse_cfg.do_custom_404
	cmp $6, %rax
	je .parse_cfg.404_path
	cmp $7, %rax
	je .parse_cfg.do_custom_403
	cmp $8, %rax
	je .parse_cfg.403_path
	cmp $9, %rax
	je .parse_cfg.mpermission
	cmp $10, %rax
	je .parse_cfg.timeout
	cmp $11, %rax
	je .parse_cfg.do_dirlist
	cmp $12, %rax
	je .parse_cfg.mtypes
	cmp $13, %rax
	je .parse_cfg.show_hidden_files
	cmp $14, %rax
	je .parse_cfg.dirlist_sorting
	cmp $15, %rax
	je .parse_cfg.dirlists_caching
	cmp $16, %rax
	je .parse_cfg.cache_dir
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.ret:
	mov -8(%rbp), %rdi
	call buffclose
.parse_cfg.errret:
	leave
	ret
.parse_cfg.port:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	testb $1, (fls)
	jnz .parse_cfg.opts
	mov %rax, %rdi
	mov %rax, %rsp
	xor %rsi, %rsi
	call strtou
	movw %ax, (port)
	jmp .parse_cfg.opts
.parse_cfg.addr:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	testb $2, (fls)
	jnz .parse_cfg.opts
	mov %rax, %rdi
	mov %rax, %rsp
	call inet_addr
	movl %eax, (saddr)
	jmp .parse_cfg.opts
.parse_cfg.root:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	testb $4, (fls)
	jnz .parse_cfg.opts
	mov %rax, %rdi
	mov %rax, %rsp
	call strlen
	lea 1(%rax), %rdx
	mov %rdi, %rsi
	mov $pathesb, %rdi
	add (patheso), %rdi
	call memcpy
	mov %rdi, %rax
	lea (serv_root), %rdi
	stosq
	add %rdx, (patheso)
	jmp .parse_cfg.opts
.parse_cfg.do_ddir_files:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmp $0, %al
	je .parse_cfg.do_ddir_files.0
	orb $8, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_ddir_files.0:
	mov $FALSE, %rsi
	call streq
	cmp $0, %al
	je .parse_cfg.do_ddir_files.1
	andb $~8, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_ddir_files.1:
	mov %rsp, %rdi
	mov -24(%rbp), %rsi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.ddir_file:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	call strlen
	lea 1(%rax), %rdx
	mov $pathesb, %rdi
	add (patheso), %rdi
	mov %rsp, %rsi
	call memcpy
	movq %rdi, (ddir_filep)
	add %rdx, (patheso)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_404:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_custom_404.0
	orb $32, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_404.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_custom_404.1
	andb $~32, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_404.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.404_path:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	testb $32, (fls)
	jz .parse_cfg.opts
	mov %rax, %rsp
	mov %rax, %rdi
	call strlen
	lea 1(%rax), %rdx
	mov %rsp, %rsi
	mov $pathesb, %rdi
	add (patheso), %rdi
	call memcpy
	mov %rdi, (p404path)
	add %rdx, (patheso)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_403:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_custom_403.0
	orb $64, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_403.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_custom_403.1
	andb $~64, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_custom_403.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.403_path:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	testb $64, (fls)
	jz .parse_cfg.opts
	mov %rax, %rsp
	mov %rax, %rdi
	call strlen
	lea 1(%rax), %rdx
	mov %rsp, %rsi
	mov $pathesb, %rdi
	add (patheso), %rdi
	call memcpy
	mov %rdi, (p403path)
	add %rdx, (patheso)
	jmp .parse_cfg.opts
.parse_cfg.mpermission:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rax, %rdi
	xor %rsi, %rsi
	call strtou
	mov %eax, (mpermission)
	jmp .parse_cfg.opts
.parse_cfg.timeout:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rax, %rdi
	xor %rsi, %rsi
	call strtou
	mov %rax, (timeout)
	jmp .parse_cfg.opts
.parse_cfg.do_dirlist:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_dirlist.0
	orb $128, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_dirlist.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.do_dirlist.1
	andb $~128, (fls)
	jmp .parse_cfg.opts
.parse_cfg.do_dirlist.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.mtypes:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	call strlen
	lea 1(%rax), %rdx
	mov %rsp, %rsi
	mov $pathesb, %rdi
	add (patheso), %rdi
	call memcpy
	mov %rdi, %rax
	mov $mtypes, %rdi
	stosq
	add %rdx, (patheso)
	jmp .parse_cfg.opts
.parse_cfg.show_hidden_files:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.show_hidden_files.0
	orw $256, (fls)
	jmp .parse_cfg.opts
.parse_cfg.show_hidden_files.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.show_hidden_files.1
	andw $~256, (fls)
	jmp .parse_cfg.opts
.parse_cfg.show_hidden_files.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.dirlist_sorting:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.dirlist_sorting.0
	orw $512, (fls)
	jmp .parse_cfg.opts
.parse_cfg.dirlist_sorting.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.dirlist_sorting.1
	andw $~512, (fls)
	jmp .parse_cfg.opts
.parse_cfg.dirlist_sorting.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.dirlists_caching:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	mov $TRUE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.dirlists_caching.0
	orw $1024, (fls)
	jmp .parse_cfg.opts
.parse_cfg.dirlists_caching.0:
	mov $FALSE, %rsi
	call streq
	cmpb $0, %al
	je .parse_cfg.dirlists_caching.1
	andw $~1024, (fls)
	jmp .parse_cfg.opts
.parse_cfg.dirlists_caching.1:
	mov -24(%rbp), %rsi
	mov %rsp, %rdi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.cache_dir:
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getval
	mov %rax, %rsp
	mov %rsp, %rdi
	call strlen
	lea 1(%rax), %rdx
	mov %rsp, %rsi
	mov $pathesb, %rdi
	add (patheso), %rdi
	call memcpy
	mov %rdi, %rax
	mov $cache, %rdi
	stosq
	add %rdx, (patheso)
	jmp .parse_cfg.opts

parse_args:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp
	mov (argc), %rax
	movl %eax, -4(%rbp)
.parse_args.0:
	cmpl $1, -4(%rbp)
	ja .parse_args.1
	jmp .parse_args.ret
.parse_args.1:
	decl -4(%rbp)
	movl -4(%rbp), %esi
	mov (args), %rdi
	call getstrbyidx
	mov %rax, %rdi
	mov %rax, -12(%rbp)
	mov $0x3D, %sil
	call offt_to_delim
	lea 1(%rax), %rdx
	movl %eax, -16(%rbp)
	neg %rax
	lea -18(%rbp, %rax), %rsp
	movb $0, -17(%rbp)
	mov -12(%rbp), %rsi
	mov %rsp, %rdi
	call memcpy
	mov $ARGS, %rsi
	mov $8, %rdx
	call strinstrs
	cmp $0, %rax
	je .parse_args.cfg
	cmp $1, %rax
	je .parse_args.usage
	cmp $2, %rax
	je .parse_args.port
	cmp $3, %rax
	je .parse_args.host_addr
	cmp $4, %rax
	je .parse_args.root
	cmp $5, %rax
	je .parse_args.daemonize
	cmp $6, %rax
	je .parse_args.daemonize	
	cmp $7, %rax
	je .parse_args.usage
	mov $ERR_unknown_arg, %rdi
	call .perror.print
	mov %rsp, %rdi
	call .perror.print
	mov (stderr), %rdi
	mov $ERR_unknown_arg, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	jmp .parse_args.0
.parse_args.ret:
	leave
	ret
.parse_args.cfg:
	mov -12(%rbp), %rax
	mov $1, %rbx
	addl -16(%rbp), %ebx
	add %rbx, %rax
	mov %rax, (cfgpath)
	jmp .parse_args.0
.parse_args.usage:
	mov $USAGE, %rsi
	mov (stdout), %rdi
	call bsndstr
	mov (args), %rsi
	call bsndstr
	mov $USAGE, %rsi
	mov $1, %edx
	call bsndstrbyidx
	call sbuffflush
	xor %rdi, %rdi
	jmp exit
	jmp .parse_args.0
.parse_args.port:
	orb $1, (fls)
	mov -12(%rbp), %rax
	mov $1, %rbx
	addl -16(%rbp), %ebx
	add %rbx, %rax
	mov %rax, %rdi
	xor %rsi, %rsi
	call strtou
	movw %ax, (port)
	jmp .parse_args.0
.parse_args.host_addr:
	orb $2, (fls)
	mov -12(%rbp), %rax
	mov $1, %rbx
	addl -16(%rbp), %ebx
	add %rbx, %rax
	mov %rax, %rdi
	call inet_addr
	movl %eax, (saddr)
	jmp .parse_args.0
.parse_args.root:
	orb $4, (fls)
	mov -12(%rbp), %rax
	mov $1, %rbx
	addl -16(%rbp), %ebx
	add %rbx, %rax
	mov %rax, (serv_root)
	jmp .parse_args.0
.parse_args.daemonize:
	orb $16, (fls)
	jmp .parse_args.0

_start:
	mov %rsp, %rbp

	mov (%rbp), %rax
	mov %rax, (argc)
	mov 8(%rbp), %rax
	mov %rax, (args)

	sub $32, %rsp
	mov $2, %rdi
	call sbuffattach
	mov %rax, (stderr)
	mov $1, %rdi
	call sbuffattach
	mov %rax, (stdout)

	call parse_args
	call parse_cfg

	mov (mtypes), %rdi
	call loadmtypes
	cmp $-1, %rax
	jg ._start.0
	mov $5, %rdi
	mov $0, %sil
	mov (mtypes), %rdx
	call perror
._start.0:
	mov %rax, (mtypesp)
	testw $1024, (fls)
	jz ._start.2
	mov (cache), %rdi
	mov $65536, %rsi
	mov $2, %rax
	syscall
	cmp $0, %rax
	jg ._start.1
	mov $5, %rdi
	mov $0, %sil
	mov (cache), %rdx
	call perror
._start.1:
	movsx %eax, %rdi
	mov $caches_struct, %rsi
	call loadcaches
	cmp $-1, %rax
	jg ._start.2
	mov $6, %rdi
	mov $0, %sil
	mov (cache), %rdx
	call perror
._start.2:

	testb $16, (fls)
	jz _start.ndaemonize
	mov $57, %rax
	syscall
	xor %rdi, %rdi
	cmp $0, %al
	jne exit
	mov $112, %rax
	syscall
	mov (stdout), %rdi
	call sbuffclose
	mov (stderr), %rdi
	call sbuffclose
_start.ndaemonize:
	mov $2, %rax
	mov (serv_root), %rdi
	mov $65536, %rsi
	syscall
	cmp $0, %rax
	jl ._start.sroot.err
	mov %eax, (fsroot)

	mov $41, %rax
	mov $2, %rdi
	mov $1, %rsi
	xor %rdx, %rdx
	syscall

	movl %eax, -4(%rbp)

	mov $54, %rax
	movl -4(%rbp), %edi
	mov $1, %rsi
	mov $15, %rdx
	movl $0, -8(%rbp)
	lea -8(%rbp), %r10
	mov $4, %r8
	syscall

	cmp $-1, %rax
	jle ._start.setsock_err

	movw (port), %di
	sub $8, %rsp
	call htons
	movw $2, -24(%rbp)
	movw %ax, -22(%rbp)
	movl (saddr), %eax
	movl %eax, -20(%rbp)

	mov $49, %rax
	movl -4(%rbp), %edi
	lea -24(%rbp), %rsi
	mov $16, %rdx
	syscall

	cmp $-1, %rax
	jle ._start.bind_err

	mov $50, %rax
	movl -4(%rbp), %edi
	mov $5, %rsi
	syscall

	cmp $-1, %rax
	jg ._start.listen_pass
._start.listen_err:
	mov $3, %rdi
	call perror
._start.listen_pass:
	mov $43, %rax
	movl -4(%rbp), %edi
	movq $0, -24(%rbp)
	movq $0, -16(%rbp)
	lea -24(%rbp), %rsi
	movq $16, -32(%rbp)
	lea -32(%rbp), %rdx
	syscall

	cmp $-1, %rax
	jg ._start.accept_pass
._start.accept_err:
	mov $4, %rax
	call perror
._start.accept_pass:
	mov %rax, %rsi
	mov $client_thr, %rdi
	call new_thr
	jmp ._start.listen_pass

	mov %rbp, %rsp
	xor %rdi, %rdi
	jmp exit

._start.setsock_err:
	mov $1, %rdi
	jmp perror
._start.bind_err:
	mov $2, %rdi
	jmp perror
._start.sroot.err:
	mov $5, %rdi
	xor %rsi, %rsi
	mov (serv_root), %rdx
	jmp perror

perror:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp
	cmp $1, %rdi
	je .perror.setsock
	cmp $2, %rdi
	je .perror.bind
	cmp $3, %rdi
	je .perror.listen
	cmp $4, %rdi
	je .perror.accept
	cmp $5, %rdi
	je .perror.open
	cmp $6, %rdi
	je .perror.caches
	jmp .perror.Ni
.perror.Ni:
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_NI, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.setsock:
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_setsock, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.bind:
	push %rax
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_bind, %rdi
	call .perror.print
	pop %rax
	cmp $-13, %rax
	je .perror.eacces
	cmp $-98, %rax
	je .perror.bind.addrinuse
	cmp $-99, %rax
	je .perror.bind.addrnotavail
	jmp .perror.eoth
.perror.eacces:
	mov $ERR_EACCES, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.bind.addrinuse:
	mov $ERR_EADDRINUSE, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.bind.addrnotavail:
	mov $ERR_EADDRNOTAVAIL, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.eoth:
	mov $ERR_NI, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.listen:
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_listen, %rdi
	call .perror.fprint
	leave
	ret
.perror.accept:
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_accept, %rdi
	call .perror.fprint
	leave
	ret
.perror.open:
	movb %sil, -1(%rbp)
	mov %rdx, -9(%rbp)
	mov $ERR_ERR, %rdi
	push %rax
	call .perror.print
	mov $ERR_open, %rdi
	call .perror.print
	mov -9(%rbp), %rdi
	call .perror.print
	mov $1, %rsi
	mov $ERR_open, %rdi
	call getstrbyidx
	mov %rax, %rdi
	call .perror.print
	pop %rax
	cmp $-2, %rax
	je .perror.open.enoent
	cmp $-13, %rax
	je .perror.eacces
	cmp $-20, %rax
	je .perror.open.enotdir
	cmp $-21, %rax
	je .perror.open.eisdir
	jmp .perror.eoth
.perror.open.enoent:
	mov $ERR_ENOENT, %rdi
	call .perror.fprint
	cmpb $0, -1(%rbp)
	je .perror.exit
	leave
	ret
.perror.open.enotdir:
	mov $ERR_ENOTDIR, %rdi
	call .perror.fprint
	cmpb $0, -1(%rbp)
	je .perror.exit
	leave
	ret
.perror.open.eisdir:
	mov $ERR_ISDIR, %rdi
	call .perror.fprint
	cmpb $0, -1(%rbp)
	je .perror.exit
	leave
	ret
.perror.fprint:
	call .perror.print
	mov (stderr), %rdi
	call sbuffflush
	ret
.perror.print:
	mov %rdi, %rsi
	call strlen
	mov %rax, %rdx
	mov (stderr), %rdi
	call sbuffwrite
	ret
.perror.caches:
	mov %rdx, -8(%rbp)
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_cache, %rdi
	call .perror.print
	mov -8(%rbp), %rdi
	call .perror.print
	mov $ERR_cache, %rdi
	mov $1, %esi
	call getstrbyidx
	mov %rax, %rdi
	call .perror.fprint
.perror.exit:
	mov $1, %rdi
	jmp _exit

exit:
	mov $60, %rax
	syscall

.bss
	.comm pathesb, 32767

.data

	argc: .quad 0
	args: .quad 0
	fls: .byte 136, 7
#	[arg] port = 0 << 0
#	[arg] serv addr = 0 << 1
#	[arg] root = 0 << 2
#	[cfg] ddir_files = 1 << 3
#	[arg] daemon_fl = 0 << 4
#	[cfg] do_custom_404 = 0 << 5
#	[cfg] do_custom_403 = 0 << 6
#	[cfg] do_dirlist = 1 << 7
#   [cfg] show_hidden_files = 1 << 8
#   [cfg] dirlist_sorting = 1 << 9
#   [cfg] dirlists_caching = 1 << 10

	stdout: .quad 0
	stderr: .quad 0
	patheso: .quad 0

	timeout: .quad 90000
	mpermission: .long 04
	port: .word 80
	saddr: .long 0
	fsroot: .long 0
	caches_struct: .quad 0
	cfgpath: .quad dcfgpath
	serv_root: .quad dserv_root
	p404path: .quad d404path
	p403path: .quad d403path
	mtypes: .quad dmtypes
	cache: .quad dcache
	mtypesp: .quad 0

	dcache: .asciz ".cache"
	dmtypes: .asciz "mime.types"
	d403path: .asciz "pages/403.html"
	d404path: .asciz "pages/404.html"
	dserv_root: .asciz "."
	ddir_filep: .quad ddir_file
	ddir_file: .asciz "index.html"
	dirlistp:
		.ascii "<html><head>\n"
		.ascii "<meta charset=\"UTF-8\">\n"
		.ascii "<title>Index of /\0</title>\n"
		.asciz "</head>\n<body><h1>Index of /\0</h1>"
	d400p:
		.ascii "<html><head>\n"
		.ascii "<title>400 Bad request</title>\n"
		.ascii "</head>\n"
		.ascii "<body><h1 style=\"text-align: center\">Bad request</h1>\n"
		.asciz "<p style=\"text-align: center\">\0HTTP version is not same."
		.asciz "HTTP method is not supported, allowed or implemented."
		.asciz "</p><hr>\n</body></html>\n"
	d403p:
		.ascii "<html><head>\n"
		.ascii "<meta charset=\"UTF-8\">\n"
		.ascii "<title>403 Forbidden</title>"
		.ascii "</head>\n"
		.ascii "<body><h1>Forbidden</h1>\n"
		.ascii "<p>You don't have permission to access this resource: `/\0'</p><hr>\n"
		.asciz "</body></html>\n"
	d404p:
		.ascii "<html><head>\n"
		.ascii "<meta charset=\"UTF-8\">\n"
		.ascii "<title>404 Not Found</title>"
		.ascii "</head>\n"
		.ascii "<body><h1>Not Found</h1>\n"
		.ascii "<p>The requested URL /\0 was not found on this server.</p><hr>\n"
		.asciz "</body></html>\n"
	resp:
		.asciz "HTTP/1.1 \0\r\n"
		.asciz "Content-Length: \0\r\n"
		.asciz "Content-Range: bytes \0\r\n"
		.asciz "Content-Type: \0\r\n"
		.asciz "Connection: close\r\n\r\n"
	resp_m:
		.asciz "200 OK"
		.asciz "404 Not Found"
		.asciz "403 Forbidden"
		.asciz "400 Bad Request"
		.asciz "408 Request Timeout"
		.asciz "206 Partial Content"
		.asciz "416 Range Not Satisfiable"
	types:
		.asciz "text/html"
		.asciz "multipart/byteranges; boundary=STR_SEP"
		.asciz "application/octet-stream"
	strsep: .asciz "STR_SEP"
	ddash: .asciz "--"

	dcfgpath: .asciz "config"
	ERR_ERR: .asciz "ERROR: "
	ERR_NI: .asciz "Not implemented yet.\n"
	ERR_setsock: .asciz "Cannot to setsockopt.\n"
	ERR_bind: .asciz "Cannot bind: "
	ERR_open: .asciz "Cannot open `\0': "
	ERR_ENOENT: .asciz "File or directory does not exist.\n"
	ERR_EADDRINUSE:	.asciz "Address in use.\n"
	ERR_EADDRNOTAVAIL: .asciz "Interface does not exist, check your host_addr option.\n"
	ERR_EACCES:	.asciz "Not enough permission.\n"
	ERR_listen:	.asciz "Cannot listen.\n"
	ERR_accept:	.asciz "Cannot accept.\n"
	ERR_ENOTDIR: .asciz "Not a directory.\n"
	ERR_ISDIR: .asciz "Not a regular file.\n"
	ERR_unexp_word: .asciz ":\0 Unexpected word: `\0'.\n"
	ERR_unknown_arg: .asciz "Unknown argument: `\0'.\n"
	ERR_cache: .asciz "Cannot load cache files from directory `\0'. Make sure that the directory does not have any extrinsic files or directories.\n"

	ARGS:
		.asciz "--config="
		.asciz "--help"
		.asciz "--port="
		.asciz "--host_addr="
		.asciz "--root="
		.asciz "-d"
		.asciz "--daemonize"
		.asciz "-h"

	CFG_KEYWORDS:
		.asciz "port="
		.asciz "host_addr="
		.asciz "root="
		.asciz "ddir_file="
		.asciz "do_ddir_files="
		.asciz "do_custom_404="
		.asciz "404_path="
		.asciz "do_custom_403="
		.asciz "403_path="
		.asciz "min_permission="
		.asciz "timeout="
		.asciz "do_dirlist="
		.asciz "mimetypes_path="
		.asciz "show_hidden_files="
		.asciz "dirlist_sorting="
		.asciz "dirlists_caching="
		.asciz "caches_dir="

	HTTP_M: .asciz "GET"
	HTTPV:  .asciz "HTTP/1.1"

	TRUE: .asciz "true"
	FALSE: .asciz "false"

	USAGE:
		.ascii "Usage: \0 [<args>]\n"
		.ascii "  Arguments:\n"
		.ascii "    -d | --daemonize       Daemonize the server.\n"
		.ascii "    --root=<srv root dir>  The directory will used as the server root directory.\n"
		.ascii "    --config=<cfg file>    Path to the server config file.\n"
		.ascii "    --port=<srv bind port> The server port to bind instead of the config port option.\n"
		.ascii "    --host_addr=<ip>       Network interface to bind instead of the config option.\n"
		.asciz "    -h | --help            Prints this message.\n"
