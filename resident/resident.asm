.model tiny
.code

org 80h
cmd_length db ?
cmd_line   db ?

org 100h

locals @@

_start:
    jmp     call_main

    default_handler           dd ?
    default_multiplex_handler dd ?
    multiplex_function_number equ 2ABCh
    multiplex_return_code     equ 0FFh


;
; Multiplex handler for defence against deploying copies of general resident in memory
;
multiplex_hundler proc
    pushf
    
    cmp     ax, multiplex_function_number
    jne     @@call_default_handler

    mov     al, multiplex_return_code

    popf
    iret

@@call_default_handler:
    popf
    jmp     cs:default_multiplex_handler    
multiplex_hundler endp


resident_end:

;
; Check for resident are already runned
; if yes - returns 1
; otherwise sets the multiplex interrupt hundler and returns 0
;

install_multiplex_handler proc
    push    bp
    mov     bp, sp

    push    bx
    push    dx
    push    es

    mov     ax, multiplex_function_number
    int     2Fh

    cmp     al, multiplex_return_code
    je      @@already_runned

    mov     ax, 352Fh
    int     21h

    mov     word ptr default_multiplex_handler,     bx
    mov     word ptr default_multiplex_handler + 2, es

    mov     ax, 252Fh
    lea     dx, multiplex_hundler
    int     21h

    xor     ax, ax
    jmp     @@to_return

@@already_runned:
    mov     ax, 1

@@to_return:
    pop     bx
    pop     dx
    pop     es

    mov     sp, bp
    pop     bp    
    ret
install_multiplex_handler endp

;
; Store default handler at default_handler variable
;

save_dafault_handler proc
    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    es

    mov     ax, 3521h
    int     21h

    mov     word ptr default_handler,     bx
    mov     word ptr default_handler + 2, es

    pop     es
    pop     bx
    pop     ax

    mov     sp, bp
    pop     bp
    ret
save_dafault_handler endp


;
; Set current 21h handler to new handler
;

set_handler proc
    push    bp
    mov     bp, sp

    call    save_dafault_handler

    mov     sp, bp
    pop     bp
    ret
set_handler endp


;
; Create resident by interrupt 27h
; An old way to create one, doesnt allow to pass return code
; and have limit of the resident size up to 64KB
;

create_resident_by_interruption proc
    push    bp
    mov     bp, sp

    call    install_multiplex_handler
    cmp     ax, 1
    je      @@to_return

    call    set_handler

    lea     dx, resident_end + 1
    int     27h

@@to_return:
    mov     sp, bp
    pop     bp
    ret
create_resident_by_interruption endp

;
; Create resident by function
;

create_resident_by_function proc
    ret
create_resident_by_function endp

;
; "Entry point" of the program
; Checks the command line arguments and select right way to create resident
; Terminates and starts the resident nor returns error code
;

usage_string db "Make funny string printing! Use argument o - to use 27h interrupt or n - to use function 31h", 10, 13, '$'
error_installing db "Couldnt install resident", 10, 13, '$'

main proc
    push    bp
    mov     bp, sp

    ; need to compare with 2, because start space symbol are included at command line
    cmp     byte ptr cmd_length, 2

    jne     @@invalid_usage
    mov     al, byte ptr [cmd_line + 1]

    cmp     al, 'o'
    jmp     @@using_old_version

    cmp     al, 'n'
    jmp     @@using_new_version

    jmp     @@invalid_usage

@@using_old_version:
    call    create_resident_by_interruption
    mov     ah, 09h
    lea     dx, error_installing
    int     21h
    mov     al, 1
    jmp     @@to_return

@@using_new_version:
    call    create_resident_by_function
    mov     ah, 09h
    lea     dx, error_installing
    int     21h
    mov     al, 1
    jmp     @@to_return

@@invalid_usage:
    mov     ah, 09h
    lea     dx, usage_string
    int     21h
    mov     al, 1

@@to_return:
    mov     sp, bp
    pop     bp
    ret
main endp


call_main:
    call    main
    mov     ah, 4CH
    int     21h
end _start
