graphics_mode_number equ 13h
graphics_page_number equ 0

old_graphics_mode db ?
old_graphics_page db ?

screen_width  equ 320
screen_height equ 200


black         equ 0
blue          equ 1
green         equ 2
cyan          equ 3
red           equ 4
magenta       equ 5
brown         equ 6
light_gray    equ 7
dark_gray     equ 8
light_blue    equ 9
light_green   equ 10
light_cyan    equ 11
light_red     equ 12
light_magenta equ 13
yellow        equ 14
white         equ 15

_gray equ light_gray


backg equ (223)

sprite_width equ screen_width / map_width
sprite_height equ screen_height / map_height

sprite_size equ (sprite_height * sprite_width)

brick_wall_sprite   db red,     red,    red,    white,  red,    red,    red,    white,  red,    red
                    db red,     red,    red,    white,  red,    red,    red,    white,  red,    red
                    db white,   white,  white,  white,  white,  white,  white,  white,  white,  white
                    db red,     red,    white,  red,    red,    red,    white,  red,    red,    red
                    db red,     red,    white,  red,    red,    red,    white,  red,    red,    red
                    db white,   white,  white,  white,  white,  white,  white,  white,  white,  white
                    db red,     red,    red,    white,  red,    red,    red,    white,  red,    red
                    db red,     red,    red,    white,  red,    red,    red,    white,  red,    red
                    db white,   white,  white,  white,  white,  white,  white,  white,  white,  white
                    db red,     red,     red,    white,  red,    red,    red,    white,  red,    red

empty_sprite    db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg

spring_wall_sprite  db _gray, _gray, _gray, _gray, backg, backg, _gray, _gray, _gray, _gray
                    db backg, _gray, _gray, backg, backg, backg, backg, _gray, _gray, backg
                    db _gray, backg, backg, _gray, backg, backg, _gray, backg, backg, _gray
                    db backg, _gray, _gray, backg, backg, backg, backg, _gray, _gray, backg
                    db _gray, backg, backg, _gray, backg, backg, _gray, backg, backg, _gray
                    db backg, _gray, _gray, backg, backg, backg, backg, _gray, _gray, backg
                    db _gray, backg, backg, _gray, backg, backg, _gray, backg, backg, _gray
                    db backg, _gray, _gray, backg, backg, backg, backg, _gray, _gray, backg
                    db _gray, backg, backg, _gray, backg, backg, _gray, backg, backg, _gray
                    db _gray, _gray, _gray, _gray, backg, backg, _gray, _gray, _gray, _gray

apple_sprite        db backg, backg, backg, backg, backg, green, green, backg, backg, backg
                    db backg, backg, backg, backg, green, backg, backg, backg, backg, backg
                    db backg, backg, backg, red, red, backg, backg, backg, backg, backg
                    db backg, backg, red, red, red, red, backg, backg, backg, backg
                    db backg, red, red, red, red, red, red, backg, backg, backg
                    db red, red, red, red, red, red, Red, red, backg, backg
                    db red, red, red, red, red, red, red, red, backg, backg
                    db backg, red, red, red, red, red, red, backg, backg, backg
                    db backg, backg, red, red, red, red, backg, backg, backg, backg
                    db backg, backg, backg, red, red, backg, backg, backg, backg, backg


poisoned_apple_sprite   db backg, backg, backg, backg, backg, yellow, yellow, backg, backg, backg
                        db backg, backg, backg, backg, yellow, backg, backg, backg, backg, backg
                        db backg, backg, backg, green, green, backg, backg, backg, backg, backg
                        db backg, backg, green, green, green, green, backg, backg, backg, backg
                        db backg, green, green, green, green, green, green, backg, backg, backg
                        db green, green, green, green, green, green, green, green, backg, backg
                        db green, green, green, green, green, green, green, green, backg, backg
                        db backg, green, green, green, green, green, green, backg, backg, backg
                        db backg, backg, green, green, green, green, backg, backg, backg, backg
                        db backg, backg, backg, green, green, backg, backg, backg, backg, backg

