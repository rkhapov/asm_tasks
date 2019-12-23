
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
    dec di

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
