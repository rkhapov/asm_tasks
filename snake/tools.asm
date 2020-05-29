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


milliseconds_per_tick equ 50

;ax - milliseconds
;returns ax - ticks amount
milliseconds_to_ticks_amount proc
    push    bx dx

    xor     dx, dx
    mov     bx, milliseconds_per_tick
    div     bx

    pop     dx bx
    ret
endp


print_ax proc
    push    ax bx cx dx

    mov     dx, 4

@@lll:
    call    divide_and_get_right_digit
    push    ax dx

    mov     ah, 2
    mov     dl, cl
    int     21h

    pop     dx ax

    dec     dx
    jne     @@lll

    mov     ah, 2
    mov     dl, 10
    int     21h

    mov     ah, 2
    mov     dl, 13
    int     21h

    pop     dx cx bx ax
    ret
endp


print_1 proc
    push    ax dx

    mov     ah, 2
    mov     dl, '1'
    int     21h

    mov     ah, 2
    mov     dl, 10
    int     21h

    mov     ah, 2
    mov     dl, 13
    int     21h

    pop     dx ax
    ret
endp


;ax - milliseconds amount
wait_milliseconds proc
    push    ax dx cx es

    call    milliseconds_to_ticks_amount

    xor     cx, cx
    mov     es, cx

    mov     cx, word ptr es:[046Ch]
    add     cx, ax

@@waiting:
    hlt

    cmp     cx, word ptr es:[046Ch]
    jne     @@waiting

    pop     es cx dx ax
    ret
endp


read_timer_count proc
    mov     al, 00000000b
    out     43h, al
    in      al, 40h
    mov     ah, al
    in      al, 40h
    rol     ax, 8
    ret
endp


; ah - x al - y
generate_random_cords proc
    push    bx cx dx
    mov     ah, 5
    mov     al, 5
    call    read_timer_count
    mov     cx, ax
    mov     ah, 0
    mov     al, cl
    mov     dl, map_width
    xor     al, ch
    add     al, 37h
    mov     ah, 0
    div     dl
    mov     bh, ah
    mov     dl, map_height
    mov     ah, 0
    mov     al, ch
    xor     al, cl
    add     al, 37h
    mov     ah, 0
    div     dl
    mov     bl, ah
    mov     ax, bx
    pop     dx cx bx
    ret
endp


;bx - offset of msg
abort proc
    call    clear_screen
    mov     ah, 9
    int     21h
    mov     al, scancode_esc
    call    keyboard_wait_until
    int     20h
endp
