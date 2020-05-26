model tiny
.386
.code

org 100h

locals @@

_start:

    jmp     main

    include argparse.asm
    include strings.asm
    include graphics.asm
    include keyboard.asm
    include map.asm
    include tools.asm
    include audio.asm


initialize proc
    call    enter_graphics_mode
    call    keyboard_setup
    call    music_init
    ret
initialize endp


exit proc
    call    exit_graphics_mode
    call    keyboard_exit
    call    music_exit
    ret
exit endp


main:
    call    initialize

@@loopa:
    call    keyboard_pop_from_buffer
    cmp     al, esc_scancode
    je      @@loopa_end

    lea     si, brick_wall_sprite
    mov     dh, 5
    mov     dl, 10
    call    draw_sprite

    lea     si, spring_wall_sprite
    mov     dh, 50
    mov     dl, 100
    call    draw_sprite

    lea     si, apple_sprite
    mov     dh, 100
    mov     dl, 50
    call    draw_sprite

    lea     si, poisoned_apple_sprite
    mov     dh, 80
    mov     dl, 50
    call    draw_sprite

    lea     si, burger_sprite
    mov     dh, 30
    mov     dl, 50
    call    draw_sprite

    lea     si, portal_sprite
    mov     dh, 100
    mov     dl, 100
    call    draw_sprite

    lea     si, snake_part_sprite
    mov     dh, 100
    mov     dl, 0
    call    draw_sprite

    lea     si, snake_head_left_sprite
    mov     dh, 90
    mov     dl, 0
    call    draw_sprite

    lea     si, snake_head_up_sprite
    mov     dh, 90
    mov     dl, 10
    call    draw_sprite

    lea     si, snake_head_right_sprite
    mov     dh, 90
    mov     dl, 20
    call    draw_sprite

    lea     si, snake_head_down_sprite
    mov     dh, 90
    mov     dl, 30
    call    draw_sprite

    call    clear_screen


    jmp     @@loopa

@@loopa_end:

    call    exit

    ret

end _start
