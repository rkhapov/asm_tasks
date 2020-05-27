old_int9                    dw 0, 0
keyboard_buffer             db 20 dup(0)
keyboard_buffer_end:
keyboard_buffer_head        dw offset keyboard_buffer
keyboard_buffer_tail        dw offset keyboard_buffer


scancode_esc    equ 01h
scancode_up     equ 48h
scancode_down   equ 50h
scancode_left   equ 4Bh
scancode_right  equ 4Dh
scancode_p      equ 19h
scancode_enter  equ 1Ch


keyboard_push_at_buffer proc
    push    di
    push    bx
    push    bp

    mov     di, cs:keyboard_buffer_tail
    mov     bx, di
    inc     di

    cmp     di, offset keyboard_buffer_end
    jnz     @@pushing_at_tail

    mov     di, offset keyboard_buffer

@@pushing_at_tail:
    mov     bp, di
    cmp     di, cs:keyboard_buffer_head
    jz      @@overflow

    mov     di, bx
    mov     byte ptr cs:[di], al
    mov     cs:keyboard_buffer_tail, bp

@@overflow:
    pop     bp
    pop     bx
    pop     di
    ret
keyboard_push_at_buffer endp


keyboard_no_scancode equ 0


keyboard_pop_from_buffer proc
    push    bx

    call    keyboard_is_empty
    test    al, al
    jnz     @@empty_buffer

    mov     bx, keyboard_buffer_head
    mov     al, byte ptr ds:[bx]
    inc     bx

    cmp     bx, offset keyboard_buffer_end
    jnz     @@to_return

    mov     bx, offset keyboard_buffer

@@to_return:
    mov     keyboard_buffer_head, bx

    jmp     @@actual_return

@@empty_buffer:
    mov     al, keyboard_no_scancode

@@actual_return:
    pop     bx
    ret
keyboard_pop_from_buffer endp


keyboard_is_empty proc
    push    bx

    mov     al, 1

    mov     bx, keyboard_buffer_head
    cmp     bx, keyboard_buffer_tail
    jz      @@to_return

    xor     al, al

@@to_return:
    pop     bx

    ret
keyboard_is_empty endp


keyboard_clear_buffer proc
    mov     word ptr keyboard_buffer_head, offset keyboard_buffer
    mov     word ptr keyboard_buffer_tail, offset keyboard_buffer
    ret
endp


;al - scancode
keyboard_wait_until proc
    push    ax

    mov     ah, al

@@wait_loop:
    hlt
    call    keyboard_pop_from_buffer
    cmp     ah, al
    jne     @@wait_loop

    pop     ax
    ret
endp

keyboard_wait_key proc
    push    ax

@@loopa:
    call    keyboard_pop_from_buffer
    cmp     al, keyboard_no_scancode
    je      @@loopa

    pop     ax
    ret
keyboard_wait_key endp


my_int9 proc
    push    ax

    in      al, 60h
    call    keyboard_push_at_buffer

    mov     al, 20h
    out     20h, al

    pop     ax
    iret
my_int9 endp


keyboard_setup proc
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
keyboard_setup endp


keyboard_exit proc
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
keyboard_exit endp
