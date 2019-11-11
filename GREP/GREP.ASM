.model tiny
.code

org 100h

locals @@

_start:
    jmp call_main

    DTA                db 50 dup(0)

    usage              db "Usage: grep <mask> <pattern> <?outfile>", 0dh, 0ah, '$'
    usage_length       equ $ - usage

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

zeromem proc
@@length equ [bp + 4]
@@buffer equ [bp + 6]
    push bp
    mov bp, sp

    push di
    push cx
    push ax

    mov cx, @@length
    mov di, @@buffer
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

shift_left proc
@@buffer equ [bp + 6]
@@length equ [bp + 4]    

    push bp
    mov bp, sp

    push di
    push si
    push cx

    mov di, @@buffer
    lea si, [di + 1]
    mov cx, @@length
    dec cx

    rep movsb

    pop cx
    pop si
    pop di

    mov sp, bp
    pop bp
    ret
shift_left endp

strlen proc
@@string equ [bp + 4]

    push bp
    mov bp, sp

    push si
    mov si, @@string

    xor ax, ax

@@l1:
    lodsb
    test al, al
    jz @@l2
    inc ah
    jmp @@l1

@@l2:
    pop si

    mov al, ah
    xor ah, ah

    mov sp, bp
    pop bp
    ret
strlen endp

memcmp proc
@@n    equ [bp + 4]
@@str2 equ [bp + 6]
@@str1 equ [bp + 8]

    push bp
    mov bp, sp

    push si
    push di
    push cx

    mov si, @@str1
    mov di, @@str2    
    mov cx, @@n

    xor ax, ax

@@l1:
    cmpsb

    je @@eq
    mov ax, 1
@@eq:
    loop @@l1

    pop cx
    pop di
    pop si

    mov sp, bp
    pop bp
    ret
memcmp endp

get_pattern_count_at_file proc
@@filename       equ [bp + 6]
@@pattern        equ [bp + 4]
@@handle         equ [bp - 2]
@@pattern_length equ [bp - 4]
@@count          equ [bp - 6]
@@buffer_len     equ 100
@@buffer         equ [bp - @@buffer_len - 6]

    push bp
    mov bp, sp
    sub sp, 6 + @@buffer_len

    push bx
    push cx
    push dx
    push si
    push di
 
    mov di, @@pattern
    push di
    call strlen
    add sp, 2

    mov @@pattern_length, ax

    mov word ptr @@count, 0

    mov ah, 3dh
    mov al, 0
    mov dx, @@filename
    int 21h

    jc @@end

    mov @@handle, ax
    mov bx, ax

    lea dx, @@buffer
    mov ah, 3fh
    mov cx, @@pattern_length
    int 21h

    cmp ax, @@pattern_length
    jl @@end

@@searching:
    mov ax, @@pattern
    push ax
    lea ax, @@buffer
    push ax
    mov ax, @@pattern_length
    push ax
    call memcmp
    add sp, 6

    test ax, ax
    jnz @@not_found

    inc word ptr @@count

@@not_found:
    lea dx, @@buffer
    mov cx, @@pattern_length
    push dx
    push cx
    call shift_left
    add sp, 4

    dec cx
    add dx, cx
    mov ah, 3fh
    mov cx, 1
    int 21h

    test ax, ax
    jz @@searching_end

    jmp @@searching

@@searching_end:
    mov bx, @@handle
    mov ah, 3eh
    int 21h

@@end:
    mov ax, @@count

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    mov sp, bp
    pop bp
    ret
get_pattern_count_at_file endp

print_result proc
@@filename equ [bp + 6]
@@count    equ [bp + 4]   
    
    push bp
    mov bp, sp

    push ax
    push si

    mov si, @@filename
    xor ax, ax

@@name_printing:
    lodsb
    push ax
    call put_smb
    add sp, 2

    test al, al
    jnz @@name_printing

    mov ax, ' '
    push ax
    call put_smb
    add sp, 2

    push @@count
    call print_num
    add sp, 2

    mov ax, 0dh
    push ax
    call put_smb
    add sp, 2
    
    mov ax, 0ah
    push ax
    call put_smb
    add sp, 2

    pop si
    pop ax

    mov sp, bp
    pop bp
    ret
print_result endp

output_result_to_screen proc
    push bp
    mov bp, sp

    push ax
    push dx

    mov ax, '$'
    push ax
    call put_smb
    add sp, 2

    mov ah, 9
    lea dx, result_string
    int 21h

    pop dx
    pop ax

    mov sp, bp
    pop bp
    ret
output_result_to_screen endp

output_result_to_file proc
@@filename equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx

    mov ah, 3ch
    mov cx, 2
    mov dx, @@filename
    int 21h

    jc @@to_end

    mov bx, ax
    mov cx, result_pointer
    sub cx, offset result_string
    mov ah, 40h
    lea dx, result_string
    int 21h

    mov ah, 3eh
    int 21h

@@to_end:
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
output_result_to_file endp

main proc
@@argc equ [bp - 2]
@@argv equ [bp - 4]

    push bp
    mov bp, sp
    sub sp, 6

    mov ax, [bp + 4]
    mov @@argv, ax
    mov ax, [bp + 6]
    mov @@argc, ax

    cmp byte ptr @@argc, 2
    je @@valid

    cmp byte ptr @@argc, 3
    je @@valid

    mov ah, 9
    lea dx, usage
    int 21h
    
    mov ax, 1

    jmp @@to_return

@@valid:
    mov ah, 1ah
    lea dx, DTA
    int 21h

    xor cx, cx
    mov ah, 4eh
    mov bx, @@argv
    mov dx, [bx]
    int 21h

    mov bx, @@argv
    mov dx, 2[bx]
    lea bx, 1eh[DTA]

@@files_enumerating:
    jc @@enumeration_end

    push bx
    push dx
    call get_pattern_count_at_file
    add sp, 4

    push bx
    push ax
    call print_result
    add sp, 4

    mov ah, 4fh
    int 21h
    jmp @@files_enumerating

@@enumeration_end:
    cmp byte ptr @@argc, 3
    je @@to_file

    call output_result_to_screen

    jmp @@return_zero

@@to_file:
    mov bx, @@argv
    mov bx, 4[bx]
    push bx
    call output_result_to_file
    add sp, 2

@@return_zero:
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
