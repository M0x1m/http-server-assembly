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

client_thr:
	mov %rsp, %rbp
	mov $test.msg, %rdi
	call strlen
	mov %rax, %rdx
	mov $1, %rax
	mov %rdi, %rsi
	mov (%rbp), %rdi
	syscall

	mov $3, %rax
	mov (%rbp), %rdi
	syscall
	
	jmp exit

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
	je ._start.setsock_err

	mov $8080, %rdi
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
	je ._start.bind_err

	mov $50, %rax
	movl -4(%rbp), %edi
	mov $5, %rsi
	syscall

	movl $4, -28(%rbp)

	cmp $-1, %rax
	je ._start.listen_err
	jne ._start.listen_pass
._start.listen_err:
	mov $3, %rdi
	call perror
._start.listen_pass:
	mov $43, %rax
	movl -4(%rbp), %edi
	lea -24(%rbp), %rsi
	lea -28(%rbp), %rdx
	syscall

	cmp $-1, %rax
	je ._start.accept_err
	jne ._start.accept_pass
._start.accept_err:
	mov $4, %rax
	call perror
._start.accept_pass:
	mov %rax, %rsi
	mov $client_thr, %rdi
	call new_thr

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
	call .perror.print
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

	ERR_setsock:
		.asciz "ERROR: Failed to setsockopt.\n"
	ERR_bind:
		.asciz "ERROR: Bind failed.\n"
	ERR_listen:
		.asciz "ERROR: Listen failed.\n"
	ERR_accept:
		.asciz "ERROR: Accept failed\n"
	test.msg:
		.asciz "Message from server!\n"
