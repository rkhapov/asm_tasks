model tiny
.386
.code

org 100h

locals @@

_start:

    jmp     call_main

    include argparse.asm
    include strings.asm
    include graphics.asm
    include keyboard.asm
    include map.asm
    include tools.asm
    include audio.asm
    include menu.asm
    include snakequ.asm

    snake_start_length  db 3
    start_apple_count   db 1
    intersection_mode   db 'd'

    intersection_mode_death     equ 'd'
    intersection_mode_cut       equ 'c'
    intersection_mode_nothing   equ 'n'

initialize proc
    call    enter_graphics_mode
    call    keyboard_setup
    call    music_init
    call    clear_screen
    ret
initialize endp


exit proc
    call    exit_graphics_mode
    call    keyboard_exit
    call    music_exit
    ret
exit endp


;ax - level number (0, 1, 2)
run_game_at_level proc
    push    ax bx cx dx

    call    initialize_map
    call    snake_queue_clear

    call    draw_map

    mov     ax, scancode_esc
    call    keyboard_wait_until

    pop     dx cx bx ax
    ret
endp


run_menu_cycle proc
    push    ax bx cx dx si di

@@cycle:
    call    run_menu

    cmp     ax, menu_exit
    je      @@cycle_end

    call    run_game_at_level

    jmp     @@cycle

@@cycle_end:
    pop     di si dx cx bx ax
    ret
endp


help_text   db 'snake - simple implementation of snake game', 10, 13
            db 'use keys:', 10, 13
            db '  -l <number> to specify start snake length (from 1 to 5) default = 3', 10, 13
            db '  -a <number> to specify start amounts of apple (from 1 to 5) default = 1', 10, 13
            db '  -i <mode> to specify self intersection behaviour (d - death, c - cut, n - nothing) default = d', 10, 13
            db '  -h to see this help and exit', 10, 13
            db 'for ingame controls see help item at main menu', 10, 13, '$'

invalid_length_msg db 'Invalid snake length: must be from 1 to 5!', 10, 13, '$'

invalid_intersection_mode_msg db 'Invalid sel intersection mode: accepltable is d, c, n!', 10, 13, '$'

invalid_apple_count_msg db 'Invalid apple amount: must be from 1 to 5!', 10, 13, '$'

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
    jz      @@no_help

    mov     ah, 09h
    lea     dx, help_text
    int     21h

    mov     ax, 1

    jmp     @@to_return

@@no_help:
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'l'
    push    ax
    call    get_arg_value
    add     sp, 6

    test    ax, ax
    jz      @@no_l_flag

    mov     si, ax
    call    to_int
    
    cmp     al, 0
    je      @@invalid_length

    cmp     al, 5
    ja      @@invalid_length

    mov     byte ptr snake_start_length, al

    jmp     @@no_l_flag

@@invalid_length:
    mov     ah, 9h
    lea     dx, invalid_length_msg
    int     21h
    mov     ax, 1
    jmp     @@to_return

@@no_l_flag:
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'i'
    push    ax
    call    get_arg_value
    add     sp, 6

    test    ax, ax
    jz      @@no_i_flag

    mov     si, ax
    mov     al, byte ptr [si]

    cmp     al, intersection_mode_death
    je      @@set_i_and_continue

    cmp     al, intersection_mode_cut
    je      @@set_i_and_continue

    cmp     al, intersection_mode_nothing
    je      @@set_i_and_continue

    jmp     @@invalid_intersection_mode

@@set_i_and_continue:
    mov     byte ptr intersection_mode, al

    jmp     @@no_i_flag

@@invalid_intersection_mode:
    mov     ah, 9h
    lea     dx, invalid_intersection_mode_msg
    int     21h
    mov     ax, 1
    jmp     @@to_return

@@no_i_flag:
    mov     ax, @@argc
    push    ax
    mov     ax, @@argv
    push    ax
    mov     ax, 'a'
    push    ax
    call    get_arg_value
    add     sp, 6

    test    ax, ax
    jz      @@run_game

    mov     si, ax
    call    to_int
    
    cmp     al, 0
    je      @@invalid_length

    cmp     al, 5
    ja      @@invalid_length

    mov     byte ptr start_apple_count, al

    jmp     @@run_game

@@invalid_apple_count:
    mov     ah, 9h
    lea     dx, invalid_apple_count_msg
    int     21h
    mov     ax, 1
    jmp     @@to_return

@@run_game:
    call    initialize

    call    run_menu_cycle

    call    exit

    xor     ax, ax

@@to_return:
    mov     sp, bp
    pop     bp

    ret
endp


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

    ret

end _start
