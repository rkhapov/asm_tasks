.model tiny
.code
org 100h

locals @@

start:
    jmp     call_main

    modenum db 3
    pagenum db 0
    attributes_mask db 07Fh
    screen_height db ?
    screen_width db ?

    include argparse.asm
    include strings.asm


calc_screen_sizes proc
    push    ax
    push    es

    mov     byte ptr screen_height, 25 ; ??? how to get lines number ???

    xor     ax, ax
    mov     es, ax
    mov     ax, word ptr es:[44Ah]

    mov     byte ptr screen_width, al
    
    pop     es
    pop     ax
    ret
calc_screen_sizes endp


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


get_table_line_start_address proc
    push    ax
    push    bx
    push    dx
    push    es

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
    
    xor     bx, bx
    mov     es, bx     
    add     di, word ptr es:[44Eh]

@@to_return:
    pop     es
    pop     dx
    pop     bx
    pop     ax

    ret
get_table_line_start_address endp


get_line_start_address proc
    push    ax
    push    bx
    push    dx
    push    es

    xor     bx, bx
    mov     bl, byte ptr screen_width
    mul     bx

    shl     ax, 1

    mov     di, ax 
    
    xor     bx, bx
    mov     es, bx     
    add     di, word ptr es:[44Eh]

@@to_return:
    pop     es
    pop     dx
    pop     bx
    pop     ax

    ret
get_line_start_address endp


get_attributes_for_monochrome proc
    mov     bx, dx

    shr     bx, 4

    cmp     bx, 1
    je      @@first_line

    jmp     @@other

@@first_line:
    mov     ah, 0F0h

    jmp     @@to_return

@@other:
    mov     ah, 70h

@@to_return:
    ret
get_attributes_for_monochrome endp


get_attributes proc
    push    dx
    push    bx

    mov     ah, byte ptr modenum
    cmp     ah, 7
    jne     @@not_monochrome

    call    get_attributes_for_monochrome
    
    jmp     @@to_return

@@not_monochrome:
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
    and     ah, byte ptr attributes_mask

    pop     bx
    pop     dx

    ret
get_attributes endp


load_buffer_start_address proc
    push    ax

    mov     al, byte ptr modenum
    cmp     al, 7
    jne      @@other

@@for_momochrome:
    mov     ax, 0B000h

    jmp     @@to_return

@@other:
    mov     ax, 0B800h

@@to_return:
    mov     es, ax
    pop     ax
    ret
load_buffer_start_address endp


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

    call    get_table_line_start_address
    call    load_buffer_start_address

    xor     cx, cx

@@draw_line_cycle:
    cmp     cx, 16
    je      @@draw_line_cycle_end

    mov     al, dl
    call    get_attributes

    mov     word ptr es:[di], ax
    add     di, 2

    cmp     cx, 15
    je      @@continue

    call    get_attributes
    mov     al, ' '
    
    mov     word ptr es:[di], ax
    add     di, 2

@@continue:
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
    pop     ax

    ret
draw_table endp


print_string_centrized_by_columns proc
    push    ax
    push    bx
    push    es
    push    di

    call    get_line_start_address

    call    strlen

    xor     bh, bh
    mov     bl, byte ptr column_middle
    shr     al, 1
    sub     bl, al
    shl     bl, 1

    add     di, bx

    call    load_buffer_start_address

    cld

@@cycle:
    lodsb
    test    al, al
    jz      @@cycle_end

    mov     ah, 7

    mov     word ptr es:[di], ax
    add     di, 2

    jmp     @@cycle

@@cycle_end:
    pop     di
    pop     es
    pop     bx
    pop     ax
    ret
print_string_centrized_by_columns endp


mode_page_str   db 'Mode - '
mode_to_insert  db ?
                db ' Page - '
page_to_insert  db ?
                db 0

draw_mode_and_page proc
    push    ax
    push    si

    mov     al, byte ptr modenum
    add     al, '0'
    mov     byte ptr mode_to_insert, al

    mov     al, byte ptr pagenum
    add     al, '0'
    mov     byte ptr page_to_insert, al

    xor     ax, ax
    mov     al, lines_middle
    sub     al, 10
    lea     si, mode_page_str
    call    print_string_centrized_by_columns

    pop     si
    pop     ax
    ret
draw_mode_and_page endp


numeric_line db '0 1 2 3 4 5 6 7 8 9 A B C D E F ', 0

draw_upper_numeric proc
    push    ax
    push    si

    xor     ax, ax
    mov     al, lines_middle
    sub     al, 9
    lea     si, numeric_line
    call    print_string_centrized_by_columns

    pop     si
    pop     ax
    ret
draw_upper_numeric endp


hex_numeric db '0123456789ABCDEF', 0

draw_left_numeric proc
    push    ax
    push    bx
    push    dx
    push    si
    push    di
    push    es

    call    load_buffer_start_address
    lea     si, hex_numeric

    xor     ax, ax
    xor     dx, dx
    xor     bx, bx

    mov     al, byte ptr lines_middle
    sub     al, 8

    mov     dh, 7h

@@cycle:
    mov     dl, [si]
    test    dl, dl
    jz      @@cycle_end

    call    get_line_start_address

    mov     bl, byte ptr column_middle
    sub     bl, 17
    shl     bl, 1
    add     di, bx

    mov     word ptr es:[di], dx
    
    inc     si
    inc     ax
    jmp     @@cycle

