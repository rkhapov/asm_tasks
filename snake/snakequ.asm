snake_direction_up      equ 0
snake_direction_down    equ 1
snake_direction_left    equ 2
snake_direction_right   equ 3

snake_current_direction db snake_direction_right

snake_max_length equ 50

snake_head_x_pos db ?
snake_head_y_pos db ?

snake_current_length db 0


update_head_position proc
    push    ax

    mov     al, byte ptr snake_current_direction

    cmp     al, snake_direction_up
    je      @@up

    cmp     al, snake_direction_down
    je      @@down

    cmp     al, snake_direction_left
    je      @@left

    cmp     al, snake_direction_right
    je      @@right

@@up:
    dec     byte ptr snake_head_y_pos
    jmp     @@to_return

@@down:
    inc     byte ptr snake_head_y_pos
    jmp     @@to_return

@@left:
    dec     byte ptr snake_head_x_pos
    jmp     @@to_return

@@right:
    inc     byte ptr snake_head_x_pos
    jmp     @@to_return

@@to_return:
    pop     ax
    ret
endp


;al - snake length
spawn_snake proc
    push    ax bx cx dx

    mov     byte ptr game_is_over, 0

    mov     byte ptr snake_current_length, al
    mov     byte ptr snake_current_direction, snake_direction_right

    mov     dh, 11
    mov     dl, 13
    mov     cl, 1

@@spawn_body:
    call    get_map_object_ref
    mov     [bx]._type, map_object_type_snake_body
    mov     [bx]._life_time, cl

    inc     dl
    inc     cl
    cmp     cl, byte ptr snake_current_length
    jne     @@spawn_body

    call    get_map_object_ref
    mov     [bx]._type, map_object_type_snake_right
    mov     [bx]._life_time, cl

    mov     byte ptr snake_head_y_pos, dh
    mov     byte ptr snake_head_x_pos, dl

    pop     dx cx bx ax
    ret
endp


game_is_over db 0


compute_cut_intersection_mode proc
    push    ax bx cx dx di

    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    get_map_object_ref

    mov     cl, [bx]._life_time
    mov     al, byte ptr snake_current_length
    sub     al, cl
    inc     al
    mov     byte ptr snake_current_length, al

    lea     bx, map
    mov     dx, map_size

@@map_traversee:
    cmp     byte ptr [bx]._type, map_object_type_snake_body
    jne     @@continue

    cmp     byte ptr [bx]._life_time, cl
    jl      @@delete_part

    sub     byte ptr [bx]._life_time, cl

    jmp     @@continue

@@delete_part:
    mov     byte ptr [bx]._life_time, map_object_life_time_enternity
    mov     byte ptr [bx]._type, map_object_type_none

@@continue:
    add     bx, type(map_object_t)
    dec     dx
    jne     @@map_traversee

    pop     di dx cx bx ax
    ret
endp


;al - is critical
calculate_self_intersection proc
    cmp     byte ptr intersection_mode, intersection_mode_death
    je      @@critical

    cmp     byte ptr intersection_mode, intersection_mode_nothing
    je      @@non_critical

    call    compute_cut_intersection_mode
    jmp     @@non_critical

@@critical:
    mov     byte ptr game_is_over, 1
    mov     al, 1
    jmp     @@to_return

@@non_critical:
    xor     al, al

@@to_return:
    ret
endp



;dh - y, dl x
;ah - dy, al - dx
;returns valid coordinates in dx, if portal was found
try_find_portal proc
    push    ax bx cx

    mov     cx, ax

    ;one more step to not get neighbour
    add     dh, ch
    add     dl, cl

@@finding:
    add     dh, ch
    add     dl, cl

    call    inbound
    test    al, al
    jz      @@finding_end

    call    get_map_object_ref
    cmp     byte ptr [bx]._type, map_object_type_portal
    je      @@finding_end

    jmp     @@finding

@@finding_end:

    pop     cx bx ax
    ret
endp


;ah - dy, al - dx
;returns al - success flag
try_move_to_portal proc
    push    dx bx

    mov     bx, ax

    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    try_find_portal

    call    inbound
    test    al, al
    jz      @@not_found

    sub     dl, bl
    sub     dh, bh
    mov     byte ptr snake_head_y_pos, dh
    mov     byte ptr snake_head_x_pos, dl
    mov     al, 1
    jmp     @@to_return

@@not_found:
    xor     al, al

@@to_return:
    pop     bx dx
    ret
endp

