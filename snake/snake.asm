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

    mov     ax, do1
    mov     bx, 5FFFh
    call    music_push_to_queue

    mov     ax, do2
    mov     bx, 09FFFh
    call    music_push_to_queue

@@loopa:
    call    keyboard_pop_from_buffer
    cmp     al, esc_scancode
    je      @@loopa_end

@@to_play:
    mov     ax, 1
    call    music_update

    jmp     @@loopa

@@loopa_end:

    call    exit

    ret

end _start
