# struct linux_dirent64 {
#	ino64_t		   d_ino;	  /* 64-bit inode number */
#	off64_t		   d_off;     /* 64-bit offset to next structure */
#	unsigned short d_reclen;  /* Size of this dirent */
#	unsigned char  d_type;    /* File type */
#	char		   d_name[];  /* Filename (null-terminated) */
# };

# struct dirent{
#	uint32_t dirfd;  // file descriptor of listed directory
#	uint32_t map_sz; // mapped memory size for this structure
#	uint32_t size;   // size of el structures
#	uint32_t offt;   // offset to current element in el
#	struct linux_dirent64 el[];
# };

# Cache file format:
# NULL-terminated full path of cached directory list
# 8-byte timestamp modification time of the directory
# Saved part of page(generated by genpage)

.text

.globl dirread
.globl dirclose
.globl diropen
.globl fdiropen
.globl genpage
.globl _chkappend
.globl sortdir
.globl dirfload
.globl mkcache
.globl loadcaches
.globl lookforcache
.globl updcache
.globl delcache

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

abspath:
# rdi - root fd
# rsi - file path
# rdx - char buffer[4096]
# ret rax - rdx
	push %rbp
	mov %rsp, %rbp
	mov %rsi, -12(%rbp)
	mov %rdx, -20(%rbp)
	movq $0, -28(%rbp)
	sub $28, %rsp
	mov $81, %rax
	syscall
	mov -12(%rbp), %rdi
	call strlen
	cmp $0, %rax
	je .abspath.2
	mov %rsi, %rdi
	mov $80, %rax
	syscall
	cmp $0, %rax
	je .abspath.2
	mov -20(%rbp), %rdi
	mov $4096, %rsi
	mov $79, %rax
	syscall
	mov %eax, -24(%rbp)
	cmpb $47, -2(%rdi, %rax)
	je .abspath
	movw $47, -1(%rdi, %rax)
.abspath:
	decl -24(%rbp)
.abspath.3:
	mov -12(%rbp), %rdi
	call strlen
	mov %eax, -28(%rbp)
.abspath.1:
	movsxd -28(%rbp), %rax
	cmpb $47, -1(%rdi, %rax)
	jne .abspath.0
	decl -28(%rbp)
	jmp .abspath.1
.abspath.0:
	mov -12(%rbp), %rsi
	movsxd -28(%rbp), %rdx
	movsxd -24(%rbp), %rax
	mov -20(%rbp), %rdi
	add %rax, %rdi
	call memcpy
	movsxd -24(%rbp), %rax
	mov -20(%rbp), %rdi
	add %rax, %rdi
	movsxd -28(%rbp), %rax
	movb $0, 1(%rdi, %rax)
	mov -20(%rbp), %rax
	jmp _procret
.abspath.2:
	mov -20(%rbp), %rdi
	mov $4096, %rsi
	mov $79, %rax
	syscall
	mov -20(%rbp), %rax
	jmp _procret

_chkappend2:
# rdi - start addr ptr
# rsi - curr offt
# rdx - curr length
# r10 - pending data to write
# ret rax - new mapped size of mem
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	sub $32, %rsp
	add (%rdi), %rsi
	mov %rsi, -32(%rbp)
	lea -32(%rbp), %rsi
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rdx
	call _chkappend
	mov -24(%rbp), %rdx
	mov %rdx, %rax
	jmp _procret

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
	leave
	ret

# struct caches{
#	int fd;		   // dirfd of cache directory
#	long cnt;	   // total count of cached directories in cache directory
#	long mscaches; // size of mapped memory for the structure
#	struct names[cnt];
# };

# struct names{
#	char cname[]; // file name of cache NULL-terminated
#	char dname[]; // full name of cached directory NULL-terminated
# };

mkcache:
# creates and writes cache in cache file
# rdi - ptr to ptr caches struct
# rsi - ptr to page
# rdx - timestamp of directory modification
# r10d - dirfd of requested directory
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	mov %r10d, -28(%rbp)
	sub $70, %rsp
	mov -16(%rbp), %rdi
	call strlen
	mov %rax, -40(%rbp)
