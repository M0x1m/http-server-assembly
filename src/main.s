.global _start
.global memcpy
.extern buffopen
.extern buffclose
.extern buffgetc
.extern buffseek
.extern sbuffattach
.extern sbuffgetc
.extern sbuffwrite
.extern sbuffflush 

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
	mov $7, %rdx
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
	xor %rbx, %rbx
	movb -1(%rdi, %rsi), %bl
	subb $0x30, %bl
	push %rax
	movw -8(%rbp), %cx
	subw %si, %cx
	incw %cx
.strtou.4:
	cmpw $0, %cx
	decw %cx
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
	mov %rbp, %rsp
	pop %rbp
	ret

htons:
	mov %rdi, %rax
	shl $8, %rax
	mov $65535, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rdx, %rax
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
	mov %rbp, %rsp
	pop %rbp
	ret

memcpy:
	mov %rdx, %rcx
	mov %rdi, %rax
	rep movsb
	mov %rax, %rdi
	ret

wait_client:
	push %rdi
	movw $0, -14(%rsp)
	jmp .wait_client.1
.wait_client.0:
	cmpl $0, -12(%rsp)
	je .wait_client.2
	cmpw $90, -14(%rsp)
	je .wait_client.2
.wait_client.1:
	mov (%rsp), %rax
	movl %eax, -8(%rsp)
	movw $8216, -4(%rsp)
	movw $0, -2(%rsp)
	mov $7, %rax
	mov $1, %rsi
	mov $1000, %rdx
	lea -8(%rsp), %rdi
	syscall
	testw $8216, -2(%rsp)
	jnz .wait_client.2
	lea -12(%rsp), %rdx
	mov $21521, %rsi
	mov (%rsp), %rdi
	mov $16, %rax
	syscall
	incw -14(%rsp)
	jmp .wait_client.0
.wait_client.2:
	pop %rdi
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
	mov %rbp, %rsp
	pop %rbp
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
	mov $90000, %rsi
	call sbuffgetc
	cmp $-1, %rax
	jle .getcpath.errret
	cmpb $0x20, %al
	je .getcpath.2
	cmpb $0, -9(%rbp)
	je .getcpath.1
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
	movb $0x2F, %sil
	call skip_delim
	call unhexhttp
	mov %rax, %rdi
	jmp .getcpath.fret
.getcpath.errret:
	mov $-1, %rax
.getcpath.fret:
	mov %rbp, %rsp
	pop %rbp
	ret
.getcpath.2:
	cmpb $1, -9(%rbp)
	je .getcpath.ret
	movb $1, -9(%rbp)
	jmp .getcpath.1

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
	call unhexdctob
	mov -16(%rbp), %rcx
	mov -8(%rbp), %rdi
	cmp $0, %rax
	jl .unhexhttp.0
	mov %al, (%rdi, %rcx)
	lea 3(%rdi, %rcx), %rdi
	call strlen
	lea 1(%rax), %rdx
	mov $-2, %rsi
	call memmov
.unhexhttp.2:
	incq -16(%rbp)
	jmp .unhexhttp.0
.unhexhttp.1:
	mov -8(%rbp), %rax
	mov %rbp, %rsp
	pop %rbp
	ret

memmov:
# rdi - ptr
# rsi - offt
# rdx - size
# ret rax - rdi
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
	rep movsb
	cld
	mov -8(%rbp), %rdi
	mov %rbp, %rsp
	pop %rbp
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
	mov %rbp, %rsp
	pop %rbp
	ret

_exit: # group exit
	mov $231, %rax
	syscall

sndfd: # edi -> esi
	push %rbp
	mov %rsp, %rbp
	mov %edi, -148(%rbp)   # edi - sending file
	mov %rsi, -164(%rbp)   # esi - STREAMB pointer to client socket
	sub $164, %rsp
	mov $5, %rax
	lea -144(%rbp), %rsi
	syscall
.sndfd.2:
	cmpq $65536, -96(%rbp)
	ja .sndfd.0
	jb .sndfd.1
.sndfd.0:
	mov $65536, %r10
	subq $65536, -96(%rbp)
	jmp .sndfd.3
