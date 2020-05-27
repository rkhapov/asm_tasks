snake_direction_up      equ 0
snake_direction_down    equ 1
snake_direction_left    equ 2
snake_direction_right   equ 3

snake_current_direction db snake_direction_right

snake_max_length equ 50

snake_head_x_pos db ?
snake_head_y_pos db ?

snake_current_length db ?


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
