
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
    jl @@@@to_return

    cmp al, '9'
    jg @@@@to_return

    sub al, '0'

    xchg bx, ax
    mov dx, 10
    mul dx

    add ax, bx

    xchg bx, ax

    jmp @@1

@@@@to_return:
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


to_int proc
    push    cx
    push    bx
    push    dx

    mov     bx, 10
    xor     ax, ax
    xor     cx, cx

@@read_loop:
    mov     cl, [si]
    inc     si

    cmp     cl, '0'
    jb      @@read_loop_end

    cmp     cl, '9'
    ja      @@read_loop_end

    sub     cl, '0'

    mul     bx
    add     ax, cx

    jmp     @@read_loop

    @@read_loop_end:
    pop     dx
    pop     bx
    pop     cx

    ret
to_int endp