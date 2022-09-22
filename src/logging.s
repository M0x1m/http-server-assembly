.globl log

.text

getaddr:
# rdi - fd
# rsi - dest
# ret rax - writed size
	push %rbp
	mov %rsp, %rbp
	mov %edi, -4(%rbp)
	mov %rsi, -12(%rbp)
	movq $0, -20(%rbp)
	sub $40, %rsp
	lea 4(%rsp), %rsi
	movl $16, (%rsp)
	mov %rsp, %rdx
	mov $52, %rax
	syscall
	cmp $0, %rax
	jl .getaddr.lc
	add $4, %rsp
	movsxd 4(%rsp), %rdi
	mov -12(%rbp), %rsi
	call inet_ntoa
	add %rax, -12(%rbp)
	add %rax, -20(%rbp)
	mov -12(%rbp), %rsi
	movb $58, -1(%rsi)
	movzxw 2(%rsp), %rdi
	call htons
	add $16, %rsp
	mov %rax, %rsi
	mov -12(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	add %rax, -20(%rbp)
	mov -20(%rbp), %rax
	leave
	ret
.getaddr.lc:
	mov $disconnected, %rsi
	mov -12(%rbp), %rdi
	call cpstr
	add %rax, -20(%rbp)
	add %rax, -12(%rbp)
	movsxd -4(%rbp), %rsi
	mov -12(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	add %rax, -20(%rbp)
	add %rax, -12(%rbp)
	mov $disconnected, %rsi
	mov -12(%rbp), %rdi
	mov $1, %rdx
	call cpstrbyidx
	add %rax, -20(%rbp)
	mov -20(%rbp), %rax
	leave
	ret

cpstrbyidx:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	sub $24, %rsp
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getstrbyidx
	mov %rax, %rsi
	mov -8(%rbp), %rdi
	call cpstr
	mov %rdx, %rax
	leave
	ret

cpstr:
	push %rdi
	push %rsi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov 8(%rsp), %rdi
	call memcpy
	pop %rsi
	pop %rdi
	mov %rdx, %rax
	ret

sndstr:
	push %rsi
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	mov %rdi, %rsi
	mov (%rsp), %rdi
	mov $1, %rax
	syscall
	pop %rdi
	pop %rsi
	ret

inet_ntoa:
# rdi - addr
# rsi - dest ptr
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	movw $0, -18(%rbp)
	movw $0, -20(%rbp)
	sub $20, %rsp
.inet_ntoa:
	mov -8(%rbp), %rsi
	mov -16(%rbp), %rdi
	add -20(%rbp), %di
	mov -17(%rbp), %cl
	addb $8, -17(%rbp)
	shr %cl, %rsi
	and $0xff, %rsi
	xor %dl, %dl
	call cpustr
	add %rax, %rdi
	movb $46, (%rdi)
	inc %rax
	add %ax, -20(%rbp)
	incb -18(%rbp)
	cmpb $4, -18(%rbp)
	jb .inet_ntoa
	movzxw -20(%rbp), %rax
	mov -16(%rbp), %rsi
	movb $0, -1(%rsi, %rax)
	leave
	ret

log:
# rdi - msg id
# rsi - args(can be structs)
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	sub $42, %rsp
	call time
	mov %rax, -42(%rbp)
	xor %rdi, %rdi
	mov $4096, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -24(%rbp)
	mov %rax, -32(%rbp)
	cmpq $1, -8(%rbp)
	je .log.1
	cmpq $2, -8(%rbp)
	je .log.2
	cmpq $3, -8(%rbp)
	je .log.3
	cmpq $4, -8(%rbp)
	je .log.4
	cmpq $5, -8(%rbp)
	je .log.5
	cmpq $6, -8(%rbp)
	je .log.6
	cmpq $7, -8(%rbp)
	je .log.7
	cmpq $8, -8(%rbp)
	je .log.8
	cmpq $9, -8(%rbp)
	je .log.9
	cmpq $10, -8(%rbp)
	je .log.10
	cmpq $11, -8(%rbp)
	je .log.11
	cmpq $12, -8(%rbp)
	je .log.12
	cmpq $13, -8(%rbp)
	je .log.13
	cmpq $14, -8(%rbp)
	je .log.14
	cmpq $15, -8(%rbp)
	je .log.15
	cmpq $16, -8(%rbp)
	je .log.16
	cmpq $17, -8(%rbp)
	je .log.17
	cmpq $18, -8(%rbp)
	je .log.18
	cmpq $19, -8(%rbp)
	je .log.19
	cmpq $20, -8(%rbp)
	je .log.20
	cmpq $21, -8(%rbp)
	je .log.21
	cmpq $22, -8(%rbp)
	je .log.22
	cmpq $23, -8(%rbp)
	je .log.23
	cmpq $24, -8(%rbp)
	je .log.24
	cmpq $25, -8(%rbp)
	je .log.25
	jmp .log.err
.log.1:
	mov -16(%rbp), %rsi
	mov -24(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	add %rax, -24(%rbp)
	mov $LOGS, %rsi
	mov -24(%rbp), %rdi
	call cpstr
	jmp .log.ret
.log.2:
	mov -16(%rbp), %rsi
	mov -24(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	add %rax, -24(%rbp)
	mov $LOGS, %rsi
	mov $1, %rdx
	mov -24(%rbp), %rdi
	call cpstrbyidx
	jmp .log.ret
.log.3:
	mov $LOGS, %rsi
	mov $2, %rdx
	mov -24(%rbp), %rdi
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov -24(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	jmp .log.ret
.log.4:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $3, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.5:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $4, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -24(%rbp), %rsi
	mov -16(%rbp), %rdi
	mov 4(%rdi), %edi
	call inet_ntoa
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	movb $58, -1(%rdi)
	mov -16(%rbp), %rdi
	movzxw 2(%rdi), %rdi
	call htons
	mov %rax, %rsi
	mov -24(%rbp), %rdi
	xor %dl, %dl
	call cpustr
	jmp .log.ret
.log.6:
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $5, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	jmp .log.ret
.log.7:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $6, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $7, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $8, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.8:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $9, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $10, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $11, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.9:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $12, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $13, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	jmp .log.ret
.log.10:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $14, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $15, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov (%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $16, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.11:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $17, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov (%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $18, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $19, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.12:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $20, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $21, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov (%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $22, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.13:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $23, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 16(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $24, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	mov (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $25, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $26, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.14:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $27, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 16(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $28, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $29, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $30, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.15:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $31, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $32, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	movsxd (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $33, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.16:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $34, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	jmp .log.ret
.log.17:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $35, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov -16(%rbp), %rsi
	mov 16(%rsi), %rsi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $36, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov -16(%rbp), %rsi
	mov (%rsi), %rsi
	xor %dl, %dl
	call cpustr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	movb $46, (%rdi)
	incq -24(%rbp)
	mov -24(%rbp), %rdi
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rax
	mov $1000000, %rbx
	xor %rdx, %rdx
	div %rbx
	mov %rax, %rsi
	mov $3, %dl
	call cpustr
	mov -24(%rbp), %rdi
	movb $115, (%rdi, %rax)
	jmp .log.ret
.log.18:
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $37, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.19:
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $38, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.20:
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $39, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.21:
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $40, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.22:
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $41, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.23:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $42, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	jmp .log.ret
.log.24:
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $43, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	jmp .log.ret
.log.25:
	mov -16(%rbp), %rdi
	mov (%rdi), %rdi
	mov -24(%rbp), %rsi
	call getaddr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $44, %rdx
	call cpstrbyidx
	add %rax, -24(%rbp)
	mov -16(%rbp), %rsi
	mov 8(%rsi), %rsi
	cmp $0, %rsi
	je .log.ret
	mov -24(%rbp), %rdi
	call cpstr
	add %rax, -24(%rbp)
	mov -24(%rbp), %rdi
	mov $LOGS, %rsi
	mov $45, %rdx
	call cpstrbyidx
	jmp .log.ret
.log.ret:
	mov -32(%rbp), %rdi
	mov $10, %rsi
	call strlen
	mov %rax, %rdx
	push %rdx
	call memmov
	movw $0x205d, 8(%rdi)
	mov -42(%rbp), %rdi
	xor %rsi, %rsi
	call asctime
	mov %rax, %rsi
	mov -32(%rbp), %rdi
	call cpstr
	mov -32(%rbp), %rdi
	mov $1, %rsi
	call strlen
	mov %rax, %rdx
	call memmov
	movb $0x5b, (%rdi)
	pop %rdx
	add $12, %rdx
	movb $10, -1(%rdi, %rdx)
	testw $4096, (fls)
	jnz .log.ret.1
	mov %rdi, %rsi
	mov $1, %rdi
	mov $1, %rax
	syscall
.log.ret.1:
	testw $2048, (fls)
	jz .log.ret.0
	mov -32(%rbp), %rdi
	inc %rdi
	mov $11, %rsi
	call strlen
	mov %rax, %rdx
	push %rdx
	call memmov
	mov -42(%rbp), %rdi
	xor %rsi, %rsi
	call ascdate
	mov %rax, %rsi
	mov -32(%rbp), %rdi
	inc %rdi
	call cpstr
	mov -32(%rbp), %rsi
	movsxd (flogfile), %rdi
	pop %rdx
	add $12, %rdx
	mov $1, %rax
	syscall
.log.ret.0:
	push %rax
	mov -32(%rbp), %rdi
	mov $4096, %rsi
	mov $11, %rax
	syscall
	pop %rax
	leave
	ret
.log.err:
	mov $-1, %rax
	jmp .log.ret.0

.data

disconnected: .asciz "[Hanged up connection on fd: \0]"

LOGS:
	.asciz " mime-types have been loaded"
	.asciz " cache files have been loaded"
	.asciz "Binding to port "
	.asciz "Server successfully started, waiting for connections..."
	.asciz "Created new thread for the connection from "
	.asciz " requested /"
	.asciz "Requested path `/\0' by the address \0 was not found, 404 response sent"
	.asciz "Server does not have enough permission to open `/\0' for the request from the address \0, 403 response sent"
	.asciz "Sorting the directory `/\0' for the request from "
	.asciz "Saved cache for the directory `/\0' to `\0'"
	.asciz "Used cache from `\0' for the directory `/\0'"
	.asciz "Updated cache for the directory `/\0' in the cache file `\0'"
	.asciz "The requested cached file `/\0' by \0 is no longer accessible, thus cache file `\0' will be deleted"
	.asciz "The requested cached file `/\0' by \0 is no longer exist, thus cache file `\0' will be deleted"
	.asciz "Generating directory entries list of the directory `/\0' for the connection from \0..."
	.asciz "Closing connection "
	.asciz "Directory `/\0' sorted in "
	.asciz " timed out, 408 response sent"
	.asciz ": unknown protocol, 400 response sent"
	.asciz ": unsupported protocol, 505 response sent"
	.asciz ": unknown HTTP method, 400 response sent"
	.asciz ": unsupported HTTP method, 501 response sent"
	.asciz "Request was successfully served, 200 response status sent to "
	.asciz "Request was successfully served, 206 response status sent to "
	.asciz ": Invalid range for the file `/\0', 416 response status sent"
