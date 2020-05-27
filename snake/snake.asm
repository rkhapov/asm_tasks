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
    mov     dx, 5
    mov     ax, 10
    call    draw_sprite

    lea     si, spring_wall_sprite
    mov     dx, 50
    mov     ax, 100
    call    draw_sprite

    lea     si, apple_sprite
    mov     dx, 100
    mov     ax, 50
    call    draw_sprite

    lea     si, poisoned_apple_sprite
    mov     dx, 80
    mov     ax, 50
    call    draw_sprite

    lea     si, burger_sprite
    mov     dx, 30
    mov     ax, 50
    call    draw_sprite

    lea     si, portal_sprite
    mov     dx, 100
    mov     ax, 100
    call    draw_sprite

    lea     si, snake_part_sprite
    mov     dx, 100
    mov     ax, 0
    call    draw_sprite

    lea     si, snake_head_left_sprite
    mov     dx, 90
    mov     ax, 0
    call    draw_sprite

    lea     si, snake_head_up_sprite
    mov     dx, 90
    mov     ax, 10
    call    draw_sprite

    lea     si, snake_head_right_sprite
    mov     dx, 90
    mov     ax, 20
    call    draw_sprite

    lea     si, snake_head_down_sprite
    mov     dx, 90
    mov     ax, 30
    call    draw_sprite


    jmp     @@loopa

@@loopa_end:

    call    exit

    ret

end _start
