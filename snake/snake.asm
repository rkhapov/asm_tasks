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


;returns al = 1 - should exit, 2 - do pause
process_keyboard proc
@@process_events:
    call    keyboard_pop_from_buffer
    cmp     al, keyboard_no_scancode
    je      @@process_events_exit

    cmp     al, scancode_esc
    je      @@return_exit

    cmp     al, scancode_p
    je      @@return_pause

    cmp     al, scancode_up
    je      @@do_up

    cmp     al, scancode_down
    je      @@do_down

    cmp     al, scancode_left
    je      @@do_left

    cmp     al, scancode_right
    je      @@do_right

    cmp     al, scancode_minus
    je      @@do_decrease_speed

    cmp     al, scancode_plus
    je      @@do_increase_speed

    jmp     @@continue

@@do_up:
    call    try_set_direction_to_up
    jmp     @@continue

@@do_down:
    call    try_set_direction_to_down
    jmp     @@continue

@@do_right:
    call    try_set_direction_to_right
    jmp     @@continue

@@do_left:
    call    try_set_direction_to_left
    jmp     @@continue

@@do_decrease_speed:
    call    increase_pause
    jmp     @@continue

@@do_increase_speed:
    call    decrease_pause
    jmp     @@continue

@@continue:
    jmp     @@process_events


@@process_events_exit:
    mov     al, 0
    jmp     @@to_return

@@return_pause:
    mov     al, 2
    jmp     @@to_return

@@return_exit:
    mov     al, 1

@@to_return:
    ret
endp


paused_str db 'Paused. Press P to continue$'


do_pause proc
    push    ax bx dx

    mov     dh, 12
    mov     dl, 7
    lea     bx, paused_str
    call    print_string

    mov     ax, scancode_p
    call    keyboard_wait_until

    pop     dx bx ax
    ret
endp



pause_milliseconds: dw 30, 50, 80, 100, 150, 200, 300, 400, 500
pause_milliseconds_end: dw ($ - pause_milliseconds - 2)
current_pause_pointer dw pause_milliseconds


make_default_speed proc
    mov word ptr current_pause_pointer, offset pause_milliseconds + 4
    ret
endp


increase_pause proc
    push    ax bx

    mov     bx, word ptr current_pause_pointer
    mov     ax, [bx]
    cmp     ax, 500
    je      @@to_return

    add     word ptr current_pause_pointer, 2

@@to_return:
    pop     bx ax
    ret
endp

decrease_pause proc
    push    ax

    mov     ax, word ptr current_pause_pointer
    cmp     ax, offset pause_milliseconds
    je      @@to_return

    sub     word ptr current_pause_pointer, 2

@@to_return:
    pop     ax
    ret
endp


wait_pause proc
    push    ax bx

    mov     bx, word ptr current_pause_pointer
    mov     ax, [bx]
    call    wait_milliseconds

    pop     bx ax
    ret
endp


;ax - level number (0, 1, 2)
run_game_at_level proc
    push    ax bx cx dx

    call    initialize_map

    mov     al, byte ptr snake_start_length
    call    spawn_snake

    call    spawn_apples

    call    make_default_speed

@@game_loop:
    call    process_keyboard

    cmp     al, 1
    je      @@game_loop_exit

    cmp     al, 2
    jne     @@not_pause

    call    do_pause

@@not_pause:
    call    update_map
    call    update_snake_position_to_current_direction
    call    spawn_objects_if_needed
    call    draw_map

    call    wait_pause

    cmp     byte ptr game_is_over, 1
    jne     @@game_loop

@@game_loop_exit:
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


help_text   db 'this is simple implementation of snake game', 10, 13
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
