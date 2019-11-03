.model tiny
.code

org 100h

_start:
	jmp skip_data

	lemon_string db "lemon"
	lemon_len dw $ - lemon_string
	lemons_count_string db "Lemons count: ", '$'

skip_data:
	xor cx, cx
	xor bx, bx
	mov cl, byte ptr ds:[80h]
	cmp cx, lemon_len
    	jb printing_result
	sub cx, lemon_len
	inc cx
	xor dx, dx

lemon_finding:
	xor ax, ax
	mov si, 81h
	add si, dx
	lea di, lemon_string

local_finding:
	cmpsb
	jne local_finding_end

	inc ax
	cmp ax, lemon_len
	jb local_finding
local_finding_end:

	cmp ax, lemon_len
	jne not_found

	inc bx
	add dx, lemon_len
	dec dx

not_found:

	inc dx
	cmp dx, cx
	jb lemon_finding


printing_result:
        mov ax, bx
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
	lea dx, lemons_count_string
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
