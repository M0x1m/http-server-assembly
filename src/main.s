.globl _start

.text
_start:

exit:
	mov $60, %rax
	syscall
