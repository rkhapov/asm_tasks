.model tiny
.code
org 100h

locals @@

start:
    jmp     actual_start

    old_int9    dw 0, 0
    buffer      db 20 dup(0)
    buffer_end:
    head        dw offset buffer
    tail        dw offset buffer

    esc_scancode    equ 01h
    space_scancode  equ 39h

notes:
    ;filler for escape scancode and zero
    dw 0, 0

    keys_start_scancode equ 02h

    ;1 to = keys with scancodes 0x02 - 0x0D
    do1         dw 261
    do_sharp1   dw 277
    re1         dw 293
    re_sharp1   dw 311
    mi1         dw 329
    fa1         dw 349
    fa_sharp1   dw 369
    sol1        dw 392
    sol_sharp1  dw 415
    la1         dw 440
    la_sharp1   dw 466
    si1         dw 493

    keys_end_first_octave_scancode equ 0Dh

    ;filler for 0x0F and 0x0E (tab and backspace)
    dw 0, 0

    keys_start_second_octave_scancode equ 10h

    ;a to \ keys with scancodes 0x10 - 0x1B
    do2         dw 523
    do_sharp2   dw 554
    re2         dw 587
    re_sharp2   dw 622
    mi2         dw 659
    fa2         dw 698
    fa_sharp2   dw 740
    sol2        dw 784
    sol_sharp2  dw 831
    la2         dw 880
    la_sharp2   dw 932
    si2         dw 988

    keys_end_scancode equ 1Bh

    press_keymap_len    equ (keys_end_scancode + 1)
    press_keymap        db press_keymap_len dup (0)

    do3 equ 1046
    re3 equ 1174

    mi2_becar equ re_sharp2
    si2_becar equ la_sharp2
    la1_becar equ sol_sharp1
    si1_becar equ la_sharp1
    mi1_becar equ re_sharp1


push_at_buffer proc
    push    di
    push    bx
    push    bp

    mov     di, cs:tail
    mov     bx, di
    inc     di

    cmp     di, offset buffer_end
    jnz     @@pushing_at_tail

    mov     di, offset buffer

@@pushing_at_tail:
    mov     bp, di
    cmp     di, cs:head
    jz      @@overflow

    mov     di, bx
    mov     byte ptr cs:[di], al
    mov     cs:tail, bp

@@overflow:
    pop     bp
    pop     bx
    pop     di
    ret
push_at_buffer endp

pop_from_buffer proc
    push    bx

    mov     bx, head
    mov     al, byte ptr ds:[bx]
    inc     bx

    cmp     bx, offset buffer_end
    jnz     @@to_return

    mov     bx, offset buffer

@@to_return:
    mov     head, bx

    pop     bx
    ret
pop_from_buffer endp

my_int9 proc
    push    ax

    in      al, 60h
    call    push_at_buffer

    mov     al, 20h
    out     20h, al

    pop     ax
    iret
my_int9 endp


setup_int9 proc
    push    ax
    push    ds
    push    si
    push    di

    xor     ax, ax
    mov     ds, ax
    mov     si, 36
    mov     di, offset old_int9
    movsw
    movsw

    cli
    mov     ax, offset my_int9
    mov     ds:36, ax
    mov     ax, cs
    mov     ds:38, ax
    sti

    pop     di
    pop     si
    pop     ds
    pop     ax
    ret
setup_int9 endp


restore_int9 proc
    push    ax
    push    ds
    push    es
    push    si
    push    di

    xor     ax, ax
    push    ax
    pop     es
    push    cs
    pop     ds
    mov     si, offset old_int9
    mov     di, 36

    cli
    movsw
    movsw
    sti

    pop     di
    pop     si
    pop     es
    pop     ds
    pop     ax
    ret
restore_int9 endp


update_keymap proc
    push    ax
    push    bx

    mov     ah, al
    and     ah, 7Fh

    cmp     ah, keys_end_scancode
    jg      @@to_return

    lea     bx, press_keymap

    test    al, 80h
    jnz     @@released

    and     ax, 07Fh
    add     bx, ax
    mov     byte ptr [bx], 1

    jmp     @@to_return

@@released:
    and     ax, 07Fh
    add     bx, ax
    mov     byte ptr [bx], 0

@@to_return:
    pop     bx
    pop     ax
    ret
update_keymap endp


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


count_average proc
    push    bp
    push    cx
    push    dx
    push    bx
    push    di
    push    si

    lea     di, press_keymap
    lea     si, notes

    xor     cx, cx
    xor     bp, bp
    xor     ax, ax

