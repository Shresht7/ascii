; ASCII Lookup

; -----------
; DEFINITIONS
; -----------

%define SYS_EXIT    60

; ------
; MACROS
; ------

%macro exit 1
    mov rax, SYS_EXIT   ; syscall: exit
    mov rdi, $1         ; exit status code
    syscall
%endmacro

; ----------------
; INITIALIZED DATA
; ----------------

section .data
    hello_world db "Hello World!", 0xA
    hello_world_len equ $ - hello_world

; ----
; CODE
; ----

section .text
    global _start

_start:
    mov rax, 1                      ; syscall: write
    mov rdi, 1                      ; file-descriptor: stdout
    lea rsi, [rel hello_world]      ; buffer to write
    mov rdx, hello_world_len        ; the number of bytes to write
    syscall

    exit 0