;al - success flag
try_move_to_left_portal proc
    mov     ah, 0
    mov     al, -1
    call    try_move_to_portal
    ret
endp

;al - success flag
try_move_to_right_portal proc
    mov     ah, 0
    mov     al, 1
    call    try_move_to_portal
    ret
endp

;al - success flag
try_move_to_up_portal proc
    mov     ah, -1
    mov     al, 0
    call    try_move_to_portal
    ret
endp

;al - success flag
try_move_to_down_portal proc
    mov     ah, 1
    mov     al, 0
    call    try_move_to_portal
    ret
endp


portal_not_found_msg db 'Portal not found', 10, 13, '$'

compute_portal_collision proc
    push    ax

    cmp     byte ptr snake_current_direction, snake_direction_up
    je      @@find_in_down

    cmp     byte ptr snake_current_direction, snake_direction_left
    je      @@find_in_right

    cmp     byte ptr snake_current_direction, snake_direction_down
    je      @@find_in_up

    ;only one option - find in left

@@find_in_left:
    call    try_move_to_left_portal
    test    al, al
    jnz     @@to_return
    jmp     @@not_found

@@find_in_right:
    call    try_move_to_right_portal
    test    al, al
    jnz     @@to_return
    jmp     @@not_found

@@find_in_up:
    call    try_move_to_up_portal
    test    al, al
    jnz     @@to_return
    jmp     @@not_found

@@find_in_down:
    call    try_move_to_down_portal
    test    al, al
    jnz     @@to_return
    jmp     @@not_found

@@not_found:
    ;bx is not saved, because in this case we will never return
    lea     bx, portal_not_found_msg
    call    abort

@@to_return:
    pop     ax
    ret
endp


make_direction_opposite proc
    cmp     byte ptr snake_current_direction, snake_direction_down
    je      @@make_up

    cmp     byte ptr snake_current_direction, snake_direction_up
    je      @@make_down

    cmp     byte ptr snake_current_direction, snake_direction_left
    je      @@make_right

    mov     byte ptr snake_current_direction, snake_direction_left
    jmp     @@to_return

@@make_up:
    mov     byte ptr snake_current_direction, snake_direction_up
    jmp     @@to_return

@@make_down:
    mov     byte ptr snake_current_direction, snake_direction_down
    jmp     @@to_return

@@make_right:
    mov     byte ptr snake_current_direction, snake_direction_right

@@to_return:
    ret
endp

;al - number returns al - success flag
emplace_tail proc
    push    bx cx dx

    lea     bx, map
    xor     dh, dh

@@lines_cycle:
    xor     dl, dl

@@columns_cycle:
    cmp     byte ptr [bx]._type, map_object_type_snake_body
    jne     @@continue

    cmp     byte ptr [bx]._life_time, al
    jne     @@continue

    call    make_direction_opposite
    mov     byte ptr snake_head_y_pos, dh
    mov     byte ptr snake_head_x_pos, dl
    call    spawn_snake_head

    mov     al, 1
    jmp     @@break

@@continue:
    add     bx, type(map_object_t)
    inc     dl
    cmp     dl, map_width
    jb      @@columns_cycle

    inc     dh
    cmp     dh, map_height
    jb      @@lines_cycle

    xor     al, al

@@break:
    pop     dx cx bx
    ret
endp

move_head_to_tail_cord proc
    push    ax

    mov     ax, 0101h

@@cycle:
    mov     al, ah
    call    emplace_tail
    test    al, al
    jnz     @@break

    inc     ah
    jmp     @@cycle

@@break:
    pop     ax
    ret
endp


inverse_life_times proc
    push    bx ax dx cx

    mov     dx, map_size
    lea     bx, map

    mov     al, byte ptr snake_current_length

@@traverse:
    cmp     byte ptr [bx]._type, map_object_type_snake_body
    jne     @@continue
    
    mov     cl, byte ptr [bx]._life_time
    neg     cl
    add     cl, al
    inc     cl
    mov     byte ptr [bx]._life_time, cl

@@continue:
    add     bx, type(map_object_t)
    dec     dx
    jne     @@traverse

    pop     cx dx ax bx
    ret
endp


compute_spring_wall_collision proc
    call    move_head_to_tail_cord
    call    inverse_life_times
    ret
endp