.sndfd.1:
	mov -96(%rbp), %r10
	movq $0, -96(%rbp)
.sndfd.3:
	lea -148(%rbp), %rsi
	lea -156(%rbp), %rdi
	movsl
	movw $8216, -152(%rbp)
	movw $0, -150(%rbp)
	lea -156(%rbp), %rdi
	mov $1, %rsi
	xor %rdx, %rdx
	mov $7, %rax
	syscall
	testw $8216, -150(%rbp)
	jnz .sndfd.disconn
	mov $40, %rax
	mov -164(%rbp), %rdi
	mov (%rdi), %edi
	mov -148(%rbp), %rsi
	xor %rdx, %rdx
	syscall
	cmp $0, %rax
	jl .sndfd.disconn
	cmpq $0, -96(%rbp)
	ja .sndfd.2
	xor %rax, %rax
	jmp .sndfd.ret
.sndfd.disconn:
	mov $-1, %rax
.sndfd.ret:
	mov %rbp, %rsp
	pop %rbp
	ret

sigpipe_handler:
	mov -148(%rbp), %edi
	mov $3, %rax
	syscall
	mov -164(%rbp), %rdi
	call sbuffclose
	lea -65287(%rbp), %rdi
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
	mov %rbp, %rsp
	pop %rbp
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
	mov -8(%rbp), %rdi
	mov %rbp, %rsp
	pop %rbp
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
	mov %rbp, %rsp
	pop %rbp
	ret

client_thr:
	push %rbp
	mov %rsp, %rbp

	sub $164, %rsp

	lea -156(%rbp), %rdi
	mov $156, %rdx
	xor %sil, %sil
	call memset

	mov $sigpipe_handler, %rax
	stosq
	mov $thread_exit, %rax
	lea -140(%rbp), %rdi
	stosq
	movq $67108864, -148(%rbp) # 1 << 26 = SA_RESTORER, segfault returns without this flag

	mov $13, %rdi
	lea -156(%rbp), %rsi
	xor %rdx, %rdx
	mov $8, %r10
	mov $13, %rax
	syscall

	mov 8(%rbp), %rdi
	call sbuffattach
	mov %rax, %rdi
	mov %rax, -164(%rbp)
	call getcpath
	cmp $-1, %rax
	jle .client_thr.closeconn
	mov %rax, %rsp
	mov %rsp, %rdi
	call strlen
	cmp $0, %rax
	je .client_thr.root_dir
	mov %rdi, -156(%rbp) 		# requested file name pointer to string saved in -156(%rbp)
	mov %rdi, %rsi
	mov (fsroot), %rdi
	xor %rdx, %rdx
	mov $257, %rax
	syscall
	cmp $-13, %rax
	je .client_thr.403.oer
	cmp $-2, %rax
	je .client_thr.404
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
	jz .client_thr.pfile
	movl -148(%rbp), %edi
	mov (ddir_filep), %rsi
	xor %rdx, %rdx
	mov $257, %rax
	syscall
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
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr
	mov $resp_m, %rsi
	call bsndstr
	mov $resp, %rsi
	mov $1, %edx
	mov -164(%rbp), %rdi
	call bsndstrbyidx

	mov -96(%rbp), %rsi
	mov -164(%rbp), %rdi
	call bsndustr

	mov $resp, %rsi
	mov $2, %edx
	mov -164(%rbp), %rdi
	call bsndstrbyidx
	call sbuffflush
	mov -148(%rbp), %rdi
	mov -164(%rbp), %rsi
	call sndfd
	cmp $-1, %rax
	jle .client_thr.disconn
	mov 8(%rbp), %rdi
	call wait_client
.client_thr.disconn:
	cmpl $0, -148(%rbp)
	je .client_thr.closeconn
	mov $3, %rax
	mov -148(%rbp), %rdi
	syscall

.client_thr.closeconn:
	mov -164(%rbp), %rdi
	call sbuffclose

	lea -65520(%rbp), %rdi
	call thread_exit
.client_thr.root_dir:
	mov (fsroot), %rdi
	mov $32, %rax
	syscall
	movq $0, -156(%rbp)
	jmp .client_thr.200
