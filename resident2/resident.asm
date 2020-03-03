.model tiny
.code

org 100h

locals @@

_start:
    jmp     call_main

    default_multiplex_handler     dd ?
    
    get_signature                 equ 2ABCh
    resident_return_signature     equ 0FFh
    
    get_default_handler           equ 2ACBh

    get_resident_address          equ 2CABh


;
; Multiplex handler
; functions:
;  - for get_signature in ax, returns resident_return_signature in al
;  - for get_default_handler in ax, returns address of default_handler in es:bx
;  - for get_resident_address in ax, returns address of resident in es:bx
;  - prints hello_string and calls default handler otherwise
;

hello_string db 'Hello from my handler!', 13, 10, '$'

multiplex_hundler proc
    cmp     ax, get_signature
    je      @@return_signature

    cmp     ax, get_default_handler
    je      @@return_default_handler

    cmp     ax, get_resident_address
    je      @@return_my_address

    jmp     @@call_default_handler

@@return_signature:
    mov     al, resident_return_signature
    jmp     @@to_return

@@return_default_handler:
    mov     bx, cs:word ptr default_multiplex_handler
    mov     es, cs:word ptr default_multiplex_handler + 2
    jmp     @@to_return

@@return_my_address:
    push    cs
    pop     es
    mov     bx, offset multiplex_hundler

@@to_return:
    iret

@@call_default_handler:
    ; push    ds
    ; push    ax

    ; push    cs
    ; pop     ds
    ; mov     dx, offset hello_string
    ; mov     ah, 09h
    ; int     21h

    ; pop     ax
    ; pop     ds
    jmp     cs:default_multiplex_handler    
multiplex_hundler endp

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

    mov     ax, get_signature
    int     2Fh

    cmp     al, resident_return_signature
    je      @@already_installed

    mov     ax, 352Fh
    int     21h

    mov     word ptr default_multiplex_handler,     bx
    mov     word ptr default_multiplex_handler + 2, es

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

    mov     ax, 252Fh
    lea     dx, multiplex_hundler
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

    mov     ax, 3100h
    lea     dx, resident_end + 15
    shr     dx, 4
    int     21h

@@to_return:
    mov     sp, bp
    pop     bp
    ret
create_resident_by_function endp

o_flag: db 0
n_flag: db 0
k_flag: db 0
f_flag: db 0

;    \w, write
;    +--------+
;    |        |
;    v    -   +
;+-->0+--++-->1+--+
;    ^   |        |
;    |   +<-------+
;    |   |   !\w
;    +---+
;      !-

setup_control_flags proc
    push    bp
    mov     bp, sp

    push    ax
    push    bx
    push    cx
    push    dx
    push    si

    xor     cx, cx
	mov     cl, byte ptr ds:[80h]
    add     cl, 2
    mov     si, 81h

    xor     bl, bl

@@arguments_traverse:
    dec     cx
    jz      @@arguments_traverse_end

    lodsb

    test    bl, bl
    jnz     @@state_1

@@state_0:
    cmp     al, '-'
    je      @@to_state_1

    jmp     @@arguments_traverse

@@to_state_1:
    mov     bl, 1
    jmp     @@arguments_traverse

@@state_1:
    xor     bl, bl

    cmp     al, 'o'
    je      @@setup_o_flag

    cmp     al, 'n'
    je      @@setup_n_flag

    cmp     al, 'k'
    je      @@setup_k_flag

    cmp     al, 'f'
    je      @@setup_f_flag

    jmp     @@arguments_traverse

@@setup_o_flag:
    mov     byte ptr o_flag, 1
    jmp     @@arguments_traverse

@@setup_n_flag:
    mov     byte ptr n_flag, 1
    jmp     @@arguments_traverse

@@setup_k_flag:
    mov     byte ptr k_flag, 1
    jmp     @@arguments_traverse

@@setup_f_flag:
    mov     byte ptr f_flag, 1
    jmp     @@arguments_traverse

@@arguments_traverse_end:
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    mov     sp, bp
    pop     bp
    ret
setup_control_flags endp

just_install_handler proc
    push    bp
    mov     bp, sp

    push    ax
    push    bx

    mov     al, byte ptr n_flag
    cmp     al, 1

    je      @@create_by_new_way

