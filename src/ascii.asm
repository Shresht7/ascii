; ASCII Lookup

; -----------
; DEFINITIONS
; -----------

%define SYS_WRITE       1
%define SYS_EXIT        60

%define FD_STDOUT       1

%define EXIT_SUCCESS    0
%define EXIT_FAILURE    1

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
    usage_msg db "Usage: ascii <char>", 0xA
    usage_msg_len equ $ - usage_msg

; ----
; CODE
; ----

section .text
    global _start

; The main entrypoint of the application
_start:
    ; Retrieve argument count (argc)
    ; When the program starts, rsp points to argc
    mov rax, [rsp]          ; Move argc value into rax
    cmp rax, 2              ; Compare argc with 2 (program_name + first_argument)
    jl .usage               ; less than 2 => Insufficient Arguments. Show Usage message 

    ; Exit with Success Status Code
    exit EXIT_SUCCESS

; Print the usage message and exit
.usage:
    print usage_msg
    exit EXIT_FAILURE
