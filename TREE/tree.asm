.model tiny
.code

org 100h

locals @@

_start:
    jmp call_main

    tab_size equ 2
    tab_char equ ' '
    line equ 179
    close_line equ 192
    branch equ 195
    horizontal_line equ 196

    DTA                db 50 dup(0)

    usage              db "Usage: tree <path> -d depth -f search_suffix", 0dh, 0ah, '$'
    usage_length       equ $ - usage

    arguments_count    db 0
    arguments_table    db 100 dup(0)
    arguments_pointers dw 30 dup(0)
    next_argument      dw arguments_pointers
    free_table_pointer dw arguments_table
    result_string      db 100 dup('?')
    result_pointer     dw result_string

    files_mask         db '/', '*', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 50 (0)
    max_depth          dw 100

    get_arg_value_buffer db 100 dup(0)

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

print_tab proc
    push ax
    push dx
    push cx

    xor cx, cx
    mov ah, 02h

@@_1:
    mov dl, tab_char
    int 21h

    inc cx

    cmp cx, tab_size
    jb @@_1

    pop cx
    pop dx
    pop ax

    ret
print_tab endp


print_string proc
@@line equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push dx
    push si

    mov si, @@line

@@_1:
    lodsb

    test al, al
    jz @@_2

    mov ah, 02h
    mov dl, al
    int 21h

    jmp @@_1

@@_2:

    mov dl, 0dh
    int 21h

    mov dl, 0ah
    int 21h

    pop si
    pop dx
    pop ax

    mov sp, bp
    pop bp
    ret
print_string endp


print_name proc
@@name equ [bp + 8]
@@depth equ [bp + 6]
@@actual_depth equ [bp + 4]

@@i equ [bp - 2]

    push bp
    mov bp, sp
    sub sp, 2

    push ax
    push bx
    push cx
    push dx

    mov ax, @@depth
    mov bx, max_depth

    cmp ax, bx
    jnb @@to_return

    mov word ptr @@i, 0

    mov cx, word ptr @@depth
    sub cx, word ptr @@actual_depth

@@print_tabs:
    mov ax, word ptr @@i
    cmp ax, cx
    jae @@print_tabs_end

    mov ah, 02h
    mov dl, tab_char
    int 21h

    call print_tab

    inc word ptr @@i
    jmp @@print_tabs

@@print_tabs_end:
    mov word ptr @@i, 0

    mov cx, word ptr @@actual_depth
    dec cx

@@print_separators:
    mov ax, word ptr @@i
    cmp ax, cx
    jae @@print_separators_end

    mov ah, 02h
    mov dl, line
    int 21h

    call print_tab

    inc word ptr @@i
    jmp @@print_separators

@@print_separators_end:
    mov ah, 02h
    mov dl, branch
    int 21h

    mov ah, 02h
    mov dl, horizontal_line
    int 21h

    mov dl, tab_char
    int 21h

    mov ax, @@name
    push ax
    call print_string
    add sp, 2

@@to_return:
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_name endp


print_files proc
@@path         equ [bp + 8]
@@depth        equ [bp + 6]
@@actual_depth equ [bp + 4]

@@buffer_size equ 100
@@buffer      equ [bp - @@buffer_size]

    push bp
    mov bp, sp

    push ax

    lea ax, @@path
    push ax
    lea ax, @@buffer
    push ax
    call memcpy
    add sp, 4

    lea ax, @@buffer
    push ax
    lea ax, files_mask
    push ax
    call strconcat
    add sp, 4

    xor cx, cx
    mov ah, 4eh
    lea dx, @@buffer
    int 21h

@@enumerate_files:
    jc @@enumerating_end

    lea ax, 1eh[DTA]
    push ax
    mov ax, @@depth
    push ax
    mov ax, @@actual_depth
    call print_name
    add sp, 6

    mov ah, 4fh
    int 21h
    jmp @@enumerate_files

@@enumerating_end:
    pop ax

    mov sp, bp
    pop bp
    ret
print_files endp


print_directories proc
@@path         equ [bp + 8]
@@depth        equ [bp + 6]
@@actual_depth equ [bp + 4]

@@buffer_size equ 100
@@buffer      equ [bp - @@buffer_size]

    ret
print_directories endp


print_dir proc
@@path         equ [bp + 8]
@@depth        equ [bp + 6]
@@actual_depth equ [bp + 4]

@@buffer_size equ 100
@@buffer      equ [bp - @@buffer_size]

    push bp
    mov bp, sp
    add sp, @@buffer_size

    push ax
    
    mov ax, @@path
    push ax
    mov ax, @@depth
    push ax
    mov ax, @@actual_depth
    push ax
    call print_files
    add sp, 6

    mov ax, @@path
    push ax
    mov ax, @@depth
    push ax
    mov ax, @@actual_depth
    push ax
    call print_directories
    add sp, 6

    pop ax

    mov sp, bp
    pop bp
    ret
print_dir endp


strtonum proc
@@string equ [bp + 4]

    push bp
    mov bp, sp

    push bx
    push cx
    push dx
    push si

    xor ax, ax
    xor cx, cx
    xor bx, bx
    mov si, @@string

@@1:
    lodsb

    cmp al, '0'
    jl @@2

    cmp al, '9'
    jg @@2

    sub al, '0'

    xchg bx, ax
    mov dx, 10
    mul dx

    add ax, bx

    xchg bx, ax

    jmp @@1

@@2:
    mov ax, bx

    pop si
    pop dx
    pop cx
    pop bx

    mov sp, bp
    pop bp
    ret
strtonum endp


memcpy proc
@@src equ [bp + 6]
@@dst equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push si
    push di

    mov si, @@src
    mov di, @@dst

@@1:
    lodsb
    stosb

    test al, al
    jnz @@1

    pop di
    pop si
    pop ax

    mov sp, bp
    pop bp
    ret
memcpy endp


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
    mov cx, word ptr @@argc

@@1:
    mov ax, word ptr @@i
    cmp ax, cx
    jnb @@3

    mov bx, @@argv
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


strconcat proc
@@src equ [bp + 6]
@@dst equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push si
    push di

    mov si, @@dst

@@to_zero:
    lodsb

    test al, al
    jnz @@to_zero

    mov di, si
    mov si, @@src

@@1:
    lodsb
    stosb

    test al, al
    jnz @@1

    pop di
    pop si
    pop ax

    mov sp, bp
    pop bp
    ret
strconcat endp


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
    lea ax, files_mask
    push ax
    call strconcat
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

    cmp ax, 1

    jl @@invalid_args

    mov ah, 1ah
    lea dx, DTA
    int 21h

    mov ax, @@argc
    push ax
    mov ax, @@argv
    push ax
    call configure_parameters
    add sp, 4

    mov bx, @@argv
    mov bx, [bx]
    push bx
    mov ax, 0
    push ax
    push ax
    call print_dir
    add sp, 6

    jmp @@to_return

@@invalid_args:
    mov ah, 09h
    lea dx, usage
    int 21h

@@to_return:
    xor ax, ax

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
