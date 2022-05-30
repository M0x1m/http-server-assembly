# "Dependencies" for this assembly buffers library:
#    1. memcpy(dest, src, cnt) = dest

.text

# The file buffer cannot buffered write to openned or attached file.
# The file buffer can only read, buffered writing is not implemented yet.
# struct FILEB{			// 65557 bytes length
#   int32_t fd;         // 4-byte
#   uint64_t file_sz;   // 8-byte
#   uint64_t file_offt; // 8-byte
#   uint16_t bufpos;    // 2-byte position in the file chunk stored in the buf
#   char buf[65535];    // 65535 byte chunk of file started from file_offt
# };

# The stream buffer cannot be open, only attached.
# struct STREAMB{		// 131082 bytes length
#   int32_t fd;			// 4-byte  file descriptor of stream
#   uint16_t rbufpos;	// 2-byte  read buffer position
#	uint16_t wbufpos;	// 2-byte  write buffer position
#   uint16_t rbufcap;   // 2-byte  read buffer length
#   uint16_t wbufcap;   // 2-byte  write buffer length
#   char rbuf[65535];	// 65535 byte read buffer
#   char wbuf[65535];	// 65535 byte write buffer
# };

_picktobuff:
# reads chunk without offsetting
# rdi - FILEB pointer
# ret rax - count of readed bytes
	lea 22(%rdi), %rsi
	mov $65535, %rdx
	mov 12(%rdi), %r10
	mov (%rdi), %edi
	mov $17, %rax
	syscall
	ret

_picktosrbuff:
# reads(read skips if fd read buffer is NULL) chunk into the stream read buffer
# rdi - STREAMB pointer
# rsi - timeout in millisecs to input wait
# ret rax - count of readed bytes
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $12, %rsp
	cmp $0, %rsi
	ja ._picktosrbuff.wait
	jmp ._picktosrbuff.next
._picktosrbuff.wait:
	mov %rsi, %rdx
	sub $8, %rsp
	mov (%rdi), %eax
	lea -20(%rbp), %rdi
	stosl
	movw $8193, (%rdi)
	lea -20(%rbp), %rdi
	mov $1, %rsi
	mov $7, %rax
	syscall
	testw $8216, 6(%rdi)
	jnz ._picktosrbuff.errret
	cmp $0, %rax
	jle ._picktosrbuff.timeo
	add $8, %rsp
	mov -8(%rbp), %rdi
._picktosrbuff.next:
	mov (%rdi), %edi
	mov $21531, %rsi
	lea -12(%rbp), %rdx
	mov $16, %rax
	syscall
	cmp $-1, %rax
	jle _procret
	cmpl $0, -12(%rbp)
	je ._picktosrbuff.errret
	cmpl $65535, -12(%rbp)
	jle ._picktosrbuff.0
	movl $65535, -12(%rbp)
._picktosrbuff.0:
	mov -8(%rbp), %rax
	lea 12(%rax), %rsi
	mov (%rax), %edi
	movsxd -12(%rbp), %rdx
	mov $0, %rax
	syscall
	mov -8(%rbp), %rdi
	add $8, %rdi
	stosw
	jmp _procret
._picktosrbuff.errret:
	mov $-1, %rax
	jmp _procret
._picktosrbuff.timeo:
	mov $-2, %rax
	jmp _procret

_buffload:
# reads next chunk and makes offset
# rdi - FILEB pointer
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov %rdi, %rsi
	add $4, %rsi
	lea -16(%rbp), %rdi
	movsq
	lea -24(%rbp), %rdi
	movsq
	addq $65535, -24(%rbp)
	lea -16(%rbp), %rsi # file size
	lea -24(%rbp), %rdi # file offset
	cmpsq
	jb ._buffload.eofret
	mov -8(%rbp), %rsi
	add $12, %rsi
	lea -16(%rbp), %rdi
	movsq
	mov -8(%rbp), %rax
	mov (%rax), %edi
	lea 22(%rax), %rsi
	mov $65535, %rdx
	mov -16(%rbp), %r10
	add $65535, %r10
	mov $17, %rax
	syscall
	cmp $0, %rax
	jle ._buffload.eofret
	mov -8(%rbp), %rdi
	movb $0, 22(%rdi, %rax)
	addq $65535, 12(%rdi)
	jmp _procret
._buffload.eofret:
	mov $-1, %rax
	jmp _procret

_getofft:
# returns numeric offset of the file
# rdi - FILEB pointer
	movzxw 20(%rdi), %rbx
	mov 12(%rdi), %rax
	add %rbx, %rax
	ret

_procret:
	mov %rbp, %rsp
	pop %rbp
	ret

