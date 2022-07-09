.globl _start

.equ SYS_close, 57
.equ SYS_write, 64
.equ SYS_exit, 93
.equ SYS_socket, 198
.equ SYS_bind, 200
.equ SYS_listen, 201
.equ SYS_munmap, 215
.equ SYS_mremap, 216
.equ SYS_mmap, 222
.equ SYS_accept4, 242 // Simple accept does not working on RMX3085, idk why, thus i use accept4

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

_start:
	stp x29, x30, [sp, #-64]!
	add x29, sp, #64

	mov x0, #2      // AF_INET
	mov x1, #1      // SOCK_STREAM
	eor x2, x2, x2  // 0
	mov x8, #SYS_socket
	svc #0
	str w0, [x29, #-4]

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

	ldr w0, [x29, #-4]
	mov x1, #3
	mov x8, #SYS_listen
	svc #0

._start.0:

	ldr w0, [x29, #-4]
	eor x1, x1, x1
	eor x2, x2, x2
	eor x3, x3, x3
	mov x8, #SYS_accept4
	svc #0

	str w0, [x29, #-24]

	adr x0, resp
	mov x1, x0
	bl strlen
	mov x2, x0
	ldr w0, [x29, #-24]
	mov x8, #SYS_write
	svc #0

	ldr w0, [x29, #-24]
	mov x8, #SYS_close
	svc #0

	b ._start.0

	ldr w0, [x29, #-4]
	mov x8, #SYS_close
	svc #0

	eor x0, x0, x0
	b exit

exit:
	mov x8, #SYS_exit
	svc #0

.data

resp:
	.ascii "HTTP/1.1 200 OK\r\n"
	.ascii "Content-Type: text/html\r\n"
	.ascii "Connection: close\r\n\r\n"
	.ascii "<html><head>\n"
	.ascii "<title>Server is not implemented</title>\n"
	.ascii "</head><body>\n"
	.ascii "<h1>Server is not implemented yet.</h1>\n"
	.ascii "</body></html>\n"
