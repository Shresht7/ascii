; ASCII Lookup

section .data
    hello_world db "Hello World!", 0xA
    hello_world_len equ $ - hello_world

section .text
    global _start

_start:
    mov rax, 1                      ; syscall: write
    mov rdi, 1                      ; file-descriptor: stdout
    lea rsi, [rel hello_world]      ; buffer to write
    mov rdx, hello_world_len        ; the number of bytes to write
    syscall

    mov rax, 60                     ; syscall: exit
    xor rdi, rdi                    ; status-code: 0
    syscall
