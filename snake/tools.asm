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


;ax - milliseconds amount
wait_milliseconds proc
    push    ax dx cx

    mov     cx, 1000
    mul     cx

    mov     cx, dx
    mov     dx, ax

    mov     ah, 86h
    int     15h

    pop     cx dx ax
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