.client_thr.404:
	testb $32, (fls)
	jnz .client_thr.404.c
	mov -164(%rbp), %rdi
	mov $resp, %rsi
	call bsndstr

	mov -164(%rbp), %rdi
	mov $resp_m, %rsi
	mov $1, %edx
	call bsndstrbyidx
	mov $resp, %rsi
	mov $1, %edx
	mov -164(%rbp), %rdi
	call bsndstrbyidx

	cmpq $0, -156(%rbp)
	jne .client_thr.404.0
	testb $8, (fls)
	jnz .client_thr.404.1
	sub $2, %rsp
	mov %rsp, -156(%rbp)
	mov -156(%rbp), %rdi
	movw $0x2f, %ax
	stosw
	jmp .client_thr.404.0
.client_thr.404.1:
	lea (ddir_filep), %rsi
	lea -156(%rbp), %rdi
	movsq
.client_thr.404.0:
	mov $d404p, %rdi
	mov $2, %rsi
	call strslen
	xor %rsi, %rsi
	mov %rax, %rsi
	mov -156(%rbp), %rdi
	call strlen
	add %rax, %rsi
	mov -164(%rbp), %rdi
	call bsndustr

	mov $resp, %rsi
	mov $2, %edx
	mov -164(%rbp), %rdi
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
	call wait_client
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
	mov -96(%rbp), %rsi
	call bsndustr
	mov $resp, %rsi
	mov $2, %edx
	call bsndstrbyidx
	call sbuffflush
	movl -148(%rbp), %edi
	mov -164(%rbp), %rsi
	call sndfd

	mov 8(%rbp), %rdi
	call wait_client
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
	mov $1, %edx
	call bsndstrbyidx
	
	testb $64, (fls)
	jnz .client_thr.403.c

	mov $d403p, %rdi
	call strlen
	mov %rax, -8(%rbp)
	cmpq $0, -156(%rbp)
	je .client_thr.403.mrp
	mov -156(%rbp), %rdi
	call strlen
	cmp $0, %rax
	je .client_thr.403.mrp
	jmp .client_thr.403.up
.client_thr.403.mrp:
	testb $8, (fls)
	jz .client_thr.403.mkr
	lea (ddir_filep), %rsi
	lea -156(%rbp), %rdi
	movsq
	jmp .client_thr.403.up
.client_thr.403.mkr:
	sub $2, %rsp
	mov %rsp, -156(%rbp)
	mov -156(%rbp), %rdi
	movw $0x2f, %ax
	stosw
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
	mov $2, %edx
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
	mov 8(%rbp), %rdi
	call bsndustr

	mov $2, %edx
	mov $resp, %rsi
	call bsndstrbyidx

	mov -148(%rbp), %edi
	mov 8(%rbp), %rsi
	call sndfd

.client_thr.403.end:
	mov 8(%rbp), %rdi
	call wait_client
	jmp .client_thr.disconn

thread_exit:
	mov $65536, %rsi
	mov $4, %rdx
	mov $28, %rax
	syscall
	xor %rdi, %rdi
	call exit
	ret

skip_delim:
	mov %rdi, %rax
	cmpb %sil, (%rdi)
	je .skip_delim.1
	ret
.skip_delim.1:
	inc %rdi
	jmp skip_delim

getstrbyidx:
	push %rbp
	mov %rsp, %rbp
	movl %esi, -4(%rbp)
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
	mov %rsi, %rax
	mov %rdx, %rcx
	rep stosb
	pop %rdi
	mov %rdi, %rax
	ret

memcmp:
	mov %rdx, %rcx
	cld
	repe cmpsb
	jrcxz .memcmp.e 
	xor %rax, %rax
	ret
.memcmp.e:
	mov $1, %rax
	ret

sndstr:
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	pop %rdi
	mov $1, %rax
	syscall
	ret

sndstrbyidx:
	push %rbp
	mov %rsp, %rbp
	mov %edi, -4(%rbp)
	mov %rsi, -12(%rbp)
	mov %edx, -16(%rbp)
	sub $16, %rsp
	mov -12(%rbp), %rdi
	movl -16(%rbp), %esi
	call getstrbyidx
	mov %rax, %rsi
	mov -4(%rbp), %rdi
	call sndstr
	mov %rbp, %rsp
	pop %rbp
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
	lea 1(%rbx), %rdx
	call memcmp
	ret
