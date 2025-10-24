; ASCII Lookup

; -----------
; DEFINITIONS
; -----------

%define SYS_WRITE   1
%define SYS_EXIT    60

%define FD_STDOUT   1

; ------
; MACROS
; ------

%macro write 3
    mov rax, SYS_WRITE  ; syscall: write
    mov rdi, %1         ; file-descriptor
    mov rsi, %2         ; buffer to write
    mov rdx, %3         ; number of bytes to write
    syscall
%endmacro

%macro print 1
    write FD_STDOUT, %1, %1_len
%endmacro

%macro exit 1
    mov rax, SYS_EXIT   ; syscall: exit
    mov rdi, %1         ; exit status code
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
    print hello_world
    exit 0
