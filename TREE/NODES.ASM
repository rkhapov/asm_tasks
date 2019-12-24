__TREE_START_MSG__ db "!!!TREE STARTED HERE!!!"

tree db 4096 dup(0)

node_size equ 1 + 1 + 13 + 30 + 10 + 1 + 1
node_index_field        equ 0
node_isdirectory_field  equ 1
node_name_field         equ 2
node_path_field         equ 15
node_children_field     equ 45
node_depth_field        equ 55
node_actual_depth_field equ 56

free_node_pointer dw tree
free_node_index db 1

create_node proc
@@arg_name equ [bp + 8]
@@arg_path equ [bp + 6]
@@arg_isdirectory equ [bp + 4]

    push bp
    mov bp, sp

    push bx

    mov bx, word ptr [free_node_pointer]

    mov al, byte ptr [free_node_index]
    mov node_index_field[bx], al
    inc byte ptr [free_node_index]

    mov ax, @@arg_isdirectory
    mov node_isdirectory_field[bx], al

    mov ax, @@arg_name
    push ax
    lea ax, node_name_field[bx]
    push ax
    call memcpy
    add sp, 4

    mov ax, @@arg_path
    push ax
    lea ax, node_path_field[bx]
    push ax
    call memcpy
    add sp, 4

    mov ax, bx

    mov ax, free_node_pointer
    add word ptr [free_node_pointer], node_size

    pop bx

    mov sp, bp
    pop bp
    ret
create_node endp


get_node_by_index proc
@@arg_index equ [bp + 4]

    push bp
    mov bp, sp
    push bx
    push dx

    mov ax, @@arg_index
    dec ax
    mov bx, node_size
    mul bx

    lea bx, tree
    add ax, bx

    pop dx
    pop bx
    mov sp, bp
    pop bp
    ret
get_node_by_index endp


append_child proc
@@arg_node_ptr equ [bp + 6]
@@arg_child_idx equ [bp + 4]

    push bp
    mov bp, sp

    push ax
    push bx

    mov bx, @@arg_node_ptr
    add bx, node_children_field
  
@@l:
    mov al, [bx]

    test al, al
    jz @@l_end
    inc bx
    jmp @@l

@@l_end:
    mov ax, @@arg_child_idx
    mov [bx], al

    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret
append_child endp
