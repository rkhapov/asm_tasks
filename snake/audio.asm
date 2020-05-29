do1         equ 261
do_sharp1   equ 277
re1         equ 293
re_sharp1   equ 311
mi1         equ 329
fa1         equ 349
fa_sharp1   equ 369
sol1        equ 392
sol_sharp1  equ 415
la1         equ 440
la_sharp1   equ 466
si1         equ 493

do2         equ 523
do_sharp2   equ 554
re2         equ 587
re_sharp2   equ 622
mi2         equ 659
fa2         equ 698
fa_sharp2   equ 740
sol2        equ 784
sol_sharp2  equ 831
la2         equ 880
la_sharp2   equ 932
si2         equ 988

do3         equ 1046
re3         equ 1174

mi2_becar   equ re_sharp2
si2_becar   equ la_sharp2
la1_becar   equ sol_sharp1
si1_becar   equ la_sharp1
mi1_becar   equ re_sharp1


do_play_frequency proc
    push    ax
    push    cx
    push    dx

    mov     dx, 12h
    cmp     ax, dx
    jbe     @@to_return
    mov     cx, ax
    in      al, 61h
    or      al, 3
    out     61h, al
    mov     al, 10110110b
    out     43h, al
    mov     ax, 34DDh
    div     cx
    out     42h, al
    mov     al ,ah
    out     42h, al

@@to_return:
    pop     dx
    pop     cx
    pop     ax

    ret
do_play_frequency endp


do_stop_playing proc
    push    ax

    in      al, 61h
    and     al, not 3
    out     61h, al

    pop     ax
    ret
do_stop_playing endp


play_sound proc
    test    ax, ax
    jz      @@stop

    call    do_play_frequency

    jmp     @@to_return

@@stop:
    call    do_stop_playing

@@to_return:
    ret
play_sound endp


music_init proc
    call    music_clear
    ret
music_init endp

music_exit proc
    call    do_stop_playing
    ret
music_exit endp


sound_queue_node_t struc
    _frequency          dw 0
    _sound_elapsed_time dw 0
sound_queue_node_t ends


sounds_queue_size equ 300

sounds_queue sound_queue_node_t (sounds_queue_size+10) dup(<>)
sounds_queue_tail_index dw sounds_queue


read_head_frequency_and_duration proc
    mov     ax, sounds_queue[0]._frequency
    mov     cx, sounds_queue[0]._sound_elapsed_time
    ret
read_head_frequency_and_duration endp


upload_head_frequency_and_duration proc
    mov     sounds_queue[0]._frequency, ax
    mov     sounds_queue[0]._sound_elapsed_time, cx
    ret
upload_head_frequency_and_duration endp


music_is_queue_empty proc
    mov     ax, sounds_queue_tail_index
    test    ax, ax
    jnz     @@not_empty

    mov     ax, 1
    jmp     @@to_return

@@not_empty:
    xor     ax, ax

@@to_return:
    ret
music_is_queue_empty endp


music_play_head proc
    push    ax cx
    call    read_head_frequency_and_duration
    call    play_sound
    pop     cx ax
    ret
endp


; ax - elapsed
music_update proc
    push    ax bx cx dx

    mov     bx, ax

    call    read_head_frequency_and_duration

    test    ax, ax
    jz      @@to_return

    cmp     cx, bx
    ja      @@decrease_life_time

    call    music_shift_queue_left
    sub     word ptr sounds_queue_tail_index, type(sound_queue_node_t)

    jmp     @@to_return

@@decrease_life_time:
    sub     cx, bx
    call    upload_head_frequency_and_duration

@@to_return:
    pop     dx cx bx ax
    ret
music_update endp


; ax - note, bx - duration
music_push_to_queue proc
    push    ax bx cx

    mov     cx, bx

    mov     bx, sounds_queue_tail_index

    mov     [bx]._frequency, ax
    mov     [bx]._sound_elapsed_time, cx
    add     word ptr sounds_queue_tail_index, type(sound_queue_node_t)

    pop     cx bx ax
    ret