_swwbuf:
# Writes wbuf to fd, sets 0 to wbufpos and wbufcap
# rdi - STREAMB pointer
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	movzxw 10(%rdi), %rdx
	lea 65547(%rdi), %rsi
	movsxd (%rdi), %rdi
	mov $1, %rax
	syscall
	mov -8(%rbp), %rdi
	movw $0, 10(%rdi)
	movw $0, 6(%rdi)
	jmp _procret

.globl buffseek    # buff prefix determines usage with files
.globl buffopen
.globl buffgetc
.globl buffclose
.globl buffattach
.globl sbuffattach # sbuff prefix determines usage with sockets, streams(stdout, stdin)
.globl sbuffgetc
.globl sbuffwrite
.globl sbuffflush
.globl sbuffclose
.globl sbuffread

.extern memcpy

sbuffattach:
# stream buffer attach
# edi - fd
# ret rax - STREAMB pointer
	push %rbp
	mov %rsp, %rbp
	mov %edi, -4(%rbp)
	sub $12, %rsp
	xor %rdi, %rdi
	mov $131082, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -12(%rbp)
	mov %rax, %rdi
	lea -4(%rbp), %rsi
	movsl
	mov -12(%rbp), %rdi
	xor %rsi, %rsi
	call _picktosrbuff
	mov -12(%rbp), %rax
	jmp _procret

sbuffgetc:
# returns a character stored in STREAMB.rbuf[STREAMB.rbufpos] and makes offset by incrementing STREAMB.rbufpos
# rdi - STREAMB pointer
# rsi - wait input timeout
# ret rax - readed 1-byte char
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	sub $16, %rsp
	lea 4(%rdi), %rsi
	lea 8(%rdi), %rdi
	cmpsw
	jl .sbuffgetc.nread
	mov -8(%rbp), %rdi
	mov -16(%rbp), %rsi
	call _picktosrbuff
	cmp $-1, %rax
	jle _procret
	mov -8(%rbp), %rdi
	movw $0, 4(%rdi)
.sbuffgetc.nread:
	mov -8(%rbp), %rdi
	movzxw 4(%rdi), %rbx
	movzxb 12(%rdi, %rbx), %rax
	incw 4(%rdi)
	mov -8(%rbp), %rdi
	jmp _procret

sbuffwrite:
# rdi - STREAMB pointer
# rsi - data pointer
# rdx - data length
# ret rax - stored length + sended length(if data length + wbufpos > 65535)
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	movq $0, -32(%rbp)
	sub $40, %rsp
	mov %rdx, -40(%rbp)
	movzxw 10(%rdi), %rax
	add %rax, -24(%rbp)
.sbuffwrite.0:
	cmpq $65535, -24(%rbp)
	jae .sbuffwrite.1
	cmpq $0, -24(%rbp)
	ja .sbuffwrite.2
	mov -32(%rbp), %rax
	jmp _procret
.sbuffwrite.1:
	mov -8(%rbp), %rax
	movzxw 10(%rax), %rbx
	mov $65535, %rdx
	sub %rbx, %rdx
	push %rdx
	mov -8(%rbp), %rdi
	movw $65535, 10(%rdi)
	lea 65547(%rdi, %rbx), %rdi
	mov -16(%rbp), %rsi
	call memcpy
	mov -8(%rbp), %rdi
	call _swwbuf
	pop %rbx
	sub %rax, -24(%rbp)
	add %rax, -32(%rbp)
	add %rbx, -16(%rbp)
	sub %rbx, -40(%rbp)
	jmp .sbuffwrite.0
.sbuffwrite.2:
	mov -8(%rbp), %rdi
	movzxw 6(%rdi), %rbx
	add %rbx, %rdi
	add $65547, %rdi
	mov -16(%rbp), %rsi
	mov -40(%rbp), %rdx
	call memcpy
	mov -8(%rbp), %rax
	lea 6(%rax), %rdi
	lea -24(%rbp), %rsi
	movsw
	add $2, %rdi
	lea -24(%rbp), %rsi
	movsw
	mov -40(%rbp), %rbx
	add %rbx, -32(%rbp)
	mov -8(%rbp), %rdi
	jmp _procret

sbuffflush:
# Writes buffer data stored in wbuf to fd
# rdi - STREAMB pointer
# ret rax - writed length
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov -8(%rbp), %rdi
	movzxw 10(%rdi), %rdx
	lea 65547(%rdi), %rsi
	mov (%rdi), %edi
	mov $1, %rax
	syscall
	sub $8, %rsp
	mov %rax, -16(%rbp)
	mov -8(%rbp), %rdi
	add $6, %rdi
	xor %ax, %ax
	stosw
	add $2, %rdi
	stosw
	mov -16(%rbp), %rax
	mov -8(%rbp), %rdi
	jmp _procret

