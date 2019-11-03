.model tiny
.code
org 100h

locals @@

_start:
    jmp skip_declarations

array dw 9, 6, 10, 1, 4, 2, 9, 1, 14, 0, 0, 5, 9, 10
array_length equ ($ - array) / 2

print_num proc
    push bp
    mov bp, sp
    push ax
    push bx
    push dx 
    push cx

    xor cx, cx
    mov ax, [bp + 4]
    mov bx, 10

@@dividing:
    xor dx, dx
    div bx
    add dx, '0'
    push dx    

    inc cx
    test ax, ax
    jnz @@dividing

    mov ax, 0200h

@@printing:
    pop dx
    int 21h

    dec cx
    jnz @@printing

    pop cx
    pop dx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret
print_num endp

print_array proc
    push bp
    mov bp, sp

    push ax
    push bx
    push cx

    mov cx, array_length
    lea si, array

@@printing:
    lodsw
    push ax
    call print_num
    add sp, 2

    mov ax, 0200h
    mov dl, ' '
    int 21h

    dec cx
    jnz @@printing

    mov ax, 0200h
    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h

    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_array endp

swap proc
    push bp
    mov bp, sp
    push bx
    push ax
    push cx

    mov bx, [bp + 4]
    mov ax, [bx]
    mov bx, [bp + 6]

    mov cx, [bx]
    mov [bx], ax

    mov bx, [bp + 4]
    mov [bx], cx

    pop cx
    pop ax
    pop bx
    mov sp, bp
    pop bp
    ret
swap endp

partition proc
    push bp
    mov bp, sp
    sub sp, 8
    push bx
    push cx
    push dx

    mov ax, [bp + 6]
    add ax, [bp + 8]
    and ax, 0FFFEh

    mov bx, [bp + 4]
    add bx, ax
    push bx
    mov bx, [bp + 4]
    mov cx, [bp + 8]
    shl cx, 1
    add bx, cx
    push bx
    call swap
    add sp, 4

    mov ax, [bx]
    mov [bp - 2], ax
    mov ax, [bp + 6]
    mov [bp - 4], ax
    mov [bp - 6], ax

@@looping:
    mov ax, [bp - 6]
    mov bx, [bp + 8]
    cmp ax, bx
    jge @@looping_end

    mov bx, [bp + 4]
    mov ax, [bp - 6]
    shl ax, 1
    add bx, ax
    mov bx, [bx]
    mov ax, [bp - 2]
    cmp bx, ax
    jge @@not_greater

    mov bx, [bp + 4]
    mov ax, [bp - 6]
    shl ax, 1
    add bx, ax
    push bx
    mov bx, [bp + 4]
    mov ax, [bp - 4]
    shl ax, 1
    add bx, ax
    push bx
    call swap
    add sp, 4

    inc word ptr [bp - 4]

@@not_greater:
    inc word ptr [bp - 6]

    jmp @@looping
@@looping_end:

    mov bx, [bp + 4]
    mov ax, [bp + 8]
    shl ax, 1
    add bx, ax
    push bx
    mov bx, [bp + 4]
    mov ax, [bp - 4]
    shl ax, 1
    add bx, ax
    push bx
    call swap
    add sp, 4

    mov ax, [bp - 4]

    pop dx
    pop cx
    pop bx

    mov sp, bp
    pop bp
    ret
partition endp


qsort proc
    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx

    mov cx, [bp + 4]
    mov dx, [bp + 6]
    mov bx, [bp + 8]

    cmp dx, bx
    jge @@no_sorting_needed

    push bx
    push dx
    push cx
    call partition
    add sp, 6

    dec ax
    push ax
    push dx
    push cx
    call qsort
    add sp, 6

    push bx
    add ax, 2
    push ax
    push cx
    call qsort
    add sp, 6

@@no_sorting_needed:

    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
qsort endp

skip_declarations:
    mov ax, array_length - 1
    push ax
    xor ax, ax
    push ax
    lea ax, array
    push ax
    call qsort
    add sp, 6

    call print_array

    ret
end _start