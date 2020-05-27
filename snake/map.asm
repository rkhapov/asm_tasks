map_object_type_none            equ 0
map_object_type_brick_wall      equ 1
map_object_type_spring_wall     equ 2
map_object_type_apple           equ 3
map_object_type_poisoned_apple  equ 4
map_object_type_burger          equ 5
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


map_object_life_time_apple equ 20


map_width equ screen_width / 10
map_height equ screen_height / 10
map_size equ (map_width * map_height)

map map_object_t (map_size + 10) dup(<>)


nop
nop
nop
nop
nop
nop
nop
nop


; dh - y
load_y_index_to_bx proc
    push    ax dx

    xor     ax, ax
    mov     al, dh
    mov     bx, map_width * type(map_object_t)
    mul     bx

    mov     bx, ax

    pop     dx ax
    ret
endp

; dl - x
load_x_index_to_bx proc
    push    ax dx

    xor     ax, ax
    mov     al, dl
    mov     bx, type(map_object_t)
    mul     bx

    mov     bx, ax

    pop     dx ax
    ret
endp

; dh - y, dl - x
load_map_bx_index_by_dx proc
    call    load_y_index_to_bx
    mov     ax, bx
    call    load_x_index_to_bx
    add     ax, bx

    mov     bx, ax
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


map2    db 'BSSSSSSSSSSSSSSSSSSSBPPPPPPPPPPB'
        db 'B                   B          B'
        db 'B                   B          B'
        db 'B                   B          B'
        db 'B                   B          B'
        db 'B                   B          B'
        db 'B                   B          B'
        db 'B    SSSS           B          B'
        db 'B    SBBS           B          B'
        db 'B    SSSS           BBBBBBBBBBBB'
        db 'B                              B'
        db 'B                              B'
        db 'B                              B'
        db 'B                              B'
        db 'B                              B'
        db 'B     BBBBBBBBBBBBBBBB         B'
        db 'B                              B'
        db 'B                              B'
        db 'B                              B'
        db 'BBBBBBBBBBBBBBBBBBBBBPPPPPPPPPPB'


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


update_map proc
    push    ax bx cx

    mov     ax, map_size
    lea     bx, map

@@update_cycle:
    mov     cl, [bx]._life_time

    cmp     cl, map_object_life_time_enternity
    je      @@continue

    dec     cl
    jnz     @@continue

    mov     [bx]._type, map_object_type_none
    mov     [bx]._life_time, map_object_life_time_enternity

@@continue:
    mov     [bx]._life_time, cl
    add     bx, type(map_object_t)
    dec     ax
    jge     @@update_cycle

    pop     cx bx ax
    ret
endp


;dl - type dh - lifetime
spawn_random proc
    push    ax cx bx

    push    dx

@@while_not_empty:
    call    generate_random_cords

    mov     dl, ah
    mov     dh, al
    call    get_map_object_ref

    cmp     [bx]._type, map_object_type_none
    jne     @@while_not_empty

    pop     dx

    mov     [bx]._type, dl
    mov     [bx]._life_time, dh

    pop     bx cx ax
    ret
endp


;al - object type
;al = 1 if object of that type exists on map
has_object_with_type proc
    push    bx cx

    mov     cx, map_size
    lea     bx, map

@@find:
    cmp     [bx]._type, al
    jne     @@continue

    mov     al, 1
    jmp     @@to_return

@@continue:
    add     bx, type(map_object_t)
    dec     cx
    jg      @@find

    xor     al, al

@@to_return:
    pop     cx bx
    ret
endp


spawn_apples proc
    push    dx ax

    xor     ah, ah
    mov     al, byte ptr start_apple_count

@@spawning:
    mov     dl, map_object_type_apple
    mov     dh, map_object_life_time_apple
    call    spawn_random

    dec     ax
    jg      @@spawning

    pop     ax dx
    ret
endp


spawn_objects_if_needed proc
    push    ax dx

    mov     al, map_object_type_apple
    call    has_object_with_type

    test    al, al
    jnz     @@apple_exists

    mov     dl, map_object_type_apple
    mov     dh, map_object_life_time_apple
    call    spawn_random

@@apple_exists:
    mov     al, map_object_type_poisoned_apple
    call    has_object_with_type

    test    al, al
    jnz     @@poisoned_apple_exists

    mov     dl, map_object_type_poisoned_apple
    mov     dh, map_object_life_time_apple
    call    spawn_random

@@poisoned_apple_exists:
    mov     al, map_object_type_burger
    call    has_object_with_type

    test    al, al
    jnz     @@burger_exists

    mov     dl, map_object_type_burger
    mov     dh, map_object_life_time_apple
    call    spawn_random

@@burger_exists:
    pop     dx ax
    ret
endp
