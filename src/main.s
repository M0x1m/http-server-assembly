.global _start

.text
strlen:
	mov $0, %rax
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
	mov $0, %rdi
	mov $65536, %rsi			# THREAD STACK SIZE declared here
	mov $7, %rdx
	mov $34, %r10
	mov $0, %r8
	mov $0, %r9
	syscall

	pop 65536-8(%rax)
	pop 65536-16(%rax)

	lea 65536-16(%rax), %rax 
	mov %rax, -8(%rbp)

	mov $56, %rax
	mov $0x00010f00, %rdi
	mov -8(%rbp), %rsi
	mov $0, %rdx
	mov $0, %r10
	mov $0, %r8
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
	mov $0, %rax
	cmp $0, %rsi
	jle .strtou.0
	mov %rsi, -8(%rbp)
	jne .strtou.1
.strtou.0:
	call strlen
	mov %rax, %rsi
	mov %rax, -8(%rbp)
	mov $0, %rax
.strtou.1:
	cmp $0, %rsi
	ja .strtou.2
	jmp .strtou.3
.strtou.2:
	cmpb $0x30, -1(%rdi, %rsi)
	jb .strtou.3
	cmpb $0x39, -1(%rdi, %rsi)
	ja .strtou.3
	mov $0, %rbx
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
	mov $0, %rdx
	mul %rbx
	mov %rax, %rbx
	jmp .strtou.4
.strtou.3:
	mov %rbp, %rsp
	pop %rbp
	ret

htons:
	mov $8, %cl
	mov %rdi, %rax
	shl %cl, %rax
	mov $65535, %rbx
	mov $0, %rdx
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
	mov $0, %rdx
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
	mov $0, %rdx
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
	cmp $0, %rdx
	ja .memcpy.1
	jbe .memcpy.2
.memcpy.1:
	movb (%rsi, %rdx), %cl
	movb %cl, (%rdi, %rdx)
	dec %rdx
	jmp memcpy
.memcpy.2:
	ret

wait_client:
	push %rdi
.wait_client.0:
	mov $1, %rax
	mov (%rsp), %rdi
	movb $0, -9(%rsp)
	lea -9(%rsp), %rsi
	mov $1, %rdx
	syscall
	mov (%rsp), %rax
	movl %eax, -8(%rsp)
	movw $8192, -4(%rsp)
	movw $0, -2(%rsp)
	mov $7, %rax
	mov $1, %rsi
	mov $50, %rdx
	lea -8(%rsp), %rdi
	syscall
	cmp $0, %rax
	je .wait_client.0
	movw -2(%rsp), %bx
	andw $8192, %bx
	cmpw $8192, %bx
	je .wait_client.2
	jmp .wait_client.0
.wait_client.2:
	pop %rdi
	ret

client_thr:
	push %rbp
	mov %rsp, %rbp

	sub $144, %rsp

	mov $4, %rax
	lea -144(%rbp), %rsi
	mov $index, %rdi
	syscall

	mov 8(%rbp), %rdi
	mov $resp, %rsi
	call sndstr

	mov -96(%rbp), %rsi
	mov 8(%rbp), %rdi
	call sndustr

	mov $resp, %rdi
	mov $1, %rsi
	call getstrbyidx
	mov %rax, %rsi
	mov 8(%rbp), %rdi
	call sndstr

	mov $2, %rax
	mov $index, %rdi
	mov $0, %rsi
	syscall

	movl %eax, -4(%rbp)

.client_thr.2:
	cmpq $65536, -96(%rbp)
	ja .client_thr.0
	jb .client_thr.1
.client_thr.0:
	mov $65536, %r10
	subq $65536, -96(%rbp)
	jmp .client_thr.3
.client_thr.1:
	mov -96(%rbp), %r10
	movq $0, -96(%rbp)
.client_thr.3:
	mov $40, %rax
	mov 8(%rbp), %rdi
	mov -4(%rbp), %rsi
	mov $0, %rdx
	syscall

	cmpq $0, -96(%rbp)
	ja .client_thr.2

	mov 8(%rbp), %rdi
	call wait_client

	mov $3, %rax
	mov 8(%rbp), %rdi
	syscall

	mov $3, %rax
	mov -4(%rbp), %rdi
	syscall

	add $144, %rsp
	
	pop %rbp
	mov $0, %rdi
	jmp exit

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
	mov $0, %rdx
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

memcmp:
	mov $1, %rax
	mov $0, %rbx
.memcmp.0:
	movb (%rdi, %rbx), %cl
	cmpb %cl, (%rsi, %rbx)
	jne .memcmp.1
	cmp %rdx, %rbx
	jl .memcmp.2
