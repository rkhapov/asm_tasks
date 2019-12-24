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
    mov ah, 02h

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
@@name equ [bp + 10]
@@depth equ [bp + 8]
@@actual_depth equ [bp + 6]
@@is_last equ [bp + 4]

@@i equ [bp - 2]
@@count equ [bp - 4]

    push bp
    mov bp, sp
    sub sp, 4

    push ax
    push bx
    push cx
    push dx

    mov word ptr @@i, 0
    mov ax, @@depth
    mov word ptr @@count, ax

@@tabs:
    mov ax, @@i
    cmp ax, @@depth
    jnl @@tabs_end

    cmp ax, @@actual_depth
    jl @@as_tab

    mov ah, 02h
    mov dl, line
    int 21h

    jmp @@print_tab_call

@@as_tab:
    mov ah, 02h
    mov dl, tab_char
    int 21h

@@print_tab_call:

    call print_tab

    inc word ptr @@i
    jmp @@tabs

@@tabs_end:
 
@@to_return:

    mov ax, @@is_last
    test ax, ax
    jnz @@print_as_last

    mov dl, branch

    jmp @@to_print_name

@@print_as_last:
    mov dl, close_line

@@to_print_name:
    mov ah, 02h
    int 21h

    mov dl, horizontal_line
    int 21h

    mov dl, tab_char
    mov ah, 02h
    int 21h

    mov ax, @@name
    push ax
    call print_string
    add sp, 2


    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_name endp