.streq.ne:
	pop %rdi
	xor %rax, %rax
	ret

skip_sts:
	push %rbp
	mov %rsp, %rbp
	movb $0, -2(%rbp)
	movl $0, -6(%rbp)
	mov %rsi, -14(%rbp)
	sub $14, %rsp
.skip_sts.0:
	call buffgetc
	mov %al, -1(%rbp)
	cmp $-1, %rax
	jle .skip_sts.ret
	incl -6(%rbp)
	cmpb $1, -2(%rbp)
	je .skip_sts.2	
	cmpb $35, -1(%rbp)
	je .skip_sts.1
	cmpb $0x20, -1(%rbp)
	je .skip_sts.0
	cmpb $10, -1(%rbp)
	je .skip_sts.3
	cmpb $0x9, -1(%rbp)
	je .skip_sts.0
	mov $-1, %rsi
	mov $1, %edx
	call buffseek
.skip_sts.ret:
	mov %rbp, %rsp
	pop %rbp
	ret
.skip_sts.1:
	movb $1, -2(%rbp)
	jmp .skip_sts.0
.skip_sts.2:
	cmpb $10, -1(%rbp)
	jne .skip_sts.0
	movb $0, -2(%rbp)
.skip_sts.3:
	mov -14(%rbp), %rax
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
	mov %rbp, %rsp
	pop %rbp
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
	mov %rbp, %rsp
	pop %rbp
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
	xor %rbx, %rbx
	movb -14(%rbp), %bl
	add %rbx, -8(%rbp)
	incq -8(%rbp)
	xor %rbx, %rbx
	movb -9(%rbp), %bl
	movb %al, -13(%rbp, %rbx)
	incb -9(%rbp)
	cmpb $4, -9(%rbp)
	jb .inet_addr.0
.inet_addr.ret:
	xor %rax, %rax
	movl -13(%rbp), %eax
	mov %rbp, %rsp
	pop %rbp
	ret

getval:
	push %rbp
	mov %rsp, %rbp
	movl $0, -4(%rbp)
	mov %rsi, -12(%rbp)
	sub $12, %rsp
.getval.0:
	call buffgetc
	movl -4(%rbp), %ecx
	neg %rcx
	mov %al, -14(%rbp, %rcx)
	lea -14(%rbp, %rcx), %rsp
	cmp $-1, %rax
	jle .getval.1
	movl -4(%rbp), %ecx
	neg %rcx
	incl -4(%rbp)
	cmpb $35, -14(%rbp, %rcx)
	je .getval.1
	cmpb $0x20, -14(%rbp, %rcx)
	je .getval.1
	cmpb $10, -14(%rbp, %rcx)
	je .getval.2
	cmpb $9, -14(%rbp, %rcx)
	je .getval.1
	jmp .getval.0
.getval.ret:
	mov %rbp, %rsp
	pop %rbp
	ret
.getval.2:
	mov -12(%rbp), %rax
	incq (%rax)
.getval.1:
	movb $0, -13(%rbp)
	lea -13(%rbp, %rcx), %rsp
	lea -13(%rbp, %rcx), %rdi
	neg %rcx
	lea -1(%rcx), %rsi
	call memrev
	mov %rdi, %rax
	jmp .getval.ret

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
	movl -24(%rbp), %eax
.strinstrs.ret:
	mov %rbp, %rsp
	pop %rbp
	ret

parse_cfg:
	push %rbp
	mov %rsp, %rbp
	movq $1, -24(%rbp)
	sub $24, %rsp
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
	mov -8(%rbp), %rdi
	lea -24(%rbp), %rsi
	call getvar
	cmp $0, %rax
	jl .parse_cfg.ret
	mov %rax, %rdi
	mov %rax, -16(%rbp)
	mov %rax, %rsp
	mov $CFG_KEYWORDS, %rsi
	mov $10, %rdx
	call strinstrs
	cmp $0, %ax
	je .parse_cfg.port
	cmp $1, %ax
	je .parse_cfg.addr
	cmp $2, %ax
	je .parse_cfg.root
	cmp $3, %ax
	je .parse_cfg.ddir_file
	cmp $4, %ax
	je .parse_cfg.do_ddir_files
	cmp $5, %ax
	je .parse_cfg.do_custom_404
	cmp $6, %al
	je .parse_cfg.404_path
	cmp $7, %al
	je .parse_cfg.do_custom_403
	cmp $8, %al
	je .parse_cfg.403_path
	cmp $9, %al
	je .parse_cfg.mpermission
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call unexp_word
	jmp .parse_cfg.opts
