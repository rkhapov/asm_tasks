menu_run_level1     equ 0
menu_run_level2     equ 1
menu_run_level3     equ 2
menu_exit           equ 3


help_title              db 'Snake game about$'
help_controls           db 'Controls:$'
help_controls_esc       db '* ESC to exit$'
help_controls_arrows    db '* arrows to control snake$'
help_controls_pause     db '* P to pause game$'
help_controls_speed     db '* +\- to control speed$'
help_collectables       db 'Collectables:$'
help_collectables_apple db '* red apple - increase length$'
help_collectables_bad_a db '* green apple - decrease length$'
help_collectables_burge db '* burger - instant death$'
help_walls              db 'Walls:$'
help_walls_brick        db '* bricks - instant death$'
help_walls_hole         db '* hole - teleport to opposite hole$'
help_walls_springs      db '* springs - reverse snake direction$'
help_press_enter        db 'Press ENTER to continue$'


show_help proc
    push    bx dx

    call    clear_screen

    lea     bx, help_title
    mov     dh, 1
    mov     dl, 12
    call    print_string


    lea     bx, help_controls
    mov     dh, 3
    mov     dl, 1
    call    print_string

    lea     bx, help_controls_esc
    mov     dh, 5
    mov     dl, 1
    call    print_string

    lea     bx, help_controls_arrows
    mov     dh, 6
    mov     dl, 1
    call    print_string

    lea     bx, help_controls_pause
    mov     dh, 7
    mov     dl, 1
    call    print_string

    lea     bx, help_controls_speed
    mov     dh, 8
    mov     dl, 1
    call    print_string


    lea     bx, help_collectables
    mov     dh, 10
    mov     dl, 1
    call    print_string

    lea     bx, help_collectables_apple
    mov     dh, 12
    mov     dl, 1
    call    print_string

    lea     bx, help_collectables_bad_a
    mov     dh, 13
    mov     dl, 1
    call    print_string

    lea     bx, help_collectables_burge
    mov     dh, 14
    mov     dl, 1
    call    print_string


    lea     bx, help_walls
    mov     dh, 16
    mov     dl, 1
    call    print_string

    lea     bx, help_walls_brick
    mov     dh, 18
    mov     dl, 1
    call    print_string

    lea     bx, help_walls_hole
    mov     dh, 19
    mov     dl, 1
    call    print_string

    lea     bx, help_walls_springs
    mov     dh, 20
    mov     dl, 1
    call    print_string


    lea     bx, help_press_enter
    mov     dh, 22
    mov     dl, 8
    call    print_string

    mov     al, scancode_enter
    call    keyboard_wait_until

    pop     dx bx
    ret
endp

space_str db '                                               $'

;si - pointer to selections array
;dx - current selection number
print_selections proc
    push    ax bx dx cx si di

    cld
    xor     cx, cx

    mov     di, 2

@@cycle:
    lodsw
    mov     bx, ax

    test    bx, bx
    jz      @@cycle_end

    cmp     dx, cx
    je      @@selection_is_current

    mov     byte ptr [bx], ' '

    jmp     @@continue

@@selection_is_current:
    mov     byte ptr [bx], '>'

@@continue:
    push    dx

    xor     dx, dx
    mov     dx, di
    xchg    dh, dl
    mov     dl, 1

    mov     ax, bx

    lea     bx, space_str
    call    print_string

    mov     bx, ax
    call    print_string

    pop     dx

    inc     cx
    add     di, 2
    jmp     @@cycle

@@cycle_end:
    pop     di si cx dx bx ax
    ret
endp


selections_no_selection equ 0FFh


;si - pointer to selections array, terminated with 0
;returns ax - selection index, and 0FFh in case ESC key pressed
do_selections_list proc
    push    bx cx dx si di

    xor     dx, dx

    call    keyboard_clear_buffer

    call    strlen
    shr     ax, 1
    mov     di, ax
    dec     di

    call    clear_screen

@@selection_cycle:
    call    print_selections

@@wait_key_cycle:
    hlt
    call    keyboard_pop_from_buffer
    cmp     al, keyboard_no_scancode
    je      @@wait_key_cycle

    cmp     al, scancode_esc
    je      @@esc_key_pressed

    cmp     al, scancode_up
    je      @@up_selection

    cmp     al, scancode_down
    je      @@down_selection

    cmp     al, scancode_enter
    je      @@enter_selection

    jmp     @@continue_selection_cycle

@@up_selection:
    cmp     dx, 0
    je      @@continue_selection_cycle
    dec     dx
    jmp     @@continue_selection_cycle

@@down_selection:
    cmp     dx, di
    je      @@continue_selection_cycle
    inc     dx
    jmp     @@continue_selection_cycle

@@enter_selection:
    mov     ax, dx
    jmp     @@to_return

@@continue_selection_cycle:
    jmp     @@selection_cycle

@@esc_key_pressed:
    mov     ax, selections_no_selection

@@to_return:
    pop     di si dx cx bx
    ret
endp


menu_start_str   db ' Select level$'
menu_help_str    db ' Help$'
menu_exit_str    db ' Exit$'

main_menu_selections dw menu_start_str, menu_help_str, menu_exit_str, 0

level1_str  db ' Level 1$'
level2_str  db ' Level 2$'
level3_str  db ' Level 3$'

level_selections dw level1_str, level2_str, level3_str, 0

;returns menu_* result at ax
run_menu proc
    push    si

@@to_main_menu_selection:
    lea     si, main_menu_selections
    call    do_selections_list

    cmp     ax, selections_no_selection
    je      @@exit_selection

    cmp     ax, 2
    je      @@exit_selection

    cmp     ax, 1
    jne     @@to_level_selection

    call    show_help
    jmp     @@to_main_menu_selection

@@to_level_selection:
    lea     si, level_selections
    call    do_selections_list

    cmp     ax, selections_no_selection
    je      @@to_main_menu_selection

    jmp     @@to_return

@@exit_selection:
    mov     ax, menu_exit

@@to_return:
    pop     si
    ret
endp
