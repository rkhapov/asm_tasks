.model tiny
.code

org 100h

_start:

	jmp skip_procedures

ten: dw 10

print_num:
	push bp
	mov bp, sp
	mov ax, [bp + 4]
	xor cx, cx

dividing:
	mov bx, 10
	xor dx, dx
	div bx
	add dx, '0'
	inc cx
	push dx
	test ax, ax
	jnz dividing	

	mov ah, 02h

printing:
	pop dx
	int 21h	

	loop printing

	pop bp
	ret

factorial:
	push bp
	mov bp, sp
	push bx

	mov ax, [bp + 4]

	cmp ax, 1
	jbe end_recursion

	mov bx, ax
	dec ax
	push ax
	call factorial
	add sp, 2
	
	mul bx

end_recursion:

	pop bx
	pop bp

	ret

get_num_from_args:
	push bp
	mov bp, sp
	push cx
	push bx

	mov si, 82h
	xor cx, cx
	xor ax, ax

stacking:
	lodsb
	cmp al, ' '
	je stacking_end
	cmp al, 0dh
	je stacking_end
	sub ax, '0'
	push ax
	inc cx
	jmp stacking
stacking_end:

	xor ax, ax

summing:
	xor dx, dx
	mul word ptr [ten]
	pop bx
	add ax, bx

	loop summing

	pop bx
	pop cx
	pop bp
	ret

skip_procedures:
	call get_num_from_args

	push ax
	call factorial
	add sp, 2

	push ax
	call print_num
	add sp, 2

	ret

end _start

