.model tiny
.code

org 100h

_start:
	jmp skip_data

	arguments_count_string: db "Total arguments count: ", '$'


skip_data:
	xor cx, cx
	mov cl, byte ptr ds:[80h]
	add cx, 2
	mov si, 81h
	mov ah, 02h

	xor bx, bx

printing:
	dec cx
	jz printing_end
	lodsb
	test bl, bl
	jnz state_1

state_0:
	cmp al, ' '
	je printing
	mov dl, al
	int 21h
	mov bl, 1
	jmp printing
	
state_1:
	cmp al, ' '
	je space
	cmp al, 0dh
	je space
	
not_space:
	mov dl, al
	int 21h
	jmp printing

space:
	mov dl, 0dh
	int 21h
	mov dl, 0ah
	int 21h
	inc bh
	jmp printing

printing_end:

	xor ax, ax
	mov al, bh
	xor cx, cx

dividing:
	xor dx, dx
	mov bx, 10
	div bx
	add dx, '0'
	push dx
	inc cx
	test ax, ax
	jnz dividing

	mov ah, 09h
	lea dx, arguments_count_string
	int 21h

	mov ah, 02h
printing_number:	
	pop dx
	int 21h
	
	loop printing_number

	mov dl, 0ah
	int 21h
	mov dl, 0dh
	int 21h

	ret

end _start