.memcmp.ret:
	ret
.memcmp.1:
	mov $0, %rax
	jmp .memcmp.ret
.memcmp.2:
	inc %rbx
	jmp .memcmp.0

sndstr:
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	pop %rdi
	mov $1, %rax
	syscall
	ret

sndustr:
	push %rdi
	mov %rsi, %rdi
	call utostr
	mov %rax, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	pop %rdi
	mov $1, %rax
	syscall
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
	mov $0, %rax
	ret

skip_sts:
	push %rbp
	mov %rsp, %rbp
	movb $0, -2(%rbp)
	movl $0, -6(%rbp)
.skip_sts.0:
	mov $0, %rax
	lea -1(%rbp), %rsi
	mov $1, %rdx
	syscall
	cmp $0, %rax
	jle .skip_sts.ret
	incl -6(%rbp)
	cmpb $1, -2(%rbp)
	je .skip_sts.2	
	cmpb $35, -1(%rbp)
	je .skip_sts.1
	cmpb $0x20, -1(%rbp)
	je .skip_sts.0
	cmpb $10, -1(%rbp)
	je .skip_sts.0
	cmpb $0x9, -1(%rbp)
	je .skip_sts.0
	mov $8, %rax
	mov $-1, %rsi
	mov $1, %rdx
	syscall
.skip_sts.ret:
	pop %rbp
	ret
.skip_sts.1:
	movb $1, -2(%rbp)
	jmp .skip_sts.0
.skip_sts.2:
	cmpb $10, -1(%rbp)
	jne .skip_sts.0
	movb $0, -2(%rbp)
	jmp .skip_sts.0

getvar:
	push %rbp
	mov %rsp, %rbp
	call skip_sts
	movq $0, -8(%rbp)
.getvar.0:
	mov -8(%rbp), %rcx
	neg %rcx
	mov $0, %rax
	lea -90(%rbp, %rcx), %rsi
	mov $1, %rdx
	syscall
	cmp $0, %rax
	jle .getvar.err
	mov -8(%rbp), %rcx
	neg %rcx
	incq -8(%rbp)
	cmpb $61, -90(%rbp, %rcx)
	jne .getvar.0
.getvar.1:
	cmpq $0, -8(%rbp)
	je .getvar.err
	movb $0, -89(%rbp)
	lea -90(%rbp, %rcx), %rsp
	lea -90(%rbp, %rcx), %rdi
	mov -8(%rbp), %rsi
	dec %rsi
	call memrev
	mov %rdi, %rax
	jmp .getvar.pass
.getvar.err:
	lea -9(%rbp), %rax
.getvar.pass:
	mov %rbp, %rsp
	pop %rbp
	ret

offt_to_delim:
	mov $0, %rax
.offt_to_delim.1:
	cmpb %sil, (%rdi, %rax)
	jne .offt_to_delim.0
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
	push %rax
	call strlen
	mov %rax, %rsi
	pop %rdi
	call min
	mov -8(%rbp), %rdi
	mov %rax, %rsi
	movb %al, -14(%rbp)
	call strtou
	mov $0, %rbx
	movb -14(%rbp), %bl
	add %rbx, -8(%rbp)
	incq -8(%rbp)
	mov $0, %rbx
	movb -9(%rbp), %bl
	movb %al, -13(%rbp, %rbx)
	incb -9(%rbp)
	cmpb $4, -9(%rbp)
	jb .inet_addr.0
.inet_addr.ret:
	mov $0, %rax
	movl -13(%rbp), %eax
	mov %rbp, %rsp
	pop %rbp
	ret

getval:
	push %rbp
	mov %rsp, %rbp
	movl $0, -4(%rbp)
.getval.0:
	mov $0, %rax
	movl -4(%rbp), %ecx
	neg %rcx
	lea -160(%rbp, %rcx), %rsi
	mov $1, %rdx
	syscall
	cmp $0, %rax
	jle .getval.1
	movl -4(%rbp), %ecx
	neg %rcx
	incl -4(%rbp)
	cmpb $35, -160(%rbp, %rcx)
	je .getval.1
	cmpb $0x20, -160(%rbp, %rcx)
	je .getval.1
	cmpb $10, -160(%rbp, %rcx)
	je .getval.1
	cmpb $9, -160(%rbp, %rcx)
	je .getval.1
	jmp .getval.0
.getval.ret:
	pop %rbp
	ret