@@create_by_old_way:
    call    create_resident_by_interruption
    mov     ah, 09h
    lea     dx, error_installing
    int     21h
    jmp     @@to_return

@@create_by_new_way:
    call    create_resident_by_function
    mov     ah, 09h
    lea     dx, error_installing
    int     21h

@@to_return:
    pop     bx
    pop     ax

    mov     sp, bp
    pop     bp
    ret
just_install_handler endp

not_installed_string db "Resident not installed", 13, 10, '$'


is_hundler_last proc
    push    bp
    mov     bp, sp

    push    bx
    push    dx
    push    cx
    push    es

    mov     ax, 352fh
    int     21h

    mov     dx, bx
    mov     cx, es

    mov     ax, get_resident_address
    int     2fh

    push    es
    pop     ax
    cmp     ax, cx
    jne     @@not_last

    cmp     bx, dx
    jne     @@not_last

    mov     ax, 1

    jmp     @@to_return

@@not_last:
    xor     ax, ax

@@to_return:
    pop     es
    pop     cx
    pop     dx
    pop     bx

    mov     sp, bp
    pop     bp
    ret
is_hundler_last endp


setup_default_handler proc
    push    ax
    push    bx
    push    dx
    push    ds
    push    es

    mov     ax, get_default_handler
    int     2fh

    push    es
    pop     ds
    mov     dx, bx
    mov     ax, 252fh
    int     21h

    pop     es
    pop     ds
    pop     dx
    pop     bx
    pop     ax

    ret
setup_default_handler endp


current_handler dd ?

save_current_handler proc
    push    ax
    push    bx
    push    es

    mov     ax, get_resident_address
    int     2fh

    mov     word ptr current_handler,     bx
    mov     word ptr current_handler + 2, es

    pop     es
    pop     bx
    pop     ax
    ret
save_current_handler endp


remove_resident proc
    push    ax
    push    bx
    push    es

    mov     es, word ptr current_handler + 2

    mov     ah, 49h
    int     21h

    pop     es
    pop     bx
    pop     ax
    ret
remove_resident endp

cant_remove_not_last db "Cant remove not last resident", 13, 10, '$'

just_remove_handler proc
    mov     ax, get_signature
    int     2fh

    cmp     al, resident_return_signature
    jne     @@not_installed

    call    is_hundler_last

    cmp     ax, 1
    je      @@handler_is_last

    jmp     @@handler_is_not_last

@@handler_is_last:
    call    save_current_handler
    call    setup_default_handler
    call    remove_resident

    jmp     @@to_return

@@handler_is_not_last:
    mov     al, byte ptr f_flag
    cmp     al, 1

    jne     @@cant_remove_not_last_l

    call    save_current_handler
    call    setup_default_handler
    call    remove_resident

@@cant_remove_not_last_l:
    mov     ah, 09h
    mov     dx, offset cant_remove_not_last
    int     21h

    jmp     @@to_return

@@not_installed:
    mov     ah, 09h
    mov     dx, offset not_installed_string
    int     21h

@@to_return:
    ret
just_remove_handler endp

is_flags_setup proc
    mov     al, byte ptr o_flag
    mov     bl, byte ptr n_flag
    add     al, bl
    mov     bl, byte ptr k_flag
    add     al, bl
    mov     bl, byte ptr f_flag
    add     al, bl

    test    al, al

    jnz     @@yes

    jmp     @@to_return

@@yes:
    mov     ax, 1

@@to_return:
    ret
is_flags_setup endp

;
; "Entry point" of the program
; Checks the command line arguments and select right way to create resident
; Terminates and starts the resident nor returns error code
;
usage_string db "flags:", 13, 10,
             db  " -o - to use 27h interrupt", 13, 10,
             db  " -n - to use function 31h", 13, 10,
             db  " -k - kill resident if possible", 13, 10,
             db  " -f - force kill resident", 13, 10, '$'
error_installing db "Resident already installed", 10, 13, '$'

main proc
    push    bp
    mov     bp, sp

    call    setup_control_flags

    call    is_flags_setup

    cmp     ax, 1
    jne     @@invalid_usage

    mov     al, byte ptr k_flag
    cmp     al, 1

    je      @@to_kill

    jmp     @@to_install

@@to_kill:
    call    just_remove_handler
    jmp     @@to_return 

@@to_install:
    call    just_install_handler
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
