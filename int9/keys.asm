.model tiny
.code
org 100h

locals @@

start:
    jmp     actual_start

    old_int9 dw 0, 0

    buffer  db 5 dup(0)
    buffer_end:
    head    dw offset buffer
    tail    dw offset buffer

push_at_buffer proc
    push    di
    push    bx
    push    bp

    mov     di, cs:tail
    mov     bx, di
    inc     di

    cmp     di, offset buffer_end
    jnz     @@pushing_at_tail

    mov     di, offset buffer

@@pushing_at_tail:
    mov     bp, di
    cmp     di, cs:head
    jz      @@overflow

    mov     di, bx
    mov     byte ptr cs:[di], al
    mov     cs:tail, bp

@@overflow:
    pop     bp
    pop     bx
    pop     di
    ret
push_at_buffer endp

pop_from_buffer proc
    push    bx

    mov     bx, head
    mov     al, byte ptr ds:[bx]
    inc     bx

    cmp     bx, offset buffer_end
    jnz     @@to_return

    mov     bx, offset buffer

@@to_return:
    mov     head, bx

    pop     bx
    ret
pop_from_buffer endp

my_int9 proc
    push    ax

    in      al, 60h
    call    push_at_buffer

    mov     al, 20h
    out     20h, al

    pop     ax
    iret
my_int9 endp

transform_to_hex proc
    add     dl, '0'
    cmp     dl, '9'
    jna     @@to_return
    add     dl, 7
@@to_return:
    ret
transform_to_hex endp

print_al proc
    push    ax
    push    bx
    push    dx

    mov     bl, al
    mov     dl, al
    and     dl, 0F0h
    shr     dl, 4
    call    transform_to_hex
    mov     ah, 02h
    int     21h

    mov     dl, bl
    and     dl, 0Fh
    call    transform_to_hex
    mov     ah, 02h
    int     21h

    mov     dl, 10
    mov     ah, 02h
    int     21h

    mov     dl, 13
    mov     ah, 02h
    int     21h

    pop     dx
    pop     bx
    pop     ax
    ret
print_al endp

setup_int9 proc
    push    ax
    push    ds
    push    si
    push    di

    xor     ax, ax
    mov     ds, ax
    mov     si, 36
    mov     di, offset old_int9
    movsw
    movsw

    cli
    mov     ax, offset my_int9
    mov     ds:36, ax
    mov     ax, cs
    mov     ds:38, ax
    sti

    pop     di
    pop     si
    pop     ds
    pop     ax
    ret
setup_int9 endp

restore_int9 proc
    push    ax
    push    ds
    push    es
    push    si
    push    di

    xor     ax, ax
    push    ax
    pop     es
    push    cs
    pop     ds
    mov     si, offset old_int9
    mov     di, 36

    cli
    movsw
    movsw
    sti

    pop     di
    pop     si
    pop     es
    pop     ds
    pop     ax
    ret
restore_int9 endp

help_string db 'This program will print scan codes of every keys you will press.', 10, 13
            db 'Use <ESC> key to exit.', 10, 13, '$'

esc_scancode equ 01h

actual_start:
    mov     ah, 9
    lea     dx, help_string
    int     21h

    call    setup_int9

@@infinite_loop:
    hlt

    mov     bx, head
    cmp     bx, tail
    jz      @@infinite_loop

@@print_buffer:
    mov     bx, head
    cmp     bx, tail
    jz      @@print_buffer_end

    call    pop_from_buffer

    call    print_al

    cmp     al, esc_scancode
    je      @@infinite_loop_end

    jmp     @@print_buffer

@@print_buffer_end:
    jmp     @@infinite_loop

@@infinite_loop_end:
    call    restore_int9

    ret
end start
