.model tiny
.code
org 100h

locals @@

start:
    jmp     actual_start

    modenum db ?
    pagenum db ?
    screen_height db ?
    screen_width db ?

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
    mov     byte ptr modenum, al

    call    find_non_space

    cmp     al, 0Dh
    je     @@failed

    call    read_num
    mov     byte ptr pagenum, al

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


column_middle db ?
lines_middle db ?

calc_middle proc
    push    ax

    mov     al, byte ptr screen_height
    shr     al, 1
    mov     byte ptr lines_middle, al

    mov     al, byte ptr screen_width
    shr     al, 1
    mov     byte ptr column_middle, al

    pop     ax

    ret
calc_middle endp


wait_key proc
    push    ax

    xor     ax, ax
    int     16h

    pop     ax

    ret
wait_key endp


get_line_start_address proc
    push    ax
    push    bx
    push    dx

    mov     bx, ax

    xor     ax, ax
    mov     al, byte ptr lines_middle
    sub     ax, 8
    add     ax, bx
    mov     bl, byte ptr screen_width
    mul     bx

    xor     dx, dx
    mov     dl, byte ptr column_middle
    sub     dx, 16

    shl     ax, 1

    shl     dx, 1
    add     ax, dx

    mov     di, ax 

    pop     dx
    pop     bx
    pop     ax

    ret
get_line_start_address endp



get_attributes proc
    push    dx
    push    bx

    mov     bx, dx

    shr     bx, 4

    cmp     bx, 0
    je      @@zero_line

    cmp     bx, 1
    je      @@first_line

    cmp     bx, 2
    je      @@second_line

    cmp     bx, 3
    je      @@third_line

    jmp     @@other

@@zero_line:
    mov     ah, 020h
    add     ah, dl

    jmp     @@to_return

@@first_line:
    mov     ah, 0C0h
    and     dl, 0Fh
    add     ah, dl

    jmp     @@to_return

@@second_line:
    and     dl, 0Fh
    mov     ah, dl
    inc     ah
    shl     ah, 4
    and     ah, 7Fh
    add     ah, dl

    jmp     @@to_return

@@third_line:
    mov     ah, 040h
    and     dl, 0Fh
    add     ah, dl

    jmp     @@to_return

@@other:
    mov     ah, 30h

@@to_return:
    pop     bx
    pop     dx

    ret
get_attributes endp


draw_line proc
    push    ax
    push    bx
    push    cx
    push    dx
    push    es
    push    di

    xor     dx, dx
    mov     dx, ax
    shl     dx, 4

    call    get_line_start_address
    mov     cx, 0B800h
    mov     es, cx

    xor     cx, cx

@@draw_line_cycle:
    cmp     cx, 16
    je      @@draw_line_cycle_end

    mov     al, dl
    call    get_attributes

    mov     word ptr es:[di], ax
    add     di, 2

    call    get_attributes
    mov     al, ' '
    
    mov     word ptr es:[di], ax
    add     di, 2

    inc     cx
    inc     dx
    jmp     @@draw_line_cycle

@@draw_line_cycle_end:
    pop     di
    pop     es
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret
draw_line endp


draw_table proc
    push    ax

    xor     ax, ax

@@lines_drawing:
    cmp     ax, 16
    je      @@lines_drawing_end

    call    draw_line

    inc     ax
    jmp     @@lines_drawing

@@lines_drawing_end:
    call    wait_key

    pop     ax

    ret
draw_table endp


old_mode db ?
old_page db ?

enter_mode proc
    mov     ah, 0Fh
    int     10h

    mov     byte ptr old_mode, al
    mov     byte ptr old_page, bh

    xor     ah, ah
    mov     al, byte ptr modenum
    int     10h

    mov     ah, 05h
    mov     al, byte ptr pagenum
    int     10h

    mov     byte ptr screen_height, 25 ; ??? how to get lines number ???

    mov     ah, 0Fh
    int     10h

    mov     byte ptr screen_width, ah

    call    calc_middle
    call    draw_table

    xor     ah, ah
    mov     al, byte ptr old_mode
    int     10h

    mov     ah, 05h
    mov     al, byte ptr old_page
    int     10h

    ret
enter_mode endp

usage db 'Usage: ascii <mode number> <page number>', 10, 13, '$'

actual_start:
    call    parse_arguments

    test    ax, ax
    jnz     @@print_usage

    call    enter_mode

    jmp     @@to_return

@@print_usage:
    mov     ah, 09h
    mov     dx, offset usage
    int     21h

@@to_return:
    ret
end start