graphics_mode_number equ 13h
graphics_page_number equ 0

old_graphics_mode db ?
old_graphics_page db ?


enter_graphics_mode proc
    push    ax bx es

    xor     ax, ax
    mov     es, ax

    mov     al, byte ptr es:[449h]
    mov     byte ptr old_graphics_mode, al

    mov     al, byte ptr es:[462h]
    mov     byte ptr old_graphics_page, al

    xor     ah, ah
    mov     al, byte ptr graphics_mode_number
    int     10h

    mov     ah, 05h
    mov     al, byte ptr graphics_page_number
    int     10h

    pop     es bx ax

    ret
enter_graphics_mode endp


exit_graphics_mode proc
    push    ax bx es

    xor     ah, ah
    mov     al, byte ptr old_graphics_mode
    int     10h

    mov     ah, 05h
    mov     al, byte ptr old_graphics_page
    int     10h

    pop     es bx ax
    ret
exit_graphics_mode endp
