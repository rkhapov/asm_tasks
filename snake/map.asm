map_object_type_none            equ 0
map_object_type_brick_wall      equ 1
map_object_type_spring_wall     equ 2
map_object_type_apple           equ 3
map_object_type_poisoned_apple  equ 4
map_object_type_burget          equ 5
map_object_type_portal          equ 6
map_object_type_snake_left      equ 7
map_object_type_snake_right     equ 8
map_object_type_snake_up        equ 9
map_object_type_snake_down      equ 10

map_object_life_time_enternity  equ 0FFh

map_object_t struc
    _type       db map_object_type_none
    _life_time  db map_object_life_time_enternity
map_object_t ends


map_width equ screen_width / 10
map_height equ screen_height / 10
map_size equ (map_width * map_height)

map map_object_t map_size dup(<>)


; dh - y, dl - x
load_map_bx_index_by_dx proc
    push    ax dx cx

    push    dx

    mov     ax, map_width * type(map_object_t)
    xor     dl, dl
    shr     dx, 8
    mul     dx

    mov     bx, ax

    pop     dx
    xor     dh, dh
    mov     cx, dx
@@adding:
    add     bx, type(map_object_t)
    loop    @@adding

    pop     cx dx ax
    ret
endp


;dh - y, dl - x
;returns bx - pointer to map_object at dx
get_map_object_ref proc
    push    ax dx

    call    load_map_bx_index_by_dx
    lea     dx, map[bx]

    pop     dx ax
    ret
endp


initialize_map proc
    ret
endp