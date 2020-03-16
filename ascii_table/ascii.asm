.model tiny
.code
org 100h

locals @@

start:
    jmp     actual_start

    modenum dw ?
    pagenum dw ?

read_num proc
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
read_num endp


find_non_space proc
@@find_loop:
    lodsb

    cmp     al, ' '
    je      @@find_loop

    cmp     al, 9
    je      @@find_loop

    dec     si
    ret
find_non_space endp


parse_arguments proc
    push    bx
    push    cx
    push    dx

    mov     si, 81h

    call    find_non_space

    cmp     al, 0Dh
    je     @@failed

    call    read_num
    mov     word ptr modenum, ax

    call    find_non_space

    cmp     al, 0Dh
    je     @@failed

    call    read_num
    mov     word ptr pagenum, ax

@@success:
    xor     ax, ax
    jmp     @@to_return

@@failed:
    mov     ax, 1

@@to_return:
    pop     dx
    pop     cx
    pop     bx
    ret
parse_arguments endp


usage db 'Usage: ascii <mode number> <page number>', 10, 13, '$'

actual_start:
    call    parse_arguments

    test    ax, ax
    jnz     @@print_usage

    mov     ax, word ptr modenum
    mov     ax, word ptr pagenum    

    jmp     @@to_return

@@print_usage:
    mov     ah, 09h
    mov     dx, offset usage
    int     21h

@@to_return:
    ret
end start