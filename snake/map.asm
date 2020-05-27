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
map_object_type_snake_body      equ 11

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
    lea     bx, map[bx]

    pop     dx ax
    ret
endp


clear_map proc
    push    ax bx cx dx di

    lea     di, map
    mov     ax, map_size

@@clear_cycle:
    mov     [di]._type, map_object_type_brick_wall
    mov     [di]._life_time, map_object_life_time_enternity

    add     di, type(map_object_t)
    dec     ax
    jge     @@clear_cycle

    pop     di dx cx bx ax
    ret
endp


map1    db 'PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'PSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSP'


map2    db 'PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'P                              P'
        db 'PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP'


map3    db 'SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'S                              S'
        db 'SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS'


all_maps dw map1, map2, map3


;si - map pointer
read_map proc
    push    ax bx cx di

    lea     di, map
    mov     cx, map_size

    cld

@@clear_cycle:
    lodsb
    mov     [di]._life_time, map_object_life_time_enternity

    cmp     al, 'B'
    je      @@do_brick_wall

    cmp     al, 'P'
    je      @@do_portal_wall

    cmp     al, 'S'
    je      @@do_spring_wall

    mov     al, map_object_type_none

    jmp     @@continue

@@do_brick_wall:
    mov     al, map_object_type_brick_wall
    jmp     @@continue

@@do_portal_wall:
    mov     al, map_object_type_portal
    jmp     @@continue

@@do_spring_wall:
    mov     al, map_object_type_spring_wall

@@continue:
    mov     [di]._type, al

    add     di, type(map_object_t)
    dec     cx
    jge     @@clear_cycle

    pop     di cx bx ax
    ret
endp



;ax - map number
initialize_map proc
    push    bx si

    mov     bx, ax
    shl     bx, 1
    mov     si, [all_maps + bx]
    call    read_map

    pop     si bx
    ret
endp