.getval.1:
	movb $0, -159(%rbp)
	lea -159(%rbp, %rcx), %rsp
	lea -159(%rbp, %rcx), %rdi
	neg %rcx
	lea -1(%rcx), %rsi
	call memrev
	mov %rdi, %rax
	mov %rbp, %rsp
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
	sub $12, %rsp
	mov $2, %rax
	mov (cfgpath), %rdi
	mov $0, %rsi
	syscall
	cmp $-1, %rax
	jle .parse_cfg.oerr
	movl %eax, -4(%rbp)
	jmp .parse_cfg.opass
.parse_cfg.oerr:
	mov $5, %rdi
	mov $1, %rsi
	mov (cfgpath), %rdx
	call perror
	jmp .parse_cfg.ret
.parse_cfg.opass:
	movl $0, -12(%rbp)
.parse_cfg.opts:
	movl -4(%rbp), %edi
	call getvar
	mov %rax, %rdi
	mov $CFG_KEYWORDS, %rsi
	mov $2, %rdx
	call strinstrs
	cmp $0, %rax
	je .parse_cfg.port
	cmp $1, %rax
	je .parse_cfg.addr
	cmpl $1, -12(%rbp)
	incl -12(%rbp)
	jb .parse_cfg.opts
.parse_cfg.ret:
	mov $3, %rax
	movl -4(%rbp), %edi
	syscall
	mov %rbp, %rsp
	pop %rbp
	ret
.parse_cfg.port:
	movl -4(%rbp), %edi
	call getval
	mov %rax, %rsi
	mov %rax, -20(%rbp)
	mov %rax, %rsp
	mov -20(%rbp), %rdi
	mov $0, %rsi
	call strtou
	movw %ax, (port)
	jmp .parse_cfg.opts
.parse_cfg.addr:
	movl -4(%rbp), %edi
	call getval
	mov %rax, %rdi
	call inet_addr
#	mov $16777343, %rax
	movl %eax, (saddr)
	jmp .parse_cfg.opts

_start:
	push %rbp
	mov %rsp, %rbp

	sub $32, %rsp

	call parse_cfg

	mov $41, %rax
	mov $2, %rdi
	mov $1, %rsi
	mov $0, %rdx
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
	mov $0, %rdi
	jmp exit

._start.setsock_err:
	mov $1, %rdi
	jmp perror
._start.bind_err:
	mov $2, %rdi
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
.perror.setsock:
	mov $ERR_setsock, %rdi
	call .perror.print
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
	jmp .perror.eoth
.perror.bind.eacces:
	mov $2, %rdi
	mov $ERR_EACCES, %rdi
	call .perror.print
	jmp .perror.exit
.perror.bind.addrinuse:
	mov $2, %rdi
	mov $ERR_EADDRINUSE, %rdi
	call .perror.print
	jmp .perror.exit
.perror.eoth:
	mov $ERR_NI, %rdi
	call .perror.print
	jmp .perror.exit
.perror.listen:
	mov $ERR_listen, %rdi
	call .perror.print
	add $16, %rsp
	pop %rbp
	ret
.perror.accept:
	mov $ERR_accept, %rdi
	call .perror.print
	add $16, %rsp
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
	call .perror.print
	cmpb $0, -1(%rbp)
	je .perror.exit
	add $16, %rsp
	pop %rbp
	ret
.perror.print:
	call strlen
	mov %rax, %rdx
	mov $1, %rax
	mov %rdi, %rsi
	mov $2, %rdi
	syscall
	ret	
.perror.exit:
	mov $1, %rdi
	jmp exit

exit:
	mov $60, %rax
	syscall

.data

	port: .word 99
	saddr: .long 0
	cfgpath: .quad dcfgpath

	index: .asciz "index.html"
	resp:
		.ascii "HTTP/1.1 200 OK\n"
		.asciz "Content-Length: "
		.ascii "\nContent-Type: text/html"
		.asciz "\nConnection: Closed\n\n"

	dcfgpath: .asciz "config"
	ERR_NI: .asciz "Not implemented yet.\n"
	ERR_setsock: .asciz "ERROR: Failed to setsockopt.\n"
	ERR_bind: .asciz "ERROR: Bind failed: "
	ERR_open: .asciz "ERROR: Could not open the file `\0': "
	ERR_ENOENT: .asciz "File does not exist.\n"	
	ERR_EADDRINUSE:	.asciz "Address in use.\n"
	ERR_EACCES:	.asciz "Not enough permission.\n"
	ERR_listen:	.asciz "ERROR: Listen failed.\n"
	ERR_accept:	.asciz "ERROR: Accept failed.\n"

	CFG_KEYWORDS:
		.asciz "port="
		.asciz "host_addr="
