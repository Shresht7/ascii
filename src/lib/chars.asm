; ----------------
; ASCII CHARACTERS
; ----------------

section .text
    global print_char

; Print the character itself (uses '.' for non-printable characters)
print_char:
    mov rax, r12
    cmp rax, 32
    jb .non_printable
    cmp rax, 126
    ja .non_printable
    mov [buf], rax
    mov rsi, buf
    mov rdx, 1
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    syscall
    jmp .done

    .non_printable:
        mov byte [buf], '.'
        mov rsi, buf
        mov rdx, 1
        mov rax, SYS_WRITE
        mov rdi, FD_STDOUT
        syscall

    .done:
        print separator
        ret
