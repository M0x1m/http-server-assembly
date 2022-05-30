# Requiremets for this file:
# 1. getstrbyidx
# 2. memcpy
# 3. strlen
# 4. strlenbyidx

# struct linux_dirent64 {
#	ino64_t        d_ino;    /* 64-bit inode number */
#	off64_t        d_off;    /* 64-bit offset to next structure */
#	unsigned short d_reclen; /* Size of this dirent */
#	unsigned char  d_type;   /* File type */
#	char 		   d_name[]; /* Filename (null-terminated) */
# };

# struct dirent{
#	uint32_t dirfd; // file descriptor of listed directory
#	uint16_t size;  // size of this structure
#	uint16_t offt;  // offset to current element in el
#	struct linux_dirent64 el[];
# };

.text

.globl dirread
.globl dirclose
.globl diropen
.globl fdiropen
.globl genpage
.globl _chkappend
.extern getstrbyidx
.extern memcpy
.extern strlen
.extern strlenbyidx

_chkappend:
# Extends mapped memory if not enough space for write
# rdi - start addr ptr
# rsi - curr addr ptr
# rdx - curr length ptr
# r10 - pending data len to write
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	mov %r10, -32(%rbp)
	sub $40, %rsp
	mov (%rsi), %rsi
	sub (%rdi), %rsi
	mov %rsi, -40(%rbp)
	mov (%rdx), %rdi
	add %r10, %rsi
	cmp %rdi, %rsi
	jb _procret
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	mov -24(%rbp), %rsi
	mov (%rsi), %rsi
	lea 65536(%rsi), %rdx
	mov $1, %r10
	mov $25, %rax
	syscall
	mov -8(%rbp), %rdi
	stosq
	mov -24(%rbp), %rdi
	addq $65536, (%rdi)
	mov -16(%rbp), %rdi
	mov -8(%rbp), %rsi
	movsq
	mov -40(%rbp), %rax
	mov -16(%rbp), %rdi
	add %rax, (%rdi)
	jmp _procret

_procret:
	mov %rbp, %rsp
	pop %rbp
	ret

genpage:
# Generates html page from directory content
# rdi - struct dirent ptr
# rsi - long* mapped size
# ret rax - page ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -40(%rbp)
	sub $40, %rsp
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	mov %rax, -16(%rbp)
	mov %rax, -24(%rbp)
	movq $65536, -32(%rbp)
	mov $.genpage.s0, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	add %rdx, -16(%rbp)
.genpage.2:
	mov -8(%rbp), %rdi
	call dirread
	cmp $0, %rax
	jle .genpage.1
	cmpw $46, 19(%rax)
	je .genpage.2
.genpage.0:
	push %rax
	mov $.genpage.s1, %rdi
	call strlen
	push %rax
	lea 1(%rax), %r10
	mov $1, %esi
	call strlenbyidx
	add %rax, %r10
	mov 8(%rsp), %rdi
	add $19, %rdi
	call strlen
	add %rax, %rax
	add %rax, %r10
	cmpb $4, -1(%rdi)
	je .genpage.7
	cmpb $10, -1(%rdi)
	je .genpage.7
	jmp .genpage.4
.genpage.7:
	add $2, %r10
.genpage.4:
	lea -24(%rbp), %rdi
	lea -16(%rbp), %rsi
	lea -32(%rbp), %rdx
	call _chkappend
	pop %rdx
	mov $.genpage.s1, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	add %rdx, -16(%rbp)
	mov (%rsp), %rax
	lea 19(%rax), %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	add %rdx, -16(%rbp)
	mov (%rsp), %rax
	mov -16(%rbp), %rdi
	cmpb $4, 18(%rax)
	je .genpage.6
	cmpb $10, 18(%rax)
	je .genpage.6
	jmp .genpage.5
.genpage.6:
	movb $47, (%rdi)
	incq -16(%rbp)
	inc %rdi	
.genpage.5:
	movb $62, (%rdi)
	incq -16(%rbp)
	mov (%rsp), %rax
	lea 19(%rax), %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	add %rdx, -16(%rbp)
	pop %rax
	cmpb $4, 18(%rax)
	jne .genpage.3
	mov -16(%rbp), %rdi
	movb $47, (%rdi)
	incq -16(%rbp)
.genpage.3:
	mov $.genpage.s1, %rdi
	mov $1, %esi
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	add %rdx, -16(%rbp)
	jmp .genpage.2
.genpage.1:
	mov $.genpage.s2, %rdi
	call strlen
	push %rax
	mov %rax, %r10
	lea -24(%rbp), %rdi
	lea -16(%rbp), %rsi
	lea -32(%rbp), %rdx
	call _chkappend
	pop %rdx
	mov $.genpage.s2, %rsi
	mov -16(%rbp), %rdi
	call memcpy
	mov -40(%rbp), %rdi
	mov -32(%rbp), %rax
	stosq
	mov -24(%rbp), %rax
	jmp _procret
.data
.genpage.s0: .asciz "<hr><pre>\n"
.genpage.s1: .asciz "<a href=\0</a>\n"
.genpage.s2: .asciz "</pre><hr>\n</html>\n"
.text

dirread:
# rdi - dirent struct ptr
# ret rax - linux_dirent64 struct ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	movzxw 6(%rdi), %rbx
	cmp %bx, 4(%rdi)
	jbe .dirread.dirl
.dirread.0:
	lea 8(%rdi, %rbx), %rax
	mov 16(%rax), %bx
	add %bx, 6(%rdi)
	jmp _procret
.dirread.dirl:
	lea 8(%rdi), %rsi
	movsxd (%rdi), %rdi
	mov $65528, %rdx
	mov $217, %rax
	syscall
	cmp $0, %rax
	jle _procret
	mov -8(%rbp), %rdi
	mov %ax, 4(%rdi)
	movw $0, 6(%rdi)
	xor %rbx, %rbx
	jmp .dirread.0

dirclose:
# rdi - dirent struct
	push %rdi
	movsxd (%rdi), %rdi
	mov $3, %rax
	syscall
	pop %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	ret

fdiropen:
# rdi - dirfd
# ret rax - dirent struct
	push %rbp
	mov %rsp, %rbp
	mov %edi, %eax
	jmp .diropen.0

diropen:
# rdi - dirname
# ret rax - dirent struct
	push %rbp
	mov %rsp, %rbp
	mov $65536, %rsi
	mov $2, %rax
	syscall
	cmp $-1, %rax
	jle _procret
.diropen.0:
	sub $4, %rsp
	mov %eax, -4(%rbp)
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	sub $8, %rsp
	mov %rax, -12(%rbp)
	mov -4(%rbp), %ebx
	mov %ebx, (%rax)
	movsx %ebx, %rdi
	mov -12(%rbp), %rsi
	add $8, %rsi
	mov $65528, %rdx
	mov $217, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	mov -12(%rbp), %rbx
	mov %ax, 4(%rbx)
	movw $0, 6(%rbx)
	mov -12(%rbp), %rax
	jmp _procret
