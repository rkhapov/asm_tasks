.model tiny
.code

org 100h

locals @@

_start:
    jmp call_main

    files_mask         db '\', '*.*', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    separator          db '\', 0, 0
    max_depth          dw 100
    dirs_mask          db '\', '*', 0, 0, 0
    empty_name         db 0, 0, 0, 0

    tab_size equ 1
    tab_char equ ' '
    line equ 179
    horizontal_line equ 196
    close_line equ 192
    branch equ 195

    DTA                db 50 dup(0)

    usage              db "Usage: tree <path> -d depth -f search_suffix", 0dh, 0ah, '$'
    usage_length       equ $ - usage

    include STRINGS.ASM
    include ARGPARSE.ASM
    include NODES.ASM
    include PRINTERS.ASM

    tree_root dw ?


create_nodes_return_buffer db 50 dup(0)
create_nodes_buffer db 50 dup(0)

append_at_return_buffer proc
@@arg_node_ptr equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push si

    lea si, create_nodes_return_buffer
    
@@l:
    mov ax, word ptr [si]

    test ax, ax
    jz @@l_end
    add si, 2
    jmp @@l

@@l_end:
    mov ax, @@arg_node_ptr
    mov [si], ax

    pop si
    pop ax

    mov sp, bp
    pop bp
    ret
append_at_return_buffer endp

create_nodes_for_path proc
@@arg_path equ [bp + 4]

    push bp
    mov bp, sp

    push bx
    push cx
    push dx

    lea ax, create_nodes_return_buffer
    push ax
    mov ax, 50
    push ax
    call zeromem
    add sp, 4

    lea ax, create_nodes_buffer
    push ax
    mov ax, 50
    push ax
    call zeromem
    add sp, 4

    mov ax, @@arg_path
    push ax
    lea ax, create_nodes_buffer
    push ax
    call memcpy
    add sp, 4

    lea ax, dirs_mask
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    mov cx, 10h ; files and directories
    mov ah, 4eh
    lea dx, create_nodes_buffer
    int 21h

@@dirs_enumeration:
    jc @@dirs_enumeration_end

    mov al, byte ptr 1eh[DTA]
    cmp al, '.'
    je @@dirs_enumeration_continue

    lea ax, create_nodes_buffer
    push ax
    mov ax, 50
    push ax
    call zeromem
    add sp, 4

    mov ax, @@arg_path
    push ax
    lea ax, create_nodes_buffer
    push ax
    call memcpy
    add sp, 4
    
    lea ax, separator
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    lea ax, 1eh[DTA]
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    lea ax, 1eh[DTA]
    push ax
    lea ax, create_nodes_buffer
    push ax
    mov ax, 1
    push ax
    call create_node
    add sp, 6

    push ax
    call append_at_return_buffer
    add sp, 2

@@dirs_enumeration_continue:

    mov ah, 4fh
    int 21h
    jmp @@dirs_enumeration

@@dirs_enumeration_end:

    lea ax, create_nodes_buffer
    push ax
    mov ax, 50
    push ax
    call zeromem
    add sp, 4

    mov ax, @@arg_path
    push ax
    lea ax, create_nodes_buffer
    push ax
    call memcpy
    add sp, 4

    lea ax, files_mask
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    xor cx, cx
    mov ah, 4eh
    lea dx, create_nodes_buffer
    int 21h

@@files_enumeration:
    jc @@files_enumeration_end

    lea ax, create_nodes_buffer
    push ax
    mov ax, 50
    push ax
    call zeromem
    add sp, 4

    mov ax, @@arg_path
    push ax
    lea ax, create_nodes_buffer
    push ax
    call memcpy
    add sp, 4
    
    lea ax, separator
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    lea ax, 1eh[DTA]
    push ax
    lea ax, create_nodes_buffer
    push ax
    call strconcat
    add sp, 4

    lea ax, 1eh[DTA]
    push ax
    lea ax, create_nodes_buffer
    push ax
    xor ax, ax
    push ax
    call create_node
    add sp, 6

    push ax
    call append_at_return_buffer
    add sp, 2

@@files_enumeration_continue:

    mov ah, 4fh
    int 21h
    jmp @@files_enumeration

@@files_enumeration_end:

    pop dx
    pop cx
    pop bx

    lea ax, create_nodes_return_buffer

    mov sp, bp
    pop bp
    ret
create_nodes_for_path endp


append_empty_children proc
@@arg_node_ptr equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push cx
    push bx
    push si

    mov bx, @@arg_node_ptr
    lea ax, node_path_field[bx]
    push ax
    call create_nodes_for_path
    add sp, 2

    mov bx, ax

@@adding:
    mov ax, [bx]

    test ax, ax
    jz @@adding_end

    mov si, ax
    mov ax, node_index_field[si]
    xor ah, ah

    mov cx, @@arg_node_ptr
    push cx
    push ax
    call append_child
    add sp, 2

    add bx, 2
    jmp @@adding

@@adding_end:

    pop si
    pop bx
    pop cx
    pop ax

    mov sp, bp
    pop bp
    ret
append_empty_children endp