burger_sprite   db backg, backg, brown, brown, brown, brown, brown, brown, backg, backg
                db backg, brown, brown, brown, brown, brown, brown, brown, brown, backg
                db brown, brown, brown, brown, brown, brown, brown, brown, brown, brown
                db yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow
                db red, red, red, red, red, red, red, red, red, red
                db red, red, red, red, red, red, red, red, red, red
                db yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow
                db brown, brown, brown, brown, brown, brown, brown, brown, brown, brown
                db backg, brown, brown, brown, brown, brown, brown, brown, brown, backg
                db backg, backg, brown, brown, brown, brown, brown, brown, backg, backg

portal_sprite   db brown, brown, brown, brown, brown, brown, brown, brown, brown, brown
                db brown, brown, brown, brown, backg, brown, brown, brown, brown, brown
                db brown, brown, brown, backg, backg, backg, brown, brown, brown, brown
                db brown, brown, backg, backg, backg, backg, backg, brown, brown, brown
                db brown, brown, backg, backg, backg, backg, backg, brown, brown, brown
                db brown, brown, backg, backg, backg, backg, backg, brown, brown, brown
                db brown, brown, backg, backg, backg, backg, backg, brown, brown, brown
                db brown, brown, brown, backg, backg, backg, brown, brown, brown, brown
                db brown, brown, brown, brown, backg, brown, brown, brown, brown, brown
                db brown, brown, brown, brown, brown, brown, brown, brown, brown, brown

snake_part_sprite   db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                    db backg, backg, green, green, green, green, green, green, backg, backg
                    db backg, green, yellow, green, yellow, green, green, yellow, green, backg
                    db backg, green, green, green, green, yellow, green, green, green, backg
                    db backg, green, green, yellow, green, green, green, yellow, green, backg
                    db backg, green, green, green, green, green, green, green, green, backg
                    db backg, green, yellow, green, green, yellow, green, green, yellow, backg
                    db backg, green, green, green, green, green, green, green, green, backg
                    db backg, backg, green, green, green, green, green, green, backg, backg
                    db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg


snake_head_up_sprite    db backg, backg, backg, green, backg, green, backg, backg, backg, backg
                        db backg, backg, backg, green, backg, green, backg, backg, backg, backg
                        db backg, backg, green, green, backg, green, green, backg, backg, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, green, green, green, green, green, green, green, green, backg
                        db backg, green, yellow, green, green, green, green, green, green, backg
                        db backg, green, yellow, green, green, green, green, green, green, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, backg, backg, green, green,green, green, backg, backg, backg


snake_head_right_sprite db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                        db backg, backg, backg, green, green, green, backg, backg, backg, backg
                        db backg, green, green, yellow, yellow, green, green, green, backg, backg
                        db green, green, green, green, green, green, green, green, green, green
                        db green, green, green, green, green, green, green, backg, backg, backg
                        db green, green, green, green, green, green, green, green, green, green
                        db green, green, green, green, green, green, green, green, backg, backg
                        db backg, green, green, green, green, green, green, backg, backg, backg
                        db backg, backg, backg, green, green, green, backg, backg, backg, backg
                        db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg

snake_head_down_sprite  db backg, backg, backg, green, green, green, green, backg, backg, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, green, green, green, green, green, green, yellow, green, backg
                        db backg, green, green, green, green, green, green, yellow, green, backg
                        db backg, green, green, green, green, green, green, green, green, backg
                        db backg, backg, green, green, green, green, green, green, backg, backg
                        db backg, backg, backg, green, green, backg, green, green, backg, backg
                        db backg, backg, backg, backg, green, backg, green, backg, backg, backg
                        db backg, backg, backg, backg, green, backg, green, backg, backg, backg


snake_head_left_sprite  db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg
                        db backg, backg, backg, backg, green, green, green, backg, backg, backg
                        db backg, backg, green, green, green, yellow, yellow, green, green, backg
                        db green, green, green, green, green, green, green, green, green, green
                        db backg, backg, backg, green, green, green, green, green, green, green
                        db green, green, green, green, green, green, green, green, green, green
                        db backg, backg, green, green, green, green, green, green, green, green
                        db backg, backg, backg, green, green, green, green, green, green, backg
                        db backg, backg, backg, backg, green, green, green, backg, backg, backg
                        db backg, backg, backg, backg, backg, backg, backg, backg, backg, backg