on_collision proc
    push    dx cx bx

    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    get_map_object_ref

    mov     al, [bx]._type

    cmp     al, map_object_type_brick_wall
    je      @@do_collision_with_brick_wall

    cmp     al, map_object_type_spring_wall
    je      @@do_collision_with_spring_wall

    cmp     al, map_object_type_apple
    je      @@do_collision_with_apple

    cmp     al, map_object_type_poisoned_apple
    je      @@do_collision_with_poisoned_apple

    cmp     al, map_object_type_snake_body
    je      @@do_collision_with_own_body

    cmp     al, map_object_type_portal
    je      @@do_collistion_with_portal

    jmp     @@do_collision_with_brick_wall

@@do_collision_with_brick_wall:
    mov     byte ptr game_is_over, 1
    jmp     @@critical

@@do_collision_with_apple:
    call    music_push_apple_eaten_sound
    inc     word ptr apples_eaten
    inc     byte ptr snake_current_length
    jmp     @@non_critical

@@do_collision_with_spring_wall:
    call    music_push_spring_sound
    call    compute_spring_wall_collision
    jmp     @@non_critical

@@do_collision_with_poisoned_apple:
    call    music_push_poisoned_apple_eaten_sound
    inc     word ptr poisoned_apple_eaten
    cmp     byte ptr snake_current_length, 2
    jg      @@decrease_length

    mov     byte ptr game_is_over, 1
    jmp     @@critical

@@do_collision_with_own_body:
    call    calculate_self_intersection
    test    al, al
    jnz     @@critical
    jmp     @@non_critical

@@do_collistion_with_portal:
    call    music_push_portal_sound
    call    compute_portal_collision
    jmp     @@non_critical

@@decrease_length:
    dec     byte ptr snake_current_length
    jmp     @@non_critical

@@non_critical:
    mov     al, 1
    jmp     @@to_return

@@critical:
    xor     al, al

@@to_return:
    pop     bx cx dx
    ret
endp


update_snake_position_to_current_direction proc
    push    ax bx cx dx

    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    get_map_object_ref

    mov     [bx]._type, map_object_type_snake_body

    call    update_head_position

    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    get_map_object_ref

    cmp     [bx]._type, map_object_type_none
    je      @@no_collision

    call    on_collision

    test    al, al
    jz      @@to_return

@@no_collision:
    call    spawn_snake_head

@@to_return:
    pop     dx cx bx ax
    ret
endp


spawn_snake_head proc
    push    ax bx dx

    cmp     byte ptr snake_current_direction, snake_direction_down
    je      @@setup_down_head

    cmp     byte ptr snake_current_direction, snake_direction_up
    je      @@setup_up_head

    cmp     byte ptr snake_current_direction, snake_direction_left
    je      @@setup_left_head

    cmp     byte ptr snake_current_direction, snake_direction_right
    je      @@setup_right_head

@@setup_down_head:
    mov     al, map_object_type_snake_down
    jmp     @@setup_end

@@setup_up_head:
    mov     al, map_object_type_snake_up
    jmp     @@setup_end

@@setup_left_head:
    mov     al, map_object_type_snake_left
    jmp     @@setup_end

@@setup_right_head:
    mov     al, map_object_type_snake_right
    jmp     @@setup_end

@@setup_end:
    mov     dh, byte ptr snake_head_y_pos
    mov     dl, byte ptr snake_head_x_pos
    call    get_map_object_ref
    mov     [bx]._type, al
    mov     al, byte ptr snake_current_length
    mov     [bx]._life_time, al

    pop     dx bx ax

    ret
endp


try_set_direction_to_up proc
    cmp     byte ptr snake_current_direction, snake_direction_down
    je      @@not_setted
    mov     byte ptr snake_current_direction, snake_direction_up
    mov     al, 1
    jmp     @@to_return
@@not_setted:
    xor     al, al
@@to_return:
    ret
endp


try_set_direction_to_down proc
    cmp     byte ptr snake_current_direction, snake_direction_up
    je      @@not_setted
    mov     byte ptr snake_current_direction, snake_direction_down
    mov     al, 1
    jmp     @@to_return
@@not_setted:
    xor     al, al
@@to_return:
    ret
endp


try_set_direction_to_left proc
    cmp     byte ptr snake_current_direction, snake_direction_right
    je      @@not_setted
    mov     byte ptr snake_current_direction, snake_direction_left
    mov     al, 1
    jmp     @@to_return
@@not_setted:
    xor     al, al
@@to_return:
    ret
endp


try_set_direction_to_right proc
    cmp     byte ptr snake_current_direction, snake_direction_left
    je      @@not_setted
    mov     byte ptr snake_current_direction, snake_direction_right
    mov     al, 1
    jmp     @@to_return
@@not_setted:
    xor     al, al
@@to_return:
    ret
endp
