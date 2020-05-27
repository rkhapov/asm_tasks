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
    include menu.asm


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


main:
    call    initialize

    mov     ax, 0
    call    initialize_map

    call    run_menu

    call    exit

    ret

end _start
