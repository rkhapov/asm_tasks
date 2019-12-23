arguments_count    db 0
arguments_table    db 100 dup(0)
arguments_pointers dw 30 dup(0)
next_argument      dw arguments_pointers
free_table_pointer dw arguments_table
result_string      db 100 dup('?')
result_pointer     dw result_string

put_smb proc
@@char equ [bp + 4]

    push bp
    mov bp, sp

    push bx
    push ax

    mov ax, @@char

    test al, al
    jz @@to_end

    mov bx, result_pointer
    mov byte ptr [bx], al
    inc bx

    mov result_pointer, bx

@@to_end:

    pop ax
    pop bx

    mov sp, bp
    pop bp

    ret
put_smb endp

print_num proc
@@num equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push dx
    push cx

    mov ax, @@num
    mov bx, 10
    xor cx, cx

@@dividing:
    xor dx, dx
    div bx

    add dx, '0'
    push dx
    inc cx

    test ax, ax
    jnz @@dividing

@@printing:
    call put_smb
    add sp, 2

    loop @@printing

    pop cx
    pop dx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_num endp

put_next_argument proc
    push bp
    mov bp, sp

    push dx
    push ax
    push bx
    push si
    push di

    mov ax, free_table_pointer
    mov bx, next_argument
    mov [bx], ax
    
    add word ptr [next_argument], 2    

    mov si, [bp + 4]
    mov di, free_table_pointer

    xor dx, dx

@@copying:
    lodsb
    stosb

    inc dx

    test al, al
    jnz @@copying

    add word ptr [free_table_pointer], dx

    pop di
    pop si
    pop bx
    pop ax
    pop dx

    mov sp, bp
    pop bp
    ret
put_next_argument endp

parse_arguments proc
@@buffer_len equ 30h    
@@buffer     equ [bp - @@buffer_len]
    push bp
    mov bp, sp
    sub sp, @@buffer_len

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor cx, cx
	mov cl, byte ptr ds:[80h]
	add cx, 2
	mov si, 81h

	xor bx, bx

@@arguments_traverse:
	dec cx
	jz @@arguments_traverse_end
	lodsb
	test bl, bl
	jnz @@state_1

@@state_0:
	cmp al, ' '
	je @@arguments_traverse
    cmp al, 0dh
    je @@arguments_traverse
	mov bl, 1

    lea di, @@buffer
    push di
    mov dx, @@buffer_len
    push dx
    call zeromem
    add sp, 4

    stosb
	jmp @@arguments_traverse
	
@@state_1:
	cmp al, ' '
	je @@space
	cmp al, 0dh
	je @@space
	
@@not_@@space:
    stosb
	jmp @@arguments_traverse

@@space:
    lea di, @@buffer
    push di
    call put_next_argument
    add sp, 2

	inc bh
    xor bl, bl
	jmp @@arguments_traverse

@@arguments_traverse_end:
    mov arguments_count, bh

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
parse_arguments endp


get_arg_value_buffer db 100 dup(0)

get_arg_value proc
@@argc      equ [bp + 8]
@@argv      equ [bp + 6]
@@argletter equ [bp + 4]

@@i         equ [bp - 2]

    push bp
    mov bp, sp
    sub sp, 2

    push bx
    push cx
    push dx

    mov word ptr @@i, 0

@@1:
    mov ax, word ptr @@i
    cmp ax, word ptr @@argc
    jnb @@3

    mov bx, @@argv
    shl ax, 1
    add bx, ax
    mov bx, [bx]

    mov al, byte ptr [bx]
    cmp al, '-'
    jne @@continue

    mov al, byte ptr [bx + 1]
    mov cx, @@argletter
    cmp al, cl
    jne @@continue

    mov bx, @@argv
    mov ax, word ptr @@i
    inc ax
    shl ax, 1
    add bx, ax
    mov bx, [bx]
    push bx
    lea ax, get_arg_value_buffer
    push ax
    call memcpy
    add sp, 4

    lea ax, get_arg_value_buffer

    jmp @@2

@@continue:
    inc word ptr @@i
    jmp @@1
@@3:
    xor ax, ax

@@2:
    pop dx
    pop cx
    pop bx

    mov sp, bp
    pop bp
    ret
get_arg_value endp


configure_parameters proc
@@argc equ [bp + 6]
@@argv equ [bp + 4]

    push bp
    mov bp, sp

    push ax

    mov ax, @@argc
    push ax
    mov ax, @@argv
    push ax
    mov ax, 'f'
    push ax
    call get_arg_value
    add sp, 6

    test ax, ax
    jz @@no_suffix

    push ax
    lea ax, 2[files_mask]
    push ax
    call memcpy
    add sp, 4

@@no_suffix:
    mov ax, @@argc
    push ax
    mov ax, @@argv
    push ax
    mov ax, 'd'
    push ax
    call get_arg_value
    add sp, 6

    test ax, ax
    jz @@no_depth

    push ax
    call strtonum
    add sp, 2

    mov max_depth, ax

@@no_depth:
    pop ax

    mov sp, bp
    pop bp
    ret
configure_parameters endp
