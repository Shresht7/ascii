#ifndef SYS_CALLS_ASM
#define SYS_CALLS_ASM

; -----------
; DEFINITIONS
; -----------

SYS_WRITE       equ 1
SYS_EXIT        equ 60

FD_STDOUT       equ 1

EXIT_SUCCESS    equ 0
EXIT_FAILURE    equ 1

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

#endif