@@average_loop:
    mov     dl, byte ptr [di]
    mov     bx, word ptr [si]

    test    dl, dl
    jz      @@continue

    test    bx, bx
    jz      @@continue

    add     ax, bx
    inc     bp

@@continue:
    add     si, 2
    inc     di
    inc     cx
    cmp     cx, press_keymap_len
    jb      @@average_loop

    test    ax, ax
    jz      @@to_return

    mov     bx, bp
    test    bx, bx
    jz      @@to_return
    xor     dx, dx
    div     bx

@@to_return:
    pop     si
    pop     di
    pop     bx
    pop     dx
    pop     cx
    pop     bp

    ret
count_average endp


play_average_sound proc
    push    ax

    call    count_average
    test    ax, ax
    jz      @@stop

    call    do_play_frequency

    jmp     @@to_return

@@stop:
    call    do_stop_playing

@@to_return:
    pop     ax
    ret
play_average_sound endp


pause8 proc
    push    ax
    push    dx
    push    cx

    mov     cx, 3
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

    mov     cx, 6
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

    mov     cx, 12
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

    mov     cx, 24
    xor     dx, dx
    mov     ah, 86h
    int     15h

    pop     cx
    pop     dx
    pop     ax
    ret
pause1 endp


call_of_magic_about db 'Here comes ', 22h, 'Call of Magic', 22h, ' from Morriwind!', 10, 13, '$'
thanks_for_listening db 'Thanks for listening!', 10, 13, '$'

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

play_easter_egg_melody proc
    push    ax
    push    dx

    mov     ah, 9
    lea     dx, call_of_magic_about
    int     21h

    call    do_stop_playing

    ;takt 1
    play4   do2
    play4   re2

    ;takt2
    play2   mi2_becar
    empty2
    play4   mi2_becar
    play4   fa2

    ;takt3
    play2   sol2
    empty2
    play4   sol2
    play4   si2_becar

    ;takt4
    play2   fa2
    empty4

    play8   sol2
    play8   fa2
    play4   mi2_becar
    play4   re2

    ;takt5
    play2   do2
    empty2
    play4   do2
    play4   re2

    ;takt6
    play2   mi2_becar
    empty2
    play4   mi2_becar
    play4   fa2

    ;takt7
    play2   sol2
    empty2
    play4   sol2
    play4   si2_becar

    ;takt8
    play2   do3
    empty2
    play4   si2_becar
    call    pause8
    play8   re3

    ;takt9
    play2   do3
    empty2
    play4   do2
    call    pause8
    play8   re2

    ;tatk10
    play2   mi2_becar
    play2   re2
    play2   do2

    ;takt11
    play2   si1_becar
    play2   la1_becar
    play2   sol1

    ;takt12
    play2   fa1
    empty2
    play4   mi1_becar
    play8   mi1_becar
    play8   sol1

    ;takt13
    play2   fa1
    play4   fa1
    play8   sol1
    play8   fa1
    play4   mi1_becar
    play4   re1

    ;takt14
    play2   do1
    play4   do1

    mov     ah, 9
    lea     dx, thanks_for_listening
    int     21h

    pop     dx
    pop     ax
    ret
play_easter_egg_melody endp


help_string db 'Just a little piano program.', 10, 13
            db 'Use 1 2 3 4 5 6 7 8 9 0 - = keys for first octave.', 10, 13
            db 'Use q w e r t y u i o p [ ] keys for second octave.', 10, 13
            db 'Use space key for easter egg melody.', 10, 13
            db 'Use esc key to exit.', 10, 13, '$'

actual_start:
    mov     ah, 9
    lea     dx, help_string
    int     21h

    call    setup_int9

@@infinite_loop:
    mov     bx, head
    cmp     bx, tail
    jz      @@infinite_loop

@@update_sounds:
    mov     bx, head
    cmp     bx, tail
    jz      @@update_sounds_end

    call    pop_from_buffer

    cmp     al, esc_scancode
    je      @@infinite_loop_end

    cmp     al, space_scancode
    je      @@do_easter_egg

    call    update_keymap

    jmp     @@update_sounds

@@do_easter_egg:
    call    play_easter_egg_melody
    jmp     @@update_sounds

@@update_sounds_end:
    call    play_average_sound

    jmp     @@infinite_loop

@@infinite_loop_end:
    call    restore_int9

    ret
end start