sbuffclose:
# Deallocates the STREAMB buffers structure
# rdi - STREAMB pointer
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov (%rdi), %edi
	mov $3, %rax
	syscall
	mov -8(%rbp), %rdi
	mov $131082, %rsi
	mov $11, %rax
	syscall
	jmp _procret

sbuffread:
# Reads from stream up to %rdx bytes to %rsi
# rdi - STREAMB pointer
# rsi - buf
# rdx - len
# r10 - timeout to next read(-2 if you don't need any subsequent reads)
# ret rax - count of bytes writed to buf
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %rdx, -24(%rbp)
	mov %r10, -32(%rbp)
	sub $40, %rsp
	movzxw 8(%rdi), %rax
	sub 4(%rdi), %ax
	cmp -24(%rbp), %rax
	jl .sbuffread.0
	mov -16(%rbp), %rdi
	mov -8(%rbp), %rsi
	mov -24(%rbp), %rdx
	movzxw 4(%rsi), %rax
	add %rax, %rsi
	add $12, %rsi
	call memcpy
	mov -24(%rbp), %rax
	mov -8(%rbp), %rsi
	add %ax, 4(%rsi)
.sbuffread.ret:
	mov -8(%rbp), %rdi
	jmp _procret
.sbuffread.0:
	mov -16(%rbp), %rdi
	mov %rax, %rdx
	mov %rax, -40(%rbp)
	mov -8(%rbp), %rsi
	movzxw 4(%rsi), %rax
	add %rax, %rsi
	add $12, %rsi
	call memcpy
	mov -40(%rbp), %rax
	cmpq $-2, -32(%rbp)
	je .sbuffread.ret
	sub %rax, -24(%rbp)
	add %rax, -16(%rbp)
.sbuffread.1:
	mov -32(%rbp), %rsi
	mov -8(%rbp), %rdi
	call _picktosrbuff
	mov -8(%rbp), %rdi
	movw $0, 4(%rdi)
	cmp $0, %rax
	jg .sbuffread.2
	mov -40(%rbp), %rax
	jmp .sbuffread.ret
.sbuffread.2:
	cmp -24(%rbp), %rax
	jl .sbuffread.3
	mov -24(%rbp), %rdx
	mov -16(%rbp), %rdi
	mov -8(%rbp), %rsi
	add $12, %rsi
	call memcpy
	mov -40(%rbp), %rax
	add -24(%rbp), %rax
	jmp .sbuffread.ret
.sbuffread.3:
	mov -24(%rbp), %rdx
	mov -16(%rbp), %rdi
	mov -8(%rbp), %rsi
	add $12, %rsi
	call memcpy
	mov -8(%rbp), %rsi
	movzxw 8(%rsi), %rax
	sub %rax, -24(%rbp)
	add %rax, -16(%rbp)
	jmp .sbuffread.1

buffseek:
# rdi - FILEB pointer
# rsi - offset
# edx - whence (Like lseek: SEEK_SET, SEEK_CUR, SEEK_END)
# ret rax - finite file offset
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	mov %rsi, -16(%rbp)
	mov %edx, -20(%rbp)
	sub $36, %rsp
	cmp $0, %edx
	je .buffseek.ncur
	cmp $1, %edx
	je .buffseek.cur
	cmp $2, %edx
	je .buffseek.end
	mov $-1, %rax
	jmp _procret
.buffseek.cur:
	mov -8(%rbp), %rdi
	call _getofft
	add %rax, -16(%rbp)
	jmp .buffseek.ncur
.buffseek.end:
	mov -8(%rbp), %rdi
	mov 4(%rdi), %rax
	add %rax, -16(%rbp)
.buffseek.ncur:
	lea -16(%rbp), %rsi
	mov -8(%rbp), %rdi
	add $4, %rdi
	cmpsq
	jl .buffseek.2
	mov -8(%rdi), %rax
	lea -16(%rbp), %rdi
	stosq
.buffseek.2:
	cmpq $0, -16(%rbp)
	jg .buffseek.3
	movq $0, -16(%rbp)
.buffseek.3:
	mov -16(%rbp), %rax
	mov $65536, %rbx
	xor %rdx, %rdx
	idiv %rbx
	mov %rdx, -28(%rbp) # storing new bufpos
	mov -16(%rbp), %rax
	cmp $0, %rdx
	jge .buffseek.0
	neg %rdx
.buffseek.0:
	sub %rdx, %rax
	mov %rax, -36(%rbp) # storing new file offset
	lea -36(%rbp), %rdi
	mov -8(%rbp), %rsi
	add $12, %rsi
	cmpsq
	jne .buffseek.1
	mov %rsi, %rdi
	lea -28(%rbp), %rsi
	movsw
	jmp .buffseek.retofft