.parse_cfg.ret:
	mov -8(%rbp), %rdi
	call buffclose
.parse_cfg.errret:
	mov %rbp, %rsp
	pop %rbp
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
	mov %rax, %rdx
	mov %rdi, %rsi
	mov $srootbuf, %rdi
	call memcpy
	mov (serv_root), %rdi
	lea (srootbuf), %rsi
	movsq
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
	decq -24(%rbp)
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
	mov %rax, %rdx
	mov $ddir_fileb, %rdi
	mov %rsp, %rsi
	call memcpy
	movq %rdi, (ddir_filep)
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
	decq -24(%rbp)
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
	mov %rax, %rdx
	mov %rsp, %rsi
	mov $e404pathb, %rdi
	call memcpy
	mov %rdi, (p404path)
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
	decq -24(%rbp)
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
	mov %rax, %rdx
	mov %rsp, %rsi
	mov $e403pathb, %rdi
	call memcpy
	mov %rdi, (p403path)
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
	cmp $0, %al
	je .parse_args.cfg
	cmp $1, %al
	je .parse_args.usage
	cmp $2, %al
	je .parse_args.port
	cmp $3, %al
	je .parse_args.host_addr
	cmp $4, %al
	je .parse_args.root
	cmp $5, %al
	je .parse_args.daemonize
	cmp $6, %al
	je .parse_args.daemonize	
	cmp $7, %al
	je .parse_args.usage
	mov $ERR_unknown_arg, %rdi
	call .perror.print
	mov %rsp, %rdi
	call .perror.print
	mov $2, %rdi
	mov $ERR_unknown_arg, %rsi
	mov $1, %edx
	call sndstrbyidx
	jmp .parse_args.0
.parse_args.ret:
	mov %rbp, %rsp
	pop %rbp
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
	push %rbp
	mov %rsp, %rbp

	mov 8(%rbp), %rax
	mov %rax, (argc)
	mov 16(%rbp), %rax
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

	testb $16, (fls)
	jz _start.ndaemonize
	mov $57, %rax
	syscall
	cmp $0, %al
	jne exit
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
	jle ._start.listen_err
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
	jle ._start.accept_err
	jg ._start.accept_pass
._start.accept_err:
	mov $4, %rax
	call perror
._start.accept_pass:
	mov %rax, %rsi
	mov $client_thr, %rdi
	call new_thr
	jmp ._start.listen_pass

	add $32, %rsp

	pop %rbp
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
	jmp .perror.Ni
.perror.Ni:
	mov $ERR_ERR, %rdi
	call .perror.print
	mov $ERR_NI, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.setsock:
	mov $ERR_setsock, %rdi
	call .perror.fprint
	jmp .perror.exit
.perror.bind:
	mov $ERR_bind, %rdi
	push %rax
	call .perror.print
	pop %rax
	cmp $-13, %rax
	je .perror.bind.eacces
	cmp $-98, %rax
	je .perror.bind.addrinuse
	cmp $-99, %rax
	je .perror.bind.addrnotavail
	jmp .perror.eoth
.perror.bind.eacces:
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
	mov $ERR_listen, %rdi
	call .perror.fprint
	mov %rbp, %rsp
	pop %rbp
	ret
.perror.accept:
	mov $ERR_accept, %rdi
	call .perror.fprint
	mov %rbp, %rsp
	pop %rbp
	ret
.perror.open:
	movb %sil, -1(%rbp)
	mov %rdx, -9(%rbp)
	mov $ERR_open, %rdi
	push %rax
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
	jmp .perror.eoth