enter_graphics_mode proc
    push    ax bx es si di

    xor     ax, ax
    mov     es, ax

    mov     al, byte ptr es:[449h]
    mov     byte ptr old_graphics_mode, al

    mov     al, byte ptr es:[462h]
    mov     byte ptr old_graphics_page, al

    xor     ah, ah
    mov     al, byte ptr graphics_mode_number
    int     10h

    mov     ah, 05h
    mov     al, byte ptr graphics_page_number
    int     10h

    pop     di si es bx ax

    ret
enter_graphics_mode endp


exit_graphics_mode proc
    push    ax bx es

    xor     ah, ah
    mov     al, byte ptr old_graphics_mode
    int     10h

    mov     ah, 05h
    mov     al, byte ptr old_graphics_page
    int     10h

    pop     es bx ax
    ret
exit_graphics_mode endp


prints MACRO string_offset, y, x
    lea     bx, string_offset
    mov     dh, y
    mov     dl, x
    call    print_string
ENDM

; bx = word offset, dh = y, dl = x
print_string proc
    push    ax bx cx dx

    push    bx
    mov     bx, 0
    mov     ah, 2
    int     10h

    pop     dx
    mov     ah, 9
    int     21h

    pop     dx cx bx ax
    ret
endp


; dx - y ax - x
load_line_offset_to_di proc
    push    ax dx

    mov     bx, ax
    mov     ax, screen_width
    mul     dx
    mov     di, ax
    add     di, bx

    pop     dx ax
    ret
endp


; si - sprite offset, dx - y, ax - x
draw_sprite proc
    push    ax bx cx dx es si di

    call    load_line_offset_to_di

    mov     ax, 0A000h
    mov     es, ax

    xor     ax, ax

    cld

@@lines_loop:
    ;copy line
    mov     cx, sprite_width
    rep     movsb

    add     di, (screen_width - sprite_width)

    inc     ax
    cmp     ax, sprite_height
    jl      @@lines_loop


    pop     di si es dx cx bx ax
    ret
endp


draw_map proc
    push    ax cx bx dx si di

    xor     dx, dx
    xor     ch, ch
    lea     bx, map

@@lines_loop:
    xor     ax, ax
    xor     cl, cl

@@column_loop:

    call    draw_object

    add     ax, sprite_width
    add     bx, type(map_object_t)
    inc     cl
    cmp     cl, map_width
    jl      @@column_loop

    add     dx, sprite_height
    inc     ch
    cmp     ch, map_height
    jl      @@lines_loop

    pop     di si dx bx cx ax
    ret
endp


clear_screen proc
    push    ax cx di es

    mov     ax, 0A000h
    mov     es, ax
    xor     di, di
    mov     bx, (screen_height * screen_width)

    cld

    xor     al, al

@@clear_loop:
    stosb

    dec     bx
    ja      @@clear_loop

    pop     es di bx ax
    ret
endp


; same order, as numbers of map_object_type_* values
map_object_type_to_sprite   dw empty_sprite
                            dw brick_wall_sprite
                            dw spring_wall_sprite
                            dw apple_sprite
                            dw poisoned_apple_sprite
                            dw burger_sprite
                            dw portal_sprite
                            dw snake_head_left_sprite
                            dw snake_head_right_sprite
                            dw snake_head_up_sprite
                            dw snake_head_down_sprite
                            dw snake_part_sprite


;bx - map pointer
;dx - screen y, ax - screen x
draw_object proc
    push cx bx

    xor     cx, cx
    mov     cl, [bx]._type

    lea     bx, map_object_type_to_sprite
    shl     cx, 1
    add     bx, cx
    mov     si, [bx]

    call    draw_sprite

    pop     bx cx
    ret
endp


;dh - y, dl - x
;returns dx - y ax - x
translate_cords proc
    push    bx cx

    mov     bx, dx

    xor     dl, dl
    mov     dl, dh
    mov     ax, sprite_height
    mul     dx

    mov     cx, ax

    mov     dx, bx
    xor     dh, dh
    mov     ax, sprite_width
    mul     dx

    mov     dx, cx

    pop     cx bx
    ret
endp

