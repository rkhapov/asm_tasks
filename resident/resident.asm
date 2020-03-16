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
    cmp     ax, multiplex_function_number
    jne     @@call_default_handler

    mov     al, multiplex_return_code

    iret

@@call_default_handler:
    jmp     cs:default_multiplex_handler    
multiplex_hundler endp

;
; Reverse $-ended string
;
reverse_string proc
@@string_ptr equ [bp + 4]

    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    si
    push    di

    mov     di, @@string_ptr
    mov     si, di
    cld

@@shift_si_to_end:
    lodsb
    cmp     al, '$'
    jne     @@shift_si_to_end

    ; si points to after $ symbol, so it is necessary to shift it to left twice
    sub     si, 2

@@reversing:
    cmp     si, di
    jb      @@reverse_end

    mov     al, [si]
    mov     bl, [di]
    mov     [si], bl
    mov     [di], al

    dec     si
    inc     di

    jmp     @@reversing

@@reverse_end:
    pop     di
    pop     si
    pop     bx
    pop     ax

    mov     sp, bp
    pop     bp
    ret
reverse_string endp

;
; Invert letter case
;
do_inverse_letter_case proc
    cmp     dl, 'A'
    jb      @@to_return

    cmp     dl, 'z'
    ja      @@to_return

    cmp     dl, 'Z'
    jbe     @@invert_to_lower

    cmp     dl, 'a'
    jae     @@invert_to_upper

    jmp     @@to_return

@@invert_to_lower:
    add     dl, 97 - 65
    jmp     @@to_return

@@invert_to_upper:
    sub     dl, 97 - 65

@@to_return:
    ret
do_inverse_letter_case endp

;
; New Handler for 21h interruption
; Checks if called dos function is 09h and reverse the string if it is
; Checks if called dos function is 02h and inverse case of the letter if it is
;
dos_functions_handler proc
    cmp     ah, 09h
    je      @@reverse_string

    cmp     ah, 02h
    je      @@inverse_letter_case

    jmp     @@call_dos_default_handler

@@reverse_string:
    push    dx
    call    reverse_string
    add     sp, 2
    jmp     @@call_dos_default_handler

@@inverse_letter_case:
    call    do_inverse_letter_case

@@call_dos_default_handler:
    jmp     cs:default_handler
dos_functions_handler endp

resident_end:

hexademical_alphabet db '0123456789ABCDEF'

print_hex_num proc
    push    bp
    mov     bp, sp

    push    dx
    push    bx
    push    cx

    mov     cx, 4

@@l:
    xor     dx, dx
    mov     bx, 16
    div     bx

    lea     bx, hexademical_alphabet
    add     bx, dx
    mov     dl, [bx]
    push    dx
    
    loop    @@l

    mov     cx, 4

@@l2:
    pop     dx
    mov     ah, 02h
    int     21h
    loop    @@l2

    pop     cx
    pop     bx
    pop     dx

    mov     sp, bp
    pop     bp
    ret
print_hex_num endp

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
    je      @@already_installed

    mov     ax, 352Fh
    int     21h

    mov     word ptr default_multiplex_handler,     bx
    mov     word ptr default_multiplex_handler + 2, es

    mov     ax, 252Fh
    lea     dx, multiplex_hundler
    int     21h

    xor     ax, ax
    jmp     @@to_return

@@already_installed:
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
; Set current 21h handler to new handler
;
set_handler proc
    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    es

    mov     ax, 3521h
    int     21h

    mov     word ptr default_handler,     bx
    mov     word ptr default_handler + 2, es

    mov     ax, es
    call    print_hex_num
    mov     ah, 02h
    mov     dl, ':'
    int     21h
    mov     ax, bx
    call    print_hex_num
    mov     ah, 02h
    mov     dl, 10
    int     21h
    mov     dl, 13
    int     21h

    mov     ax, 2521h
    lea     dx, dos_functions_handler
    int     21h

    mov     ax, cs
    call    print_hex_num
    mov     ah, 02h
    mov     dl, ':'
    int     21h
    mov     ax, dx
    call    print_hex_num
    mov     ah, 02h
    mov     dl, 10
    int     21h
    mov     dl, 13
    int     21h

    pop     es
    pop     bx
    pop     ax

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
; Newer way to install resident, doesnt have limit of resident size
;
create_resident_by_function proc
    push    bp
    mov     bp, sp

    mov     ah, 30h
    int     21h

    cmp     al, 2
    jb      @@to_return

    call    install_multiplex_handler
    cmp     ax, 1
    je      @@to_return

    call    set_handler

    mov     ax, 3100h
    lea     dx, resident_end + 15
    shr     dx, 4
    int     21h

@@to_return:
    mov     sp, bp
    pop     bp
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
    mov     al, 2
    jmp     @@to_return

@@using_new_version:
    call    create_resident_by_function
    mov     ah, 09h
    lea     dx, error_installing
    int     21h
    mov     al, 2
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
