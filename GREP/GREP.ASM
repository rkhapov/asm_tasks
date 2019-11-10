.model tiny
.code

org 100h

locals @@

_start:
    jmp call_main

    usage db "Usage: grep <mask> <patter>", 0dh, 0ah, '$'

    arguments_count    db 0
    arguments_table    db 300 dup(0)
    arguments_pointers dw 30 dup(0)
    next_argument      dw arguments_pointers
    free_table_pointer dw arguments_table

zeromem proc
    push bp
    mov bp, sp

    push di
    push cx
    push ax

    mov cx, [bp + 4]
    mov di, [bp + 6]
    xor ax, ax

@@zeroing:
    stosb

    dec cx
    jnz @@zeroing

    pop ax
    pop cx
    pop di

    mov sp, bp
    pop bp
    ret
zeromem endp

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
@@buffer equ [bp - @@buffer_len]
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

main proc
@@argc equ [bp - 2]
@@argv equ [bp - 4]

    push bp
    mov bp, sp
    sub sp, 4

    mov ax, [bp + 4]
    mov @@argv, ax
    mov ax, [bp + 6]
    mov @@argc, ax

    cmp byte ptr @@argc, 2
    je @@valid

    mov ah, 9
    lea dx, usage
    int 21h

    mov ax, 1
    jmp @@to_return

@@valid:

    xor ax, ax

@@to_return:
    mov sp, bp
    pop bp
    ret
main endp

call_main:
    call parse_arguments

    xor ax, ax
    mov al, arguments_count
    push ax
    lea ax, arguments_pointers
    push ax
    call main

    mov ah, 4Ch
    int 21h
end _start