@@cycle_end:
    pop     es
    pop     di
    pop     si
    pop     dx
    pop     bx
    pop     ax
    ret
draw_left_numeric endp


press_any_key db 'Press any key...', 0

draw_press_any_key proc
    push    ax
    push    si

    xor     ax, ax
    mov     al, lines_middle
    add     al, 8
    lea     si, press_any_key
    call    print_string_centrized_by_columns

    pop     si
    pop     ax
    ret
draw_press_any_key endp


title_msg db 'ASCII characters table', 0

draw_title proc
    push    ax
    push    si

    xor     ax, ax
    mov     al, lines_middle
    sub     al, 11
    lea     si, title_msg
    call    print_string_centrized_by_columns

    pop     si
    pop     ax
    ret
draw_title endp

old_mode db ?
old_page db ?

enter_mode proc
    push    es

    xor     ax, ax
    mov     es, ax

    mov     al, byte ptr es:[449h]
    mov     byte ptr old_mode, al

    mov     al, byte ptr es:[462h]
    mov     byte ptr old_page, al

    xor     ah, ah
    mov     al, byte ptr modenum
    int     10h

    mov     ah, 05h
    mov     al, byte ptr pagenum
    int     10h

    call    calc_screen_sizes
    call    calc_middle
    call    draw_title
    call    draw_mode_and_page
    call    draw_table
    call    draw_upper_numeric
    call    draw_left_numeric
    call    draw_press_any_key
    call    wait_key

    xor     ah, ah
    mov     al, byte ptr old_mode
    int     10h

    mov     ah, 05h
    mov     al, byte ptr old_page
    int     10h

    pop     es

    ret
enter_mode endp

invalid_mode db 'Invalid graphic mode. Use 0, 1, 2, 3 or 7', 13, 10, '$'
invalid_page db 'Invalid page, use 0-7 for mode 0, 1, 0-3 for mode 2 and 3 and 0 for 7', 13, 10, '$'

is_mode_and_page_correct proc
    push    dx

    mov     al, byte ptr modenum

    cmp     al, 0
    je      @@check_page_is_from_0_to_7

    cmp     al, 1
    je      @@check_page_is_from_0_to_7

    cmp     al, 2
    je      @@check_page_is_from_0_to_3

    cmp     al, 3
    je      @@check_page_is_from_0_to_3

    cmp     al, 7
    je      @@check_page_is_0

    mov     dx, offset invalid_mode
    jmp     @@failed

@@check_page_is_from_0_to_7:
    mov     al, byte ptr pagenum
    
    cmp     al, 7
    jle     @@success

    mov     dx, offset invalid_page
    jmp     @@failed      

@@check_page_is_from_0_to_3:
    mov     al, byte ptr pagenum
    
    cmp     al, 3
    jle     @@success

    mov     dx, offset invalid_page
    jmp     @@failed

@@check_page_is_0:
    mov     al, byte ptr pagenum
    
    cmp     al, 0
    je      @@success

    mov     dx, offset invalid_page
    jmp     @@failed
    
@@success:
    mov     ax, 1
    jmp     @@to_return

@@failed:
    mov     ah, 09h
    int     21h

    xor     ax, ax

@@to_return:
    pop     dx
    ret
is_mode_and_page_correct endp

help db 'ascii - program to print ascii characters table', 13, 10
     db 'use keys:', 13, 10    
     db '  -m <mode> to specify graphic mode (0, 1, 2, 3 or 7) default = 3', 13, 10
     db '  -p <page> to specify page number (0-7, 0-7, 0-3, 0-3 or 0-7) default = 0', 13, 10
     db '  -b to enable blinking', 13, 10
     db '  -h to see this help and exit', 13, 10, '$'

main proc
@@argc equ [bp + 6]
@@argv equ [bp + 4]
    push    bp
    mov     bp, sp
    
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'h'
    push    ax
    call    is_argument_set
    add     sp, 6

    test    ax, ax
    jnz     @@print_help    

    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'b'
    push    ax
    call    is_argument_set
    add     sp, 6

    test    ax, ax
    jz      @@no_b_flag

    mov     byte ptr attributes_mask, 0FFh  

@@no_b_flag:    
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'm'
    push    ax
    call    get_arg_value
    add     sp, 6

    test    ax, ax
    jz      @@no_m_argument

    mov     si, ax
    call    to_int
    mov     modenum, al
    
@@no_m_argument:
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'p'
    push    ax
    call    get_arg_value
    add     sp, 6

    test    ax, ax
    jz      @@to_check_page_and_mode

    mov     si, ax
    call    to_int
    mov     pagenum, al

@@to_check_page_and_mode:
    call    is_mode_and_page_correct
    test    ax, ax
    jz      @@to_return

    call    enter_mode
    xor     al, al
    jmp     @@to_return

@@print_help:
    mov     ah, 09h
    mov     dx, offset help
    int     21h

    mov     al, 1

@@to_return:
    mov     sp, bp
    pop     bp

    ret
main endp

call_main:
    call    parse_arguments

    xor     ax, ax
    mov     al, arguments_count
    push    ax
    lea     ax, arguments_pointers
    push    ax
    call    main

    mov     ah, 4Ch
    int     21h
end start