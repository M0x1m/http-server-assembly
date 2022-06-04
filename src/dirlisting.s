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
#	uint32_t dirfd;  // file descriptor of listed directory
#	uint32_t map_sz; // mapped memory size for this structure
#	uint32_t size;   // size of el structures
#	uint32_t offt;   // offset to current element in el
#	struct linux_dirent64 el[];
# };

.text

.globl dirread
.globl dirclose
.globl diropen
.globl fdiropen
.globl genpage
.globl _chkappend
.globl sortdir
.globl dirfload
.extern getstrbyidx
.extern memcpy
.extern strlen
.extern strlenbyidx

memcpy8:
# Copies buffers with modulo 8
# rdi - destination ptr
# rsi - source ptr
# rdx - size % 8 = 0
	mov %rdi, %rax
	mov %rdx, %rcx
.memcpy8:
	movsq
	sub $8, %rcx
	cmp $0, %rcx
	jg .memcpy8
	mov %rax, %rdi
	ret

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

dirfload:
# Load all directory items into memory
# rdi - ptr to ptr to struct dirent
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
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
	sub $16, %rsp
	mov %rax, -16(%rbp)
.dirfload.1:
	mov -16(%rbp), %rsi
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	movsxd (%rdi), %rdi
	mov $65536, %rdx
	mov $217, %rax
	syscall
	cmp $0, %rax
	je .dirfload.0
	mov %rax, %r10
	push %r10
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	movsxd 4(%rdi), %rax 
	mov %rax, -24(%rbp)
	movsxd 8(%rdi), %rax
	lea 16(%rdi, %rax), %rsi
	push %rsi
	mov %rsp, %rsi
	lea -24(%rbp), %rdx
	mov -8(%rbp), %rdi
	call _chkappend
	add $8, %rsp
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	mov -24(%rbp), %rax
	mov %eax, 4(%rdi)
	movsxd 8(%rdi), %rax
	mov -16(%rbp), %rsi
	lea 16(%rdi, %rax), %rdi
	mov (%rsp), %rdx
	call memcpy
	pop %rax
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	add %eax, 8(%rdi)
	jmp .dirfload.1
.dirfload.0:
	mov -16(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	jmp _procret

sortdir:
# Sorts dirent by file names
# rdi - ptr to struct dirent
	push %rbp
	mov %rsp, %rbp
	sub $24, %rsp
	mov %rdi, -8(%rbp)
	call cntel
	lea -1(%rax), %rsi
	mov %esi, -24(%rbp)
	mov -8(%rbp), %rdi
	call direl
	sub %rdi, %rax
	sub $16, %eax
	mov %eax, -12(%rbp)
	movl $0, -20(%rbp)
	movl $0, -16(%rbp)
.sortdir.0:
	mov -8(%rbp), %rdi
	movsxd -20(%rbp), %rsi
	lea 16(%rdi, %rsi), %rax
	lea 19(%rax), %rdi
	movzxw 16(%rax), %rbx
	lea 19(%rax, %rbx), %rsi
	movsxd -16(%rbp), %rbx
	add %rbx, %rdi
	add %rbx, %rsi
	cmpsb
	je .sortdir.4
	ja .sortdir.2
	mov %rax, %rdi
	call swap_struct
	jmp .sortdir.2
.sortdir.4:
	incl -16(%rbp)
	jmp .sortdir.0
.sortdir.2:
	movl $0, -16(%rbp)
	mov -8(%rbp), %rdi
	movsxd -20(%rbp), %rax
	movzxw 32(%rdi, %rax), %eax
	add %eax, -20(%rbp)
	movsxd -12(%rbp), %eax
	cmp %eax, -20(%rbp)
	jb .sortdir.0
.sortdir.1:
	movl $0, -20(%rbp)
	decl -24(%rbp)
	movsxd -24(%rbp), %rsi
	mov -8(%rbp), %rdi
	call direl
	movzxw 16(%rax), %eax
	sub %eax, -12(%rbp)
	cmpl $0, -12(%rbp)
	je _procret
	jmp .sortdir.0

direl:
# Returns pointer to struct linux_dirent64 by index
# rdi - dirent struct
# rsi - idx
# ret rax - struct linux_dirent64 ptr
	lea 16(%rdi), %rax
	mov %rsi, %rcx
	cmp $0, %rcx
	ja .direl
	ret
.direl:
	movzxw 16(%rax), %rbx
	add %rbx, %rax
	loop .direl
	ret

cntel:
# Counts number of elements in loaded directory
# rdi - struct dirent
# ret rax - number of elements
	push %rbp
	mov %rsp, %rbp
	mov 8(%rdi), %eax
	mov %eax, -4(%rbp)
	movl $0, -12(%rbp)
	movl $1, -16(%rbp)
	add $16, %rdi
.cntel.0:
	movzxw 16(%rdi), %rax
	add %rax, %rdi
	add %eax, -12(%rbp)
	incl -16(%rbp)
	mov -4(%rbp), %eax
	cmpl %eax, -12(%rbp)
	jb .cntel.0
	movsxd -16(%rbp), %rax
	jmp _procret

swap_struct: # only for struct linux_dirent64
# Swaps rdi struct with next
# rdi - struct linux_dirent64*
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	movzxw 16(%rdi), %rdx
	sub %rdx, %rsp
	mov %rsp, %rdi
	mov -8(%rbp), %rsi
	call memcpy8
	mov -8(%rbp), %rdi
	mov %rdi, %rsi
	movzxw 16(%rsi), %rax
	add %rax, %rsi
	movzxw 16(%rsi), %rdx
	call memcpy8
	mov -8(%rbp), %rdi
	movzxw 16(%rdi), %rax
	add %rax, %rdi
	mov %rsp, %rsi
	movzxw 16(%rsi), %rdx
	call memcpy8
	jmp _procret

genpage:
# Generates html page from directory content
# rdi - struct dirent ptr
# rsi - long* mapped size(writes number of mapped bytes for page)
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
	cmpw $11822, 19(%rax)
	je .genpage.0
	cmpb $46, 19(%rax)
	jne .genpage.0
	testw $256, (fls)
	jz .genpage.2
.genpage.0:
	push %rax
	mov $.genpage.s1, %rdi
	call strlen
	push %rax
	lea 2(%rax), %r10
	mov $1, %esi
	call strlenbyidx
	add %rax, %r10
	mov 8(%rsp), %rdi
	add $19, %rdi
	call strlen
	add %rax, %rax
	add %rax, %r10
	cmpb $10, -1(%rdi)
	jne .genpage.6
	push %r10
	push %rdi
	mov %rdi, %rsi
	mov -8(%rbp), %rdi
	movsxd (%rdi), %rdi
	sub $144, %rsp
	mov %rsp, %rdx
	xor %r10, %r10
	mov $262, %rax
	syscall
	mov 24(%rsp), %eax
	add $144, %rsp
	and $0170000, %eax
	cmp $0040000, %eax
	jne .genpage.7
	mov (%rsp), %rdi
	movb $4, -1(%rdi)
.genpage.7:
	pop %rdi
	pop %r10
.genpage.6:
	cmpb $4, -1(%rdi)
	jne .genpage.4
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
	jne .genpage.5
	movb $47, (%rdi)
	incq -16(%rbp)
	inc %rdi	
.genpage.5:
	movw $15906, (%rdi)
	addq $2, -16(%rbp)
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
.genpage.s1: .asciz "<a href=\"./\0</a>\n"
.genpage.s2: .asciz "</pre><hr>\n</html>\n"
.text

dirread:
# rdi - dirent struct ptr
# ret rax - linux_dirent64 struct ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	movsxd 12(%rdi), %rbx
	cmp %ebx, 8(%rdi)
	jbe .dirread.dirl
.dirread.0:
	lea 16(%rdi, %rbx), %rax
	movzxw 16(%rax), %ebx
	add %ebx, 12(%rdi)
	jmp _procret
.dirread.dirl:
	lea 16(%rdi), %rsi
	movsxd (%rdi), %rdi
	mov $65520, %rdx
	mov $217, %rax
	syscall
	cmp $0, %rax
	jle _procret
	mov -8(%rbp), %rdi
	mov %eax, 8(%rdi)
	movl $0, 12(%rdi)
	xor %rbx, %rbx
	jmp .dirread.0

dirclose:
# rdi - dirent struct
	push %rdi
	movsxd (%rdi), %rdi
	mov $3, %rax
	syscall
	pop %rdi
	movsxd 4(%rdi), %rsi
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
	movl $65536, 4(%rax)
	movsx %ebx, %rdi
	mov -12(%rbp), %rsi
	add $16, %rsi
	mov $65520, %rdx
	mov $217, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	mov -12(%rbp), %rbx
	mov %eax, 8(%rbx)
	movl $0, 12(%rbx)
	mov -12(%rbp), %rax
	jmp _procret