.mkcache.0:
	call genrandname
	mov %rax, %rsi
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	movsxd (%rdi), %rdi
	mov $65, %rdx
	mov $0644, %r10
	mov $257, %rax
	syscall
	cmp $-17, %rax
	je .mkcache.0
	cmp $-1, %rax
	jle _procret
	mov %rsi, %rsp
	mov %rsi, -48(%rbp)
	mov %eax, -32(%rbp)
	movsxd -28(%rbp), %rdi
	mov $81, %rax
	syscall
	sub $4096, %rsp
	mov %rsp, -56(%rbp)
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -64(%rbp)
	movl $0, -68(%rbp)
	mov -56(%rbp), %rdi
	mov $4096, %rsi
	mov $79, %rax
	syscall
	mov %ax, -70(%rbp)
	mov -64(%rbp), %rdi
	mov -56(%rbp), %rsi
	movzxw -70(%rbp), %rdx
	call memcpy
	add %edx, -68(%rbp)
	mov -64(%rbp), %rdi
	movsxd -68(%rbp), %rbx
	mov -24(%rbp), %rax # original data at -24(%rbp) will never used below
	mov %rax, (%rdi, %rbx)
	addl $8, -68(%rbp)
.mkcache.1:
	mov -40(%rbp), %rdi
	mov $65536, %rsi
	sub -68(%rbp), %esi
	call min
	mov %eax, -24(%rbp)
	mov -64(%rbp), %rdi
	movsxd -68(%rbp), %rax
	add %rax, %rdi
	mov -16(%rbp), %rsi
	movsxd -24(%rbp), %rdx
	call memcpy
	movsxd -24(%rbp), %rax
	add %eax, -68(%rbp)
	add %rax, -16(%rbp)
	sub %rax, -40(%rbp)
	movsxd -32(%rbp), %rdi
	mov -64(%rbp), %rsi
	movsxd -68(%rbp), %rdx
	mov $1, %rax
	syscall
	movl $0, -68(%rbp)
	cmpq $0, -40(%rbp)
	jne .mkcache.1
	mov -64(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	movsxd -32(%rbp), %rdi
	mov $3, %rax
	syscall
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	call getlencache
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	add %rdi, %rax
	mov %rax, -64(%rbp)
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	mov 12(%rdi), %rax
	mov %rax, -24(%rbp)
	mov -8(%rbp), %rdi
	lea -64(%rbp), %rsi
	lea -24(%rbp), %rdx
	movzxw -70(%rbp), %r10
	add $33, %r10
	call _chkappend
	mov -64(%rbp), %rdi
	mov -48(%rbp), %rsi
	mov $33, %rdx
	call memcpy
	addq $33, -64(%rbp)
	mov -64(%rbp), %rdi
	mov -56(%rbp), %rsi
	movzxw -70(%rbp), %rdx
	call memcpy
	mov -8(%rbp), %rdi
	mov (%rdi), %rdi
	mov -24(%rbp), %rax
	mov %rax, 12(%rdi)
	incq 4(%rdi)
	jmp _procret

updcache:
# Updates cache data
# rdi - name of the cache file
# rsi - caches struct
# rdx - page
# r10 - timestamp
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	mov %r10, -32(%rbp)
	sub $56, %rsp
	mov %rdx, %rdi
	call strlen
	mov %rax, -56(%rbp)
	mov -8(%rbp), %rsi
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov $2, %rdx
	mov $257, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	mov %eax, -36(%rbp)
	mov %rax, %r8
	xor %rdi, %rdi
	mov $4096, %rsi
	mov $3, %rdx
	mov $2, %r10
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -44(%rbp)
	mov %rax, %rdi
	call strlen
	lea 1(%rax), %rsi
	movsxd -36(%rbp), %rdi
	mov $77, %rax
	syscall
	xor %rsi, %rsi
	mov $2, %rdx
	mov $8, %rax
	syscall
	mov -44(%rbp), %rdi
	mov $4096, %rsi
	mov $11, %rax
	syscall
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -44(%rbp)
	movl $0, -48(%rbp)
	mov -32(%rbp), %rax
	mov -44(%rbp), %rdi
	stosq
	addl $8, -48(%rbp)
.updcache.0:
	mov $65536, %rdi
	sub -48(%rbp), %edi
	mov -56(%rbp), %rsi
	call min
	mov %rax, %rdx
	mov -44(%rbp), %rdi
	movsxd -48(%rbp), %rax
	add %rax, %rdi
	mov -24(%rbp), %rsi
	call memcpy
	sub %rdx, -56(%rbp)
	add %rdx, -24(%rbp)
	add %edx, -48(%rbp)
	movsxd -48(%rbp), %rdx
	movsxd -36(%rbp), %rdi
	mov -44(%rbp), %rsi
	mov $1, %rax
	syscall
	movl $0, -48(%rbp)
	cmpq $0, -56(%rbp)
	ja .updcache.0
	mov $3, %rax
	movsxd -36(%rbp), %rdi
	syscall
	mov $11, %rax
	mov -44(%rbp), %rdi
	mov $65536, %rsi
	syscall
	jmp _procret

delcache:
# Deletes cache from structure and directory
# rdi - name of cache file
# rsi - caches struct
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	sub $32, %rsp
	call strlen
	inc %rax
	sub %rax, %rsp
	mov %rdi, %rsi
	mov %rsp, %rdi
	mov %rax, %rdx
	call memcpy
	mov %rsp, -32(%rbp)
	mov -16(%rbp), %rdi
	call getlencache
	mov %rax, -24(%rbp)
	mov -8(%rbp), %rdi
	call strlen
	lea 1(%rdi, %rax), %rdi
	call strlen
	lea 1(%rdi, %rax), %rdi
	mov -8(%rbp), %rsi
	mov -16(%rbp), %rdx
	add -24(%rbp), %rdx
	sub %rdi, %rdx
	call memmovp
	mov -16(%rbp), %rax
	decq 4(%rax)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -32(%rbp), %rsi
	xor %rdx, %rdx
	mov $263, %rax
	syscall
	jmp _procret

loadcaches:
# Loads ptr to caches structure into memory pointed in rsi from dirfd
# rdi - dirfd
# rsi - ptr to memory
# ret rax - number of loaded cache files
	push %rbp
	mov %rsp, %rbp
	mov %edi, -4(%rbp)
	mov %rsi, -12(%rbp)
	sub $40, %rsp
	movsxd -4(%rbp), %rdi
	movq $20, -36(%rbp)
	call fdiropen
	mov %rax, -20(%rbp)
	xor %rdi, %rdi
	mov $65536, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -28(%rbp)
	mov -4(%rbp), %ebx
	mov %ebx, (%rax)
	movq $65536, 12(%rax)
.loadcaches.0:
	mov -20(%rbp), %rdi
	call dirread
	cmp $0, %rax
	je .loadcaches.1
	cmpw $46, 19(%rax)
	je .loadcaches.0
	cmpw $11822, 19(%rax)
	je .loadcaches.0
	lea 19(%rax), %rdi
	push %rdi
	call strlen
	lea -28(%rbp), %rdi
	mov -36(%rbp), %rsi
	mov -28(%rbp), %rdx
	mov 12(%rdx), %rdx
	lea 1(%rax), %r10
	push %r10
	call _chkappend2
	mov -28(%rbp), %rdi
	add -36(%rbp), %rdi
	pop %rdx
	mov (%rsp), %rsi
	call memcpy
	add %rdx, -36(%rbp)
	pop %rsi
	movsxd -4(%rbp), %rdi
	xor %rdx, %rdx
	mov $257, %rax
	syscall
	mov %eax, -40(%rbp)
	xor %rdi, %rdi
	mov $4096, %rsi
	mov $1, %rdx
	mov $2, %r10
	movsxd -40(%rbp), %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	cmp $0, %rax
	jl _procret
	push %rax
	movsxd -40(%rbp), %rdi
	mov $3, %rax
	syscall
	mov (%rsp), %rdi
	call strlen
	lea -28(%rbp), %rdi
	mov -36(%rbp), %rsi
	mov -28(%rbp), %rdx
	mov 12(%rdx), %rdx
	lea 1(%rax), %r10
	push %r10
	call _chkappend2
	mov -28(%rbp), %rdi
	mov %rdx, 12(%rdi)
	add -36(%rbp), %rdi
	pop %rdx
	mov (%rsp), %rsi
	call memcpy
	add %rdx, -36(%rbp)
	pop %rdi
	mov $4096, %rsi
	mov $11, %rax
	syscall
	mov -28(%rbp), %rdi
	incq 4(%rdi)
	jmp .loadcaches.0
.loadcaches.1:
	mov -20(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	mov -28(%rbp), %rsi
	mov -12(%rbp), %rdi
	mov %rsi, (%rdi)
	mov 4(%rsi), %rax
	jmp _procret

lookforcache:
# Finds cached directory in caches structure
# rdi - file path
# rsi - caches struct
# rdx - root
# ret rax - name of cache file
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %edx, -36(%rbp)
	movq $0, -24(%rbp)
	movq $20, -32(%rbp)
	sub $36, %rsp
	mov -16(%rbp), %rdi
	cmpq $0, 4(%rdi)
	je .lookforcache.nf
	sub $4096, %rsp
	mov -36(%rbp), %edi
	mov -8(%rbp), %rsi
	mov %rsp, %rdx
	call abspath
	mov %rax, -8(%rbp)
.lookforcache.0:
	mov -16(%rbp), %rdi
	add -32(%rbp), %rdi
	push %rdi
	call strlen
	inc %rax
	add %rax, -32(%rbp)
	lea (%rdi, %rax), %rdi
	call strlen
	inc %rax
	add %rax, -32(%rbp)
	mov -8(%rbp), %rsi
	call streq
	cmp $1, %al
	je .lookforcache.f
	add $8, %rsp
	incq -24(%rbp)
	mov -16(%rbp), %rdi
	mov 4(%rdi), %rax
	cmp %rax, -24(%rbp)
	jb .lookforcache.0
.lookforcache.nf:
	mov $-1, %rax
	jmp _procret
.lookforcache.f:
	pop %rax
	jmp _procret

getlencache:
# rdi - cache ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	movq $20, -16(%rbp)
	movq $0, -24(%rbp)
	sub $24, %rsp
	cmpq $0, 4(%rdi)
	je .getlencache.1
.getlencache:
	mov $2, %rcx
.getlencache.0:
	mov -16(%rbp), %rbx
	mov -8(%rbp), %rax
	lea (%rax, %rbx), %rdi
	call strlen
	inc %rax
	add %rax, -16(%rbp)
	loop .getlencache.0
	incq -24(%rbp)
	mov -8(%rbp), %rax
	mov 4(%rax), %rax
	cmpq %rax, -24(%rbp)
	jb .getlencache
.getlencache.1:
	mov -8(%rbp), %rdi
	mov -16(%rbp), %rax
	jmp _procret

genrandname:
# generates random filename
	push %rbp
	mov %rsp, %rbp
	sub $33, %rsp
	movb $0, 32(%rsp)
	lea -1(%rsp), %rdi
	mov $32, %rsi
	xor %rdx, %rdx
	mov $318, %rax
	syscall
	dec %rsp
	mov $32, %rcx
.genrandname:
	cmpb $47, (%rsp, %rcx)
	ja .genrandname.0
	addb $48, (%rsp, %rcx)
.genrandname.0:
	cmpb $57, (%rsp, %rcx)
	ja .genrandname.1
	jmp .genrandname.e
.genrandname.1:
	cmpb $65, (%rsp, %rcx)
	jb .genrandname.2
	cmpb $91, (%rsp, %rcx)
	jb .genrandname.e
	cmpb $123, (%rsp, %rcx)
	jb .genrandname.3
	subb $122, (%rsp, %rcx)
	jmp .genrandname
.genrandname.3:
	cmpb $96, (%rsp, %rcx)
	ja .genrandname.e
	addb $6, (%rsp, %rcx)
.genrandname.2:
	addb $8, (%rsp, %rcx)
.genrandname.e:
	loop .genrandname
	lea 1(%rsp), %rax
	jmp _procret

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
	jle .dirfload.0
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
	push %rax
	mov -16(%rbp), %rdi
	mov $65536, %rsi
	mov $11, %rax
	syscall
	pop %rax
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
# rdi - server root
# rsi - dirname
# ret rax - dirent struct
	push %rbp
	mov %rsp, %rbp
	mov $65536, %rdx
	mov $257, %rax
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
	jle .diropen.er
	mov -12(%rbp), %rbx
	mov %eax, 8(%rbx)
	movl $0, 12(%rbx)
	mov -12(%rbp), %rax
	jmp _procret
.diropen.er:
	mov $11, %rax
	mov -12(%rbp), %rdi
	mov $65536, %rsi
	syscall
	mov $-1, %rax
	jmp _procret
