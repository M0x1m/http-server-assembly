.globl _start

.equ SYS_ioctl, 29
.equ SYS_openat, 56
.equ SYS_close, 57
.equ SYS_read, 63
.equ SYS_write, 64
.equ SYS_writev, 66
.equ SYS_sendfile, 71
.equ SYS_ppoll, 73
.equ SYS_exit, 93
.equ SYS_rt_sigaction, 134
.equ SYS_socket, 198
.equ SYS_bind, 200
.equ SYS_listen, 201
.equ SYS_setsockopt, 208
.equ SYS_brk, 214
.equ SYS_munmap, 215
.equ SYS_mremap, 216
.equ SYS_clone, 220
.equ SYS_mmap, 222
.equ SYS_accept4, 242 // Simple accept does not working on RMX3085, idk why, thus i use accept4

.equ AT_FDCWD, 4294967196
.equ FIONREAD, 21531
.equ SA_RESTORER, 0x4000000

.text

strlen:
	stp x1, x2, [sp, #-16]!
	mov x1, x0
.strlen.0:
	ldrb w2, [x1], #1
	cmp w2, #0
	bhi .strlen.0
	sub x0, x1, x0
	sub x0, x0, #1
	ldp x1, x2, [sp], #16
	ret	

htons:
	str x1, [sp, #-16]!
	mov w1, w0, lsr #8
	lsl w0, w0, #8
	orr w0, w1, w0
	and w0, w0, #0xffff
	ldr x1, [sp], #16
	ret

thread_create:
// x0 - function pointer
// x1 - arg
// ret x0 - pid of thread
	stp x29, x30, [sp, #-32]!
	add x29, sp, #32

	stp x0, x1, [x29, #-16]

	eor x0, x0, x0
	mov x1, #65536     // Thread stack size
	mov x2, #3         // PROT_READ | PROT_WRITE
	mov x3, #34        // MAP_ANON | MAP_PRIVATE
	eor x4, x4, x4
	eor x5, x5, x5
	mov x8, #SYS_mmap
	svc #0

	add x1, x0, #65536 // Getting top of the thread stack

	ldr x0, [x29, #-8] // Storing argument of thread func
	str x0, [x1, #-8]!
	ldr x0, [x29, #-16] // Storing func pointer to thread func
	str x0, [x1, #-8]!

	ldr x0, =0x80010d00  // Flags
	eor x2, x2, x2
	eor x3, x3, x3
	eor x4, x4, x4
	mov x8, #SYS_clone
	svc #0

	cmp x0, #0
	bne .thread_create.0
	ldp x1, x0, [sp], #16
	blr x1

	sub x0, sp, #65536
	mov x1, #65536
	mov x8, #SYS_munmap
	svc #0

	eor x0, x0, x0
	b exit

.thread_create.0:
	ldp x29, x30, [sp], #32
	ret

u2str:
// x0 - num
// x1 - dest
	stp x29, x30, [sp, #-128]!
	add x29, sp, #128
	stp x1, x0, [x29, #-16]
	add x0, x29, #-25
	mov w2, #0
	strb w2, [x0], #-1
	str x0, [x29, #-24]
.u2str.0:
	ldr x0, [x29, #-8]
	mov w1, #10
	udiv x2, x0, x1
	str x2, [x29, #-8]
	msub x0, x2, x1, x0
	orr w0, w0, #0x30
	ldr x1, [x29, #-24]
	strb w0, [x1], #-1
	str x1, [x29, #-24]
	cmp x2, #0
	bhi .u2str.0
	ldr x0, [x29, #-24]
	add x0, x0, #1
	mov x1, x0
	bl strlen
	mov x2, x0
	ldr x0, [x29, #-16]
	bl memcpy
	ldr x1, [x29, #-16]
	ldp x29, x30, [sp], #128
	ret

memmov:
// x0 - dest
// x1 - src
// x2 - len
	stp x29, x30, [sp, #-32]!
	add x29, sp, #32
	stp x1, x0, [x29, #-16]

	cmp x1, x0
	blo .memmov.0
	add x0, x0, x2
	add x1, x1, x2
	stp x1, x0, [x29, #-16]
	neg x2, x2
.memmov.0:
	ldp x0, x1, [x29, #-16]
	ldrb w0, [x0, x2]
	strb w0, [x1, x2]

	cmp x2, #0
	blt .memmov.1
	sub x2, x2, #1
	b .memmov.2
.memmov.1:
	add x2, x2, #1
.memmov.2:
	bne .memmov.0
	ldp x29, x30, [sp], #32
	ret

memcpy:
// x0 - dest
// x1 - src
// x2 - len
	stp x29, x30, [sp, #-32]!
	add x29, sp, #32

	stp x1, x0, [x29, #-16]
.memcpy.0:
	sub x2, x2, #1
	ldp x1, x0, [x29, #-16]
	ldrb w1, [x1, x2]
	strb w1, [x0, x2]

	cmp x2, #0
	bhi .memcpy.0

	ldp x29, x30, [sp], #32
	ret

astrbyidx:
// Adds string to iovec array
// x0 - dest
// x1 - str
// x2 - idx
// x3 - dest off
	stp x29, x30, [sp, #-64]!
	add x29, sp, #64
	stp x0, x1, [x29, #-16]
	add x4, x3, #16
	stp x2, x4, [x29, #-32]
	add x3, x0, x3
	mov x0, x1
	mov x1, x2
	bl gstrbyidx
	mov x1, x0
	bl strlen
	stp x1, x0, [x3]
	ldp x0, x1, [x29, #-16]
	ldp x2, x3, [x29, #-32]
	ldp x29, x30, [sp], #64
	ret

getreqpath:
// Finds requested path from request
// w0 - sock
// x1 - char buffer[w2]
	stp x29, x30, [sp, #-64]!
	add x29, sp, #64
	stp w2, w0, [x29, #-8]
	str x1, [x29, #-16]

	ldp w2, w0, [x29, #-8]
	ldr x1, [x29, #-16]
	mov x8, #SYS_read
	svc #0

	ldr x1, [x29, #-16]
.getreqpath:
	ldrb w0, [x1], #1
	cmp w0, #47
	beq .getreqpath.0
	cmp w0, #0
	beq .getreqpath.1
	b .getreqpath
.getreqpath.0:
	mov x2, x1
.getreqpath.3:
	ldrb w0, [x2, #1]!
	cmp w0, #0
	beq .getreqpath.2
	cmp w0, #32
	bne .getreqpath.3
.getreqpath.2:
	ldr x0, [x29, #-16]
	sub x2, x2, x0
	str x2, [x29, #-8]
	bl memmov
	ldr x0, [x29, #-16]
	mov x2, #0
.getreqpath.4:
	ldrb w1, [x0, x2]
	add x2, x2, #1
	cmp w1, #0
	beq .getreqpath.1
	cmp w1, #32
	bne .getreqpath.4
	sub x2, x2, #1
	mov w1, #0
	strb w1, [x2, x0]
.getreqpath.1:
	ldp x29, x30, [sp], #64
	ret

milis2timespec:
// x0 - milliseconds
// x1 - struct timespec* dest
	stp x29, x30, [sp, #-32]!
	add x29, sp, #32
	str x1, [x29, #-8]
	ldr x1, =1000000
	mul x0, x0, x1
	ldr x1, =1000000000
	udiv x2, x0, x1
	msub x1, x2, x1, x0
	ldr x0, [x29, #-8]
	stp x2, x1, [x0]
	ldp x29, x30, [sp], #32
	ret

client_func:
	stp x29, x30, [sp, #-64]!
	add x29, sp, #64
	str w0, [x29, #-4]

	mov x0, #1
	str x0, [x29, #-36]
	mov x0, #0
	str x0, [x29, #-28]
	str x0, [x29, #-20]
	str x0, [x29, #-12]

	mov x0, #13
	add x1, x29, #-36
	eor x2, x2, x2
	mov x3, #8
	mov x8, #SYS_rt_sigaction
	svc #0

	adr x0, timeout
	ldr x0, [x0]
	add x1, x29, #-20
	bl milis2timespec

	ldr w0, [x29, #-4]
	str w0, [x29, #-28]
	mov w0, #8193
	str w0, [x29, #-24]
	add x0, x29, #-28
	mov x1, #1
	add x2, x29, #-20
	eor x3, x3, x3
	eor x4, x4, x4
	mov x8, #SYS_ppoll
	svc #0

	ldr w0, [x29, #-4]
	mov x1, #FIONREAD
	add x2, x29, #-16
	mov x8, #SYS_ioctl
	svc #0

	eor x0, x0, x0
	ldr w1, [x29, #-16]
	add w1, w1, #1
	str w1, [x29, #-16]
	mov x2, #3
	mov x3, #34
	eor x4, x4, x4
	eor x5, x5, x5
	mov x8, #SYS_mmap
	svc #0
	
	str x0, [x29, #-12]

	ldr w0, [x29, #-4]
	ldr x1, [x29, #-12]
	ldr w2, [x29, #-16]
	adr x3, timeout
	ldr x3, [x3]
	bl getreqpath
	
	ldr x0, [x29, #-12]
	mov x1, x0
	bl strlen
	cmp x0, #0
	bhi .client_func.0
	mov w0, #46
	strh w0, [x1]
.client_func.0:
	ldr x0, =AT_FDCWD 
	ldr x1, [x29, #-12]
	eor x2, x2, x2
	mov x8, #SYS_openat
	svc #0
	cmp x0, #-2
	beq .client_func.404
	cmp x0, #-13
	beq .client_func.403
	str w0, [x29, #-28]

	eor x0, x0, x0
	mov x1, #65536
	mov x2, #3
	mov x3, #34
	eor x4, x4, x4
	eor x5, x5, x5
	mov x8, #SYS_mmap
	svc #0
	str x0, [x29, #-24]

	adr x1, resp
	eor x2, x2, x2
	eor x3, x3, x3
	bl astrbyidx
	adr x1, strspcds
	bl astrbyidx
	adr x1, resp
	mov x2, #1
	bl astrbyidx
	mov x2, #3
	bl astrbyidx
	mov x1, x0
	mov x0, #16
	udiv x2, x3, x0
	ldr w0, [x29, #-4]
	mov x8, #SYS_writev
	svc #0
.client_func.200:
	ldr w0, [x29, #-4]
	ldr w1, [x29, #-28]
	eor x2, x2, x2
	mov x3, #65536
	mov x8, #SYS_sendfile
	svc #0

	cmp x0, #65536
	beq .client_func.200

	ldr x0, [x29, #-24]
	mov x1, #65536
	mov x8, #SYS_munmap
	svc #0
	ldr w0, [x29, #-28]
	mov x8, #SYS_close
	svc #0

.client_func.closeconn:
	ldr w0, [x29, #-4]
	mov x8, #SYS_close
	svc #0

	ldr x0, [x29, #-12]
	ldr w1, [x29, #-16]
	mov x8, #SYS_munmap
	svc #0

	ldp x29, x30, [sp], #64
	ret
.client_func.403:
	eor x0, x0, x0
	mov x1, #65536
	mov x2, #3
	mov x3, #34
	eor x4, x4, x4
	eor x5, x5, x5
	mov x8, #SYS_mmap
	svc #0
	str x0, [x29, #-24]

	adr x1, resp
	eor x2, x2, x2
	eor x3, x3, x3
	bl astrbyidx
	adr x1, strspcds
	mov x2, #1
	bl astrbyidx
	adr x1, resp
	mov x2, #1
	bl astrbyidx
	mov x2, #2
	bl astrbyidx
	mov x2, #3
	bl astrbyidx
	adr x1, pg403
	eor x2, x2, x2
	bl astrbyidx
	ldr x1, [x29, #-12]
	bl astrbyidx
	adr x1, pg403
	mov x2, #1
	bl astrbyidx
	mov x0, #16
	udiv x2, x3, x0
	ldr x1, [x29, #-24]
	ldr w0, [x29, #-4]
	mov x8, #SYS_writev
	svc #0

	ldr x0, [x29, #-24]
	mov x1, #65536
	mov x8, #SYS_munmap
	svc #0

	b .client_func.closeconn
.client_func.404:
	eor x0, x0, x0
	mov x1, #65536
	mov x2, #3
	mov x3, #34
	eor x4, x4, x4
	eor x5, x5, x5
	mov x8, #SYS_mmap
	svc #0
	str x0, [x29, #-24]

	adr x1, resp
	eor x2, x2, x2
	eor x3, x3, x3
	bl astrbyidx
	adr x1, strspcds
	mov x2, #2
	bl astrbyidx
	adr x1, resp
	mov x2, #1
	bl astrbyidx
	mov x2, #2
	bl astrbyidx
	mov x2, #3
	bl astrbyidx
	adr x1, pg404
	eor x2, x2, x2
	bl astrbyidx
	ldr x1, [x29, #-12]
	bl astrbyidx
	adr x1, pg404
	mov x2, #1
	bl astrbyidx
	mov x0, #16
	udiv x2, x3, x0
	ldr x1, [x29, #-24]
	ldr w0, [x29, #-4]
	mov x8, #SYS_writev
	svc #0

	ldr x0, [x29, #-24]
	mov x1, #65536
	mov x8, #SYS_munmap
	svc #0

	b .client_func.closeconn

gstrbyidx:
// x0 - str*
// x1 - idx
// ret x0 - ptr
	cmp x1, #0
	bhi .gstrbyidx.0
	ret
.gstrbyidx.0:
	stp x29, x30, [sp, #-32]!
	add x29, sp, #32
	stp x1, x0, [x29, #-16]
.gstrbyidx:
	ldr x0, [x29, #-8]
	mov x1, x0
	bl strlen
	add x0, x0, x1
	add x0, x0, #1
	str x0, [x29, #-8]
	ldr x0, [x29, #-16]
	sub x0, x0, #1
	str x0, [x29, #-16]
	cmp x0, #0
	bhi .gstrbyidx
	ldr x0, [x29, #-8]
	ldp x29, x30, [sp], #32
	ret

_start:
	add sp, sp, #-64
	add x29, sp, #64

	mov x0, #2      // AF_INET
	mov x1, #1      // SOCK_STREAM
	eor x2, x2, x2  // 0
	mov x8, #SYS_socket
	svc #0
	str w0, [x29, #-4]

	mov x1, #1     // SOL_SOCKET
	mov x2, #15    // SO_REUSEPORT
	mov w3, #0
	str w3, [x29, #-24]
	add x3, x29, #-24
	mov x4, #4
	mov x8, #SYS_setsockopt
	svc #0

	mov w0, #2     // AF_INET
	strh w0, [x29, #-20]
	mov w0, #8080  // port
	bl htons
	strh w0, [x29, #-18]
	mov w0, #0     // addr
	str w0, [x29, #-16]

	ldr w0, [x29, #-4]
	add x1, x29, #-20
	mov x2, #16
	mov x8, #SYS_bind
	svc #0
	cmp x0, #0
	beq ._start.1
	mov x1, #8080
	bl perror
._start.1:

	ldr w0, [x29, #-4]
	mov x1, #3
	mov x8, #SYS_listen
	svc #0

._start.0:

	ldr w0, [x29, #-4]
	eor x1, x1, x1
	eor x2, x2, x2
	mov x3, #524288
	mov x8, #SYS_accept4
	svc #0

	mov x1, x0
	adr x0, client_func
	bl thread_create

	b ._start.0

	ldr w0, [x29, #-4]
	mov x8, #SYS_close
	svc #0

	eor x0, x0, x0
	b exit

exit:
	mov x8, #SYS_exit
	svc #0

perror:
	str x30, [sp, #128]!
	add x29, sp, #128
	stp x8, x0, [x29, #-16]
	str x1, [x29, #-24]
	eor x0, x0, x0
	str x0, [x29, #-40]
	mov x8, #SYS_brk
	svc #0
	str x0, [x29, #-32]
	add x0, x0, #4096
	svc #0
	ldr x1, [x29, #-32]
	adr x0, ERR_ERR
	str x0, [x1], #8
	bl strlen
	str x0, [x1], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	ldr x0, [x29, #-16]
	cmp x0, #SYS_bind
	bne .perror.0
	adr x0, ERR_bind
	str x0, [x1], #8
	bl strlen
	str x0, [x1], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	ldr x0, [x29, #-24]
	mov x3, x1
	add x1, x3, #48
	bl u2str
	str x1, [x3], #8
	mov x0, x1
	mov x2, x3
	bl strlen
	str x0, [x2], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	adr x0, ERR_bind
	mov x1, #1
	bl gstrbyidx
	str x0, [x2], #8
	bl strlen
	str x0, [x2], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	ldr x0, [x29, #-8]
	cmp x0, #-13
	bne .perror.bind.0
	adr x0, ERR_EACCESS
	str x0, [x2], #8
	bl strlen
	str x0, [x2], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	b .perror.end
.perror.bind.0:
	cmp x0, #-98
	bne .perror.no
	adr x0, ERR_EADDRINUSE
	str x0, [x2], #8
	bl strlen
	str x0, [x2], #8
	ldr x3, [x29, #-40]
	add x3, x3, #1
	str x3, [x29, #-40]
	b .perror.end
.perror.0:
.perror.no:
	adr x0, ERR_NO
	str x0, [x3], #8
	bl strlen
	str x0, [x3], #8
	ldr x0, [x29, #-8]
	neg x0, x0
	add x1, x3, #64
	bl u2str
	str x1, [x3], #8
	mov x0, x1
	bl strlen
	str x0, [x3], #8
	adr x0, ERR_NO
	mov x1, #1
	bl gstrbyidx
	str x0, [x3], #8
	bl strlen
	str x0, [x3], #8
.perror.end:
	mov x0, #1
	ldr x1, [x29, #-32]
	ldr x2, [x29, #-40]
	mov x8, #SYS_writev
	svc #0
	ldr x0, [x29, #-32]
	mov x8, #SYS_brk
	svc #0
	eor x0, x0, x0
	b exit

.data

timeout: .quad 90000

ERR_ERR: .asciz "ERROR: "
ERR_bind: .asciz "Cannot bind to port \0: \0\n"
ERR_EACCESS: .asciz "Not enough permission.\n"
ERR_EADDRINUSE: .asciz "Address already in use.\n"
ERR_NO: .asciz "Unknown error \0.\n"

strspcds:
	.asciz "200 OK"
	.asciz "403 Forbidden"
	.asciz "404 Not Found"

pg404:
	.ascii "<html><head>\n"
	.ascii "<title>Not found</title>\n"
	.ascii "</head><body>\n"
	.ascii "<h1>Not found</h1>\n"
	.ascii "<p>Cannot find page on the requested path `/\0'.</p><hr>\n"
	.asciz "</body></html>\n"

pg403:
	.ascii "<html><head>\n"
	.ascii "<title>Forbidden</title>\n"
	.ascii "</head><body>\n"
	.ascii "<h1>Forbidden</h1>\n"
	.ascii "<p>You do not have permission to visit page on the requested path `\0'.</p><hr>\n"
	.asciz "</body></html>\n"

resp:
	.asciz "HTTP/1.1 \0\r\n"
	.asciz "Content-Type: text/html\r\n"
	.asciz "Connection: close\r\n\r\n"
