.model tiny

.code

org 100h

_start:
    jmp actual_start

    default_handler dd ?

actual_start:
    mov     ax, 352fh
   
    ret
end _start
