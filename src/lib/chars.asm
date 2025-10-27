; ----------------
; ASCII CHARACTERS
; ----------------

section .data
    three_spaces db "   "
    three_spaces_len equ $ - three_spaces

    ; Control character abbreviations (4 chars total, including padding space)
    ctrl_00 db "NUL "
    ctrl_01 db "SOH "
    ctrl_02 db "STX "
    ctrl_03 db "ETX "
    ctrl_04 db "EOT "
    ctrl_05 db "ENQ "
    ctrl_06 db "ACK "
    ctrl_07 db "BEL "
    ctrl_08 db "BS  "
    ctrl_09 db "HT  "
    ctrl_0A db "LF  "
    ctrl_0B db "VT  "
    ctrl_0C db "FF  "
    ctrl_0D db "CR  "
    ctrl_0E db "SO  "
    ctrl_0F db "SI  "
    ctrl_10 db "DLE "
    ctrl_11 db "DC1 "
    ctrl_12 db "DC2 "
    ctrl_13 db "DC3 "
    ctrl_14 db "DC4 "
    ctrl_15 db "NAK "
    ctrl_16 db "SYN "
    ctrl_17 db "ETB "
    ctrl_18 db "CAN "
    ctrl_19 db "EM  "
    ctrl_1A db "SUB "
    ctrl_1B db "ESC "
    ctrl_1C db "FS  "
    ctrl_1D db "GS  "
    ctrl_1E db "RS  "
    ctrl_1F db "US  "
    ctrl_7F db "DEL "

; Array of pointers to control character strings
; Each entry is 8 bytes (dq)
ctrl_char_ptrs:
    dq ctrl_00, ctrl_01, ctrl_02, ctrl_03, ctrl_04, ctrl_05, ctrl_06, ctrl_07
    dq ctrl_08, ctrl_09, ctrl_0A, ctrl_0B, ctrl_0C, ctrl_0D, ctrl_0E, ctrl_0F
    dq ctrl_10, ctrl_11, ctrl_12, ctrl_13, ctrl_14, ctrl_15, ctrl_16, ctrl_17
    dq ctrl_18, ctrl_19, ctrl_1A, ctrl_1B, ctrl_1C, ctrl_1D, ctrl_1E, ctrl_1F

section .text
    global print_char

; Print the character itself (uses '.' for non-printable characters)
print_char:
    mov rax, r12
    cmp rax, 32
    jb .is_control_char
    cmp rax, 127
    je .is_del_char

    ; Printable characters (32-126)
    mov [buf], rax
    mov rsi, buf
    mov rdx, 1
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    syscall
    jmp .done

; Handle control characters (0-31)
.is_control_char:
    mov rbx, rax                            ; Save character value
    mov rax, rbx
    shl rax, 3                              ; Multiply by 8 (size of dq)
    lea rsi, [ctrl_char_ptrs + rax]
    mov rsi, [rsi]                          ; Load the address of the string
    mov rdx, 4                              ; Length of control char abbreviation
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    syscall
    jmp .done

; Handle DEL character (127)
.is_del_char:
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, ctrl_7F
    mov rdx, 4
    syscall
    jmp .done

; Done printing character
.done:
    print separator
    ret
