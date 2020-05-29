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

direction_already_setted db 0

;returns al = 1 - should exit, 2 - do pause
process_keyboard proc
    mov     byte ptr direction_already_setted, 0

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
    cmp     byte ptr direction_already_setted, 1
    je      @@continue
    call    try_set_direction_to_up
    mov     byte ptr direction_already_setted, al
    jmp     @@continue

@@do_down:
    cmp     byte ptr direction_already_setted, 1
    je      @@continue
    call    try_set_direction_to_down
    mov     byte ptr direction_already_setted, al
    jmp     @@continue

@@do_right:
    cmp     byte ptr direction_already_setted, 1
    je      @@continue
    call    try_set_direction_to_right
    mov     byte ptr direction_already_setted, al
    jmp     @@continue

@@do_left:
    cmp     byte ptr direction_already_setted, 1
    je      @@continue
    call    try_set_direction_to_left
    mov     byte ptr direction_already_setted, al
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


paused_str    db 'Paused. Press P to continue$'
enter_to_help db 'Press Enter to see help$'


do_pause proc
    push    ax bx dx

    prints paused_str 12 7
    prints enter_to_help 14 9

@@key_waiting:
    call    keyboard_pop_from_buffer

    cmp     al, scancode_p
    je      @@to_return

    cmp     al, scancode_enter
    jne     @@continue

    call    show_help
    call    draw_map
    prints paused_str 12 7
    prints enter_to_help 14 9

@@continue:
    jmp     @@key_waiting

@@to_return:
    call    keyboard_clear_buffer
    pop     dx bx ax
    ret
endp


pause_coeff         equ 50
pause_milliseconds: dw 2, 3, 4, 5, 6, 7, 8, 9, 10
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
    cmp     ax, 10
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
    push    ax bx cx

    mov     bx, word ptr current_pause_pointer
    mov     cx, [bx]
    mov     ax, pause_coeff

@@waiting:
    call    music_play_head
    mov     ax, pause_coeff
    call    wait_milliseconds
    call    music_update

    loop    @@waiting

    pop     cx bx ax
    ret
endp


apples_eaten            dw 0
poisoned_apple_eaten    dw 0
life_time               dw 0


clean_stats proc
    mov     word ptr apples_eaten, 0
    mov     word ptr poisoned_apple_eaten, 0
    mov     word ptr life_time, 0
    ret
endp


game_over_str               db 'Game Over!$'
life_time_str               db 'Ticks of life:        00000'
place_for_current_tick      db '$'
apple_eaten_str             db 'Apple eaten:          00000'
place_for_apple             db '$'
poisoned_apple_eaten_str    db 'Poisoned apple eaten: 00000'
place_for_poisoned_apple    db '$'
press_enter_str             db 'Enter - back to menu$'
length_str                  db 'Your length:          00000'
length_place                db '$'


;ax - number
;si - pointer
emplace_number proc
    push    cx dx

    mov     dx, 5

@@inserting:
    call    divide_and_get_right_digit
    mov     byte ptr [si], cl

    dec     si
    dec     dx
    jne     @@inserting

    pop     cx dx
    ret
endp


emplace_apple_eaten proc
    push    ax si
    mov     ax, word ptr apples_eaten
    lea     si, place_for_apple - 1
    call    emplace_number
    pop     si ax
    ret
endp

emplace_current_tick proc
    push    ax si
    mov     ax, word ptr life_time
    lea     si, place_for_current_tick - 1
    call    emplace_number
    pop     si ax
    ret
endp

emplace_poisoned_apple_eaten proc
    push    ax si
    mov     ax, word ptr poisoned_apple_eaten
    lea     si, place_for_poisoned_apple - 1
    call    emplace_number
    pop     si ax
    ret
endp

emplace_length proc
    push    ax si
    mov     al, byte ptr snake_current_length
    xor     ah, ah
    lea     si, length_place - 1
    call    emplace_number
    pop     si ax
    ret
endp


show_end_stats proc
    push    ax bx dx

    call    clear_screen

    call    emplace_apple_eaten
    call    emplace_current_tick
    call    emplace_poisoned_apple_eaten
    call    emplace_length

    prints  game_over_str 5 16
    prints  length_str 8 7
    prints  apple_eaten_str 10 7
    prints  poisoned_apple_eaten_str 12 7
    prints  life_time_str 14 7
    prints  press_enter_str 22 7

    call    play_game_over

    mov     al, scancode_enter
    call    keyboard_wait_until

    call    keyboard_clear_buffer

    pop     dx bx ax
    ret
endp


max_string_x equ 30
max_string_y equ 23


;ax - level number (0, 1, 2)
run_game_at_level proc
    push    ax bx cx dx

    call    initialize_map
    mov     al, byte ptr snake_start_length
    call    spawn_snake
    call    spawn_apples
    call    make_default_speed
    call    clean_stats

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
    inc     word ptr life_time
    cmp     byte ptr game_is_over, 1
    jne     @@game_loop

@@game_loop_exit:
    call    music_clear
    call    show_end_stats

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