.perror.open.enoent:
	mov $ERR_ENOENT, %rdi
	call .perror.fprint
	cmpb $0, -1(%rbp)
	je .perror.exit
	add $16, %rsp
	pop %rbp
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
.perror.exit:
	mov $1, %rdi
	jmp _exit

exit:
	mov $60, %rax
	syscall

.bss
	.comm srootbuf, 8192
	.comm ddir_fileb, 8192
	.comm e404pathb, 8192
	.comm e403pathb, 8192

.data

	argc: .quad 0
	args: .quad 0
	fls: .byte 8
#	[arg] port = 0 << 0
#	[arg] serv addr = 0 << 1
#	[arg] root = 0 << 2
#	[cfg] ddir_files = 1 << 3
#	[arg] daemon_fl = 0 << 4
#	[cfg] do_custom_404 = 0 << 5
#	[cfg] do_custom_403 = 0 << 6

	stdout: .quad 0
	stderr: .quad 0

	mpermission: .long 04
	port: .word 99
	saddr: .long 0
	fsroot: .long 0
	cfgpath: .quad dcfgpath
	serv_root: .quad dserv_root
	p404path: .quad d404path
	p403path: .quad d403path

	d403path: .asciz "pages/403.html"
	d404path: .asciz "pages/404.html"
	dserv_root: .asciz "."
	ddir_filep: .quad ddir_file
	ddir_file: .asciz "index.html"
	d403p:
		.ascii "<html>\n"
		.ascii "<head>\n"
		.ascii "\t<meta charset=\"UTF-8\">\n"
		.ascii "\t<title>Forbidden</title>\n"
		.ascii "</head>\n"
		.ascii "<body>\n\t<h1>403 Forbidden</h1>\n"
		.ascii "\t<p>You have no access to file or directory on path: `\0'</p>\n"
		.ascii "</body>\n"
		.asciz "</html>\n"
	d404p:
		.ascii "<html>\n"
		.ascii "<head>\n"
		.ascii "\t<meta charset=\"UTF-8\">\n"
		.ascii "\t<title>Not Found</title>\n"
		.ascii "</head>\n"
		.ascii "<body>\n\t<h1>404 Not found</h1>\n"
		.ascii "\t<p>We can't found file or directory on path: `\0'</p>\n"
		.ascii "</body>\n"
		.asciz "</html>\n"
	resp:
		.ascii "HTTP/1.1 \0\n"
		.ascii "Content-Length: \0\n"
		.ascii "Content-Type: text/html\n"
		.asciz "Connection: Closed\n\n"
	resp_m:
		.asciz "200 OK"
		.asciz "404 Not Found"
		.asciz "403 Forbidden"

	dcfgpath: .asciz "config"
	ERR_ERR: .asciz "ERROR: "
	ERR_NI: .asciz "Not implemented yet.\n"
	ERR_setsock: .asciz "ERROR: Failed to setsockopt.\n"
	ERR_bind: .asciz "ERROR: Bind failed: "
	ERR_open: .asciz "ERROR: Could not open `\0': "
	ERR_ENOENT: .asciz "File or directory does not exist.\n"	
	ERR_EADDRINUSE:	.asciz "Address in use.\n"
	ERR_EADDRNOTAVAIL: .asciz "Interface does not exist, check your host_addr option.\n"
	ERR_EACCES:	.asciz "Not enough permission.\n"
	ERR_listen:	.asciz "ERROR: Listen failed.\n"
	ERR_accept:	.asciz "ERROR: Accept failed.\n"
	ERR_unexp_word: .asciz ":\0 Unexpected word: `\0'.\n"
	ERR_unknown_arg: .asciz "Unknown argument: `\0'.\n"

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

	TRUE: .asciz "true"
	FALSE: .asciz "false"

	USAGE:
		.ascii "Usage: \0 [<args>]\n"
		.ascii "  Arguments:\n"
		.ascii "    -d | --daemonize       Daemonize server.\n"
		.ascii "    --root=<srv root dir>  Server root directory.\n"
		.ascii "    --config=<cfg file>    Path to server config file.\n"
		.ascii "    --port=<srv bind port> Server port to bind instead of the config port option.\n"
		.ascii "    --host_addr=<ip>       Network interface to bind instead of the config option.\n"
		.asciz "    -h | --help            Prints this message.\n"