fill_node proc
@@arg_node_ptr equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bx, @@arg_node_ptr
    mov al, node_isdirectory_field[bx]

    test al, al
    jz @@to_return


    mov bx, @@arg_node_ptr
    push bx
    call append_empty_children
    add sp, 2

    mov bx, @@arg_node_ptr
    lea si, node_children_field[bx]

@@enumerating:
    lodsb

    test al, al
    jz @@enumerating_end

    xor ah, ah
    push ax
    call get_node_by_index
    add sp, 2

    push ax
    call fill_node
    add sp, 2

    jmp @@enumerating

@@enumerating_end:

@@to_return:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
fill_node endp


set_depths proc
@@arg_node_ptr equ [bp + 6]
@@depth        equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push si

    mov bx, @@arg_node_ptr
    mov ax, @@depth
    mov node_depth_field[bx], al

    lea si, node_children_field[bx]

@@enumerating:
    lodsb

    test al, al
    jz @@enumerating_end

    xor ah, ah
    push ax
    call get_node_by_index
    add sp, 2

    push ax
    mov cx, @@depth
    inc cx
    push cx
    call set_depths
    add sp, 4

    jmp @@enumerating

@@enumerating_end:

    pop si
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
set_depths endp


increase_actual_at_right proc
@@arg_node_ptr equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push si

    mov bx, @@arg_node_ptr

    inc byte ptr node_actual_depth_field[bx]

@@not_decreasing:

    lea si, node_children_field[bx]

    cmp byte ptr [si], 0
    je @@to_return

@@enumerating:
    lodsb

    test al, al
    jnz @@enumerating

    mov al, -2[si]

    xor ah, ah
    push ax
    call get_node_by_index
    add sp, 2

    push ax
    call increase_actual_at_right
    add sp, 2

    push ax
    call increase_actual_at_right
    add sp, 2

@@to_return:
    pop si
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
increase_actual_at_right endp


print_children proc
@@arg_node_ptr equ [bp + 8]
@@depth        equ [bp + 6]
@@actual_depth equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, @@arg_node_ptr

    lea si, node_children_field[bx]

@@enumeration:
    lodsb

    test al, al
    jz @@to_return

    xor ah, ah
    push ax
    call get_node_by_index
    add sp, 2

    mov bx, ax
    cmp byte ptr node_isdirectory_field[bx], 1
    jne @@not_directory

    cmp byte ptr node_children_field[bx], 0
    je @@enumeration

@@not_directory:

    mov cl, node_actual_depth_field[bx]
    mov dl, node_depth_field[bx]

    xor dh, dh
    xor ch, ch

    xor bx, bx
    cmp byte ptr [si], 0
    jnz @@not_last

    mov bx, 1

@@not_last:

    push ax
    push dx
    push cx
    push bx
    call print_node
    add sp, 8

    jmp @@enumeration

@@to_return:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_children endp

print_node proc
@@arg_node_ptr equ [bp + 10]
@@depth        equ [bp + 8]
@@actual_depth equ [bp + 6]
@@is_last      equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx

    mov ax, @@depth
    cmp ax, max_depth
    jae @@to_return


    mov bx, @@arg_node_ptr
    lea ax, node_name_field[bx]
    push ax
    mov ax, @@depth
    push ax
    mov ax, @@actual_depth
    push ax
    mov ax, @@is_last
    push ax
    call print_name
    add sp, 8

    mov ax, @@arg_node_ptr
    push ax
    mov ax, @@depth
    push ax
    mov ax, @@actual_depth
    push ax
    call print_children
    add sp, 6

@@to_return:

    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
print_node endp


main proc
@@argc equ [bp - 2]
@@argv equ [bp - 4]
    push bp
    mov bp, sp
    sub sp, 6

    mov ax, [bp + 4]
    mov @@argv, ax
    mov ax, [bp + 6]
    mov @@argc, ax

    cmp ax, 1

    jl @@invalid_args

    mov ah, 1ah
    lea dx, DTA
    int 21h

    mov ax, @@argc
    push ax
    mov ax, @@argv
    push ax
    call configure_parameters
    add sp, 4

    lea ax, empty_name
    push ax
    mov bx, @@argv
    mov ax, [bx]
    push ax
    mov ax, 1
    push ax
    call create_node
    add sp, 6

    mov word ptr [tree_root], ax
    
    mov ax, word ptr [tree_root]
    push ax
    call fill_node
    add sp, 2

    mov ax, word ptr [tree_root]
    push ax
    mov ax, -1
    push ax
    call set_depths
    add sp, 4

    mov ax, word ptr [tree_root]
    push ax
    call increase_actual_at_right
    add sp, 2

    mov ax, word ptr [tree_root]
    push ax
    xor ax, ax
    push ax
    push ax
    call print_children
    add sp, 6

    jmp @@to_return

@@invalid_args:
    mov ah, 09h
    lea dx, usage
    int 21h

@@to_return:
    xor ax, ax

    mov sp, bp
    pop bp
    ret
main endp

call_main:
    call parse_arguments

    xor ax, ax
    mov al, arguments_count
    push ax
    lea ax, arguments_pointers
    push ax
    call main

    mov ah, 4Ch
    int 21h
end _start
