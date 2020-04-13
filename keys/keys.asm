.model tiny
.code
org 100h

locals @@

start:
    jmp     actual_start

quote               equ 22h
key_info_str        db 'ascii code - '
ascii_code_place    db 30h, 30h, 'h'
                    db '   scan code - '
scan_code_place     db 30h, 30h, 'h'
                    db '   symbol - ', quote, '$'
end_line            db quote, 10, 13, '$'

transform_to_hex proc
    add     al, '0'
    cmp     al, '9'
    jna     @@to_return
    add     al, 'A' - '9' + 1
@@to_return:
    ret
transform_to_hex endp

get_printable_char proc
    cmp     al, 20h
    jb      @@replace_with_space

    jmp     @@to_return

@@replace_with_space:
    mov     al, ' '

@@to_return:
    ret
get_printable_char endp

insert_code_info proc
    push    ax
    push    bx
    mov     bx, ax

    shr     al, 4
    call    transform_to_hex
    mov     byte ptr [ascii_code_place], al

    mov     ax, bx
    and     al, 0Fh
    call    transform_to_hex
    mov     byte ptr [ascii_code_place + 1], al

    mov     ax, bx
    shr     ax, 12
    call    transform_to_hex
    mov     byte ptr [scan_code_place], al

    mov     ax, bx
    and     ax, 0F00h
    shr     ax, 8
    call    transform_to_hex
    mov     byte ptr [scan_code_place + 1], al

    pop     bx
    pop     ax
    ret
insert_code_info endp

print_key_info proc
    push    ax
    push    dx

    call    insert_code_info

    mov     ah, 9
    lea     dx, key_info_str
    int     21h

    call    get_printable_char
    mov     dl, al
    mov     ah, 2
    int     21h

    mov     ah, 9
    lea     dx, end_line
    int     21h

    pop     dx
    pop     ax
    ret
print_key_info endp

help_string db 'This program will print info about keys you will press.', 10, 13
            db 'Use <ESC> key to exit.', 10, 13, '$'

actual_start:
    mov     ah, 9
    lea     dx, help_string
    int     21h

@@infinite_loop:
    xor     ah, ah
    int     16h
    call    print_key_info
    cmp     ax, 011Bh
    jne     @@infinite_loop
    ret
end start
