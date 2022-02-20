.globl _start

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
	mov $1024, %rsi			# THREAD STACK SIZE declared here
	mov $7, %rdx
	mov $34, %r10
	mov $0, %r8
	mov $0, %r9
	syscall

	pop 1016(%rax)
	pop 1008(%rax)

	lea 1008(%rax), %rax 
	mov %rax, -8(%rbp)

	mov $56, %rax
	mov $0x80008f00, %rdi
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

htons:
	push %rcx
	mov $8, %cl
	mov %rdi, %rax
	shl %cl, %rax
	mov $65535, %rbx
	mov $0, %rdx
	div %rbx
	mov %rdx, %rax
	pop %rcx
	ret

ulen:
	mov $0, %rax
	push %rdi
.ulen.0:
	cmp $0, %rdi
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
	push %rdi
	push %rbp
	mov %rsp, %rbp
	call ulen
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
	pop %rbp
	pop %rdi
	ret

memcpy:
	push %rdx
.memcpy.0:
	cmp $0, %rdx
	ja .memcpy.1
	jbe .memcpy.2
.memcpy.1:
	movb (%rsi, %rdx), %cl
	movb %cl, (%rdi, %rdx)
	dec %rdx
	jmp .memcpy.0
.memcpy.2:
	pop %rdx
	ret

.data
	index: .asciz "index.html"
	resp:
		.ascii "HTTP/1.1 200 OK\n"
		.asciz "Content-Length: "
		.ascii "\nContent-Type: text/html\n"
		.asciz "Connection: Closed\n\n"
.text

client_thr:
	push %rbp
	mov %rsp, %rbp

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

	mov $40, %rax
	mov 8(%rbp), %rdi
	mov -4(%rbp), %rsi
	mov $0, %rdx
	mov -96(%rbp), %r10
	syscall

/*
	mov $0, %rsi
	mov $test.msg, %rdi
	call getstrbyidx
	mov %rax, %rdi
	call strlen
	mov %rax, %rdx
	mov $1, %rax
	mov %rdi, %rsi
	mov 8(%rbp), %rdi
	syscall
*/
	mov $3, %rax
	mov 8(%rbp), %rdi
	syscall

	mov $3, %rax
	mov -4(%rbp), %rdi
	syscall
	
	pop %rbp
	mov $0,  %rdi
	jmp exit

getstrbyidx:
	push %rdi
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
	pop %rdi
	ret

memrev:
	push %rbp
	mov %rsp, %rbp
	mov %rsi, %rax
	mov $2, %rbx
	mov $0, %rdx
	div %rbx
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

_start:
	push %rbp
	mov %rsp, %rbp

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

	mov $8380, %rdi
	sub $8, %rsp
	call htons
	movw $2, -24(%rbp)
	movw %ax, -22(%rbp)

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
	cmp $1, %rdi
	je .perror.setsock
	cmp $2, %rdi
	je .perror.bind
	cmp $3, %rdi
	je .perror.listen
	cmp $4, %rdi
	je .perror.accept
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
	jmp .perror.bind.eoth
.perror.bind.eacces:
	mov $2, %rdi
	mov $ERR_EACCES, %rsi
	call sndstr
	jmp .perror.exit
.perror.bind.eoth:
	mov $ERR_NI, %rsi
	call sndstr
	jmp .perror.exit
.perror.listen:
	mov $ERR_listen, %rdi
	call .perror.print
	ret
.perror.accept:
	mov $ERR_accept, %rdi
	call .perror.print
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

	ERR_NI: .asciz "Not implemented yet.\n"
	ERR_setsock: .asciz "ERROR: Failed to setsockopt.\n"
	ERR_bind: .asciz "ERROR: Bind failed: "
	ERR_EACCES:	.asciz "Not enough permission.\n"
	ERR_listen:	.asciz "ERROR: Listen failed.\n"
	ERR_accept:	.asciz "ERROR: Accept failed\n"
	test.msg:
		.asciz "HTTP/1.1 200 OK\nServer: Assembly server\nContent-Type: text/html; encoding=utf-8\nContent-Length: 63\nConnection: Closed\n\n<html>\n\t<body>\n\t\t<h1>Hello, World</h1>\n\t</body>\n</html>"