.buffseek.1:
	mov -28(%rbp), %ax
	mov -8(%rbp), %rdi
	add $20, %rdi
	stosw
	mov -8(%rbp), %rdi
	lea -36(%rbp), %rsi
	add $12, %rdi
	movsq
	mov -8(%rbp), %rdi
	call _picktobuff
	cmp $0, %rax
	mov -8(%rbp), %rdi
	jle _procret
.buffseek.retofft:
	mov -8(%rbp), %rsi
	mov 12(%rsi), %rax
	movzxw 20(%rsi), %rbx
	add %rbx, %rax
	mov -8(%rbp), %rdi
	jmp _procret

buffgetc:
# rdi - FILEB pointer
# ret rax - readed byte
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov %rdi, %rsi
	mov 4(%rsi), %rax
	lea -16(%rbp), %rdi
	stosq
	mov 12(%rsi), %rax
	lea -24(%rbp), %rdi 
	stosq
	movzxw 20(%rsi), %rax
	add %rax, -24(%rbp)
	lea -24(%rbp), %rdi
	lea -16(%rbp), %rsi
	cmpsq
	jb .buffgetc.eof
	mov -8(%rbp), %rdi
	cmpw $65535, 20(%rdi)
	jb .buffgetc.0
	call _buffload
	cmp $0, %rax
	jl _procret
	movw $0, 20(%rdi)
.buffgetc.0:
	movzxw 20(%rdi), %rax
	mov 22(%rdi, %rax), %al
	incw 20(%rdi)
	mov -8(%rbp), %rdi
	jmp _procret
.buffgetc.eof:
	mov $-1, %rax
	jmp _procret

buffclose:
# rdi - FILEB pointer
	push %rbp
	mov %rsp, %rbp
	mov %rdi, -8(%rbp)
	sub $8, %rsp
	mov (%rdi), %edi
	mov $3, %rax
	syscall
	mov -8(%rbp), %rdi
	mov $65558, %rsi
	mov $11, %rax
	syscall
	jmp _procret

buffattach:
# Attaches the file buffer to the specific file descripter
# edi - fd
# ret rax - FILEB pointer
	push %rbp
	mov %rsp, %rbp
	mov %edi, -4(%rbp)
	sub $156, %rsp
	lea -156(%rbp), %rsi
	mov $5, %rax
	syscall
	mov -132(%rbp), %eax
	and $0170000, %eax
	cmp $0100000, %eax
	jne .buffattach.errret
	xor %rdi, %rdi
	mov $65558, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -12(%rbp)
	mov %rax, %rdi
	mov -4(%rbp), %eax
	stosl
	mov -12(%rbp), %rdi
	add $4, %rdi
	mov -108(%rbp), %rax
	stosq
	mov -12(%rbp), %rdi
	call _picktobuff
	mov -12(%rbp), %rdi
	movb $0, 22(%rdi, %rax)
	mov -12(%rbp), %rax
	jmp _procret
.buffattach.errret:
	mov $-1, %rax
	jmp _procret

buffopen:
# rdi - file name
# rsi - flags
# rdx - mode
# ret rax - FILEB pointer
	push %rbp
	mov %rsp, %rbp
	mov $2, %rax
	syscall		# opening the file
	cmp $0, %rax
	jle .buffopen.errret.1
	mov %eax, -148(%rbp)
	sub $156, %rsp
	lea -144(%rbp), %rsi
	mov -148(%rbp), %edi
	mov $5, %rax
	syscall
	mov -120(%rbp), %eax
	andl $0170000, %eax
	cmpl $0100000, %eax
	jne .buffopen.errret.0
	xor %rdi, %rdi	# allocating memory
	mov $65558, %rsi
	mov $3, %rdx
	mov $34, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $9, %rax
	syscall
	mov %rax, -156(%rbp)	# storing fd
	mov %rax, %rdi
	mov -148(%rbp), %eax
	stosl
	mov -156(%rbp), %rdi	# storing file size
	add $4, %rdi
	mov -96(%rbp), %rax
	stosq
	mov -148(%rbp), %rdi # first buffer filling
	mov -156(%rbp), %rsi
	add $22, %rsi # offset to buf
	mov $65535, %rdx
	xor %r10, %r10
	mov $17, %rax
	syscall
	mov -156(%rbp), %rdi
	movb $0, 22(%rdi, %rax)
	mov -156(%rbp), %rax
	jmp _procret
.buffopen.errret.0:
	mov $3, %rax
	mov -148(%rbp), %edi
	syscall
	mov $-21, %rax
.buffopen.errret.1:
	jmp _procret
