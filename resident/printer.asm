.model tiny

.code

org 100h

_start:
    jmp     program_start

    my_useful_message db "Hello! This is very important message!", 10, 13, '$'
    my_useful_message_2 db 10, 13, "Hello! This is second important message! HaVe YoU GOT it???", 10, 13, '$'

program_start:
    mov     ah, 09h
    lea     dx, my_useful_message
    int     21h

    lea     si, my_useful_message_2

second_printing:
    lodsb
    cmp     al, '$'
    je      second_printing_end

    mov     dl, al
    mov     ah, 02h
    int     21h

    jmp     second_printing

second_printing_end:
    ret
end _start
