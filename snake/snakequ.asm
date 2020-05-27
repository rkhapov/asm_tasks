snake_direction_up      equ 0
snake_direction_down    equ 1
snake_direction_left    equ 2
snake_direction_right   equ 3

snake_current_direction db snake_direction_right


snake_cord_invalid equ 0FFh


snake_part_t struc
    _x_cord db snake_cord_invalid
    _y_cord db snake_cord_invalid
snake_part_t ends


snake_max_length equ 50

snake_queue snake_part_t snake_max_length dup(<>)
snake_queue_free_pointer dw snake_queue
snake_queue_length  db 0


snake_queue_clear proc
    push    bx ax

    mov     ax, snake_max_length
    lea     bx, snake_queue

@@clean_loop:
    mov     [bx]._x_cord, snake_cord_invalid
    mov     [bx]._y_cord, snake_cord_invalid

    add     bx, type(snake_part_t)

    dec     ax
    jge     @@clean_loop

    pop     ax bx
    ret
ends


; dh - y dl - x
; snake_queue_push proc
;     push    bx

;     mov     bx, word ptr snake_queue_free_pointer

;     mov     [bx]._x_cord, dl
;     mov     [bx]._y_cord, dh

;     call    get_map_object_ref

;     cmp     bx, offset snake_queue

; @@insert_head:

; @@insert_body:

;     add     word ptr snake_queue_free_pointer, type(snake_part_t)
;     inc     byte ptr snake_queue_length

;     pop     bx
;     ret
; endp


snake_queue_pop_tail proc
    push    bx

    mov     bx, word ptr snake_queue_free_pointer
    sub     bx, type(snake_part_t)

    mov     [bx]._x_cord, snake_cord_invalid
    mov     [bx]._y_cord, snake_cord_invalid

    dec     byte ptr snake_queue_length

    pop     bx
    ret
endp


; returns al - length
snake_queue_get_length proc
    mov     al, byte ptr snake_queue_length
    ret
endp