music_push_to_queue endp


music_shift_queue_left proc
    push    ax bx cx dx

    lea     bx, sounds_queue
    xor     dx, dx

@@shifting:
    cmp     dx, sounds_queue_size
    je      @@shifting_end

    add     bx, type(sound_queue_node_t)
    mov     ax, [bx]._frequency
    mov     cx, [bx]._sound_elapsed_time

    sub     bx, type(sound_queue_node_t)
    mov     [bx]._frequency, ax
    mov     [bx]._sound_elapsed_time, cx

    add     bx, type(sound_queue_node_t)
    inc     dx
    jmp     @@shifting

@@shifting_end:
    pop     dx cx bx ax
    ret
music_shift_queue_left endp


music_clear proc
    push    bx cx

    call    do_stop_playing

    mov     cx, sounds_queue_size
    lea     bx, sounds_queue

@@cleaning:
    mov     [bx]._frequency, 0
    mov     [bx]._sound_elapsed_time, 0

    add     bx, type(sound_queue_node_t)

    dec     cx
    jne     @@cleaning

    mov     word ptr sounds_queue_tail_index, offset sounds_queue

    pop     cx bx
    ret
endp


music_push MACRO note, duration
    push    ax bx

    mov     ax, note
    mov     bx, duration
    call    music_push_to_queue

    pop     bx ax
ENDM


play2 MACRO p
    mov     ax, p
    call    do_play_frequency
    call    pause2
    call    do_stop_playing
ENDM

play4 MACRO p
    mov     ax, p
    call    do_play_frequency
    call    pause4
    call    do_stop_playing
ENDM


pause8 proc
    push    ax
    push    dx
    push    cx

    mov     cx, 1
    xor     dx, dx
    mov     ah, 86h
    int     15h

    pop     cx
    pop     dx
    pop     ax
    ret
pause8 endp

pause4 proc
    push    ax
    push    dx
    push    cx

    mov     cx, 2
    xor     dx, dx
    mov     ah, 86h
    int     15h

    pop     cx
    pop     dx
    pop     ax
    ret
pause4 endp


pause2 proc
    push    ax
    push    dx
    push    cx

    mov     cx, 4
    xor     dx, dx
    mov     ah, 86h
    int     15h

    pop     cx
    pop     dx
    pop     ax
    ret
pause2 endp


pause1 proc
    push    ax
    push    dx
    push    cx

    mov     cx, 8
    xor     dx, dx
    mov     ah, 86h
    int     15h

    pop     cx
    pop     dx
    pop     ax
    ret
pause1 endp



play8 MACRO p
    mov     ax, p
    call    do_play_frequency
    call    pause8
    call    do_stop_playing
ENDM

empty2 MACRO
    call    do_stop_playing
    call    pause2
ENDM

empty4 MACRO
    call    do_stop_playing
    call    pause4
ENDM


music_push_apple_eaten_sound proc

    music_push  do2, 200
    music_push  mi2, 200

    ret
endp

music_push_poisoned_apple_eaten_sound proc

    music_push  do2, 200
    music_push  mi2_becar, 200

    ret
endp


music_push_portal_sound proc

    music_push  sol1, 100
    music_push  mi1, 100
    music_push  mi2, 100
    music_push  sol2, 100

    ret
endp


music_push_spring_sound proc

    music_push  sol1, 80
    music_push  mi1, 80
    music_push  do1, 80
    music_push  mi1, 80
    music_push  sol1, 80

    ret
endp


play_game_over proc

    ;takt2
    play4   do2
    play4   do2
    play2   mi2_becar

    ;takt3
    play4   re2
    play4   re2
    play4   do2
    play4   do2

    ;takt4
    play2   si1
    play2   do2

    ret
endp

play_menu_selection_sound proc
    play4   la1
    ret
endp

play_menu_enter_sound proc
    play8   mi1
    play8   mi2
    ret
endp

play_pause_menu proc
    play4   do3
    ret
endp
