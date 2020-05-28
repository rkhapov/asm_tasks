
memcpy proc
@@src equ [bp + 6]
@@dst equ [bp + 4]

    push    bp
    mov     bp, sp

    push    ax
    push    si
    push    di

    mov     si, @@src
    mov     di, @@dst

@@1:
    lodsb
    stosb

    test    al, al
    jnz     @@1

    pop     di
    pop     si
    pop     ax

    mov     sp, bp
    pop     bp
    ret
memcpy endp


strlen proc
    push    bp
    mov     bp, sp

    push    si

    xor     ah, ah

@@cycle:
    lodsb
    test    al, al
    jz      @@cycle_end

    inc     ah

    jmp     @@cycle

@@cycle_end:
    xchg    al, ah
    pop     si

    mov     sp, bp
    pop     bp
    ret
strlen endp


zeromem proc
@@length equ [bp + 4]
@@buffer equ [bp + 6]
    push    bp
    mov     bp, sp

    push    di
    push    cx
    push    ax

    mov     cx, @@length
    mov     di, @@buffer
    xor     ax, ax

@@zeroing:
    stosb

    dec     cx
    jnz     @@zeroing

    pop     ax
    pop     cx
    pop     di

    mov     sp, bp
    pop     bp
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


;ax - number
;cl - digit
divide_and_get_right_digit proc
    push    bx dx

    xor     dx, dx
    mov     bx, 10
    div     ax

    add     dl, '0'
    mov     cl, dl

    pop     dx bx
    ret
endp