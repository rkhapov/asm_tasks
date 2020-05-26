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
