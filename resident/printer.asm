.model tiny

.code

org 100h

_start:
    jmp     program_start

    my_useful_message db "Hello! This is very important message!", 10, 13, '$'

program_start:
    mov     ah, 09h
    lea     dx, my_useful_message
    int     21h
    ret
end _start
