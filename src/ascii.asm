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

    newline db 0xA
    newline_len equ 1

; ------------------
; UNINITIALIZED DATA
; ------------------

section .bss
    buf resb 16             ; Reserve 16 bytes for buffer for decimal digits (enough for 0..255)

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

    ; Retrieve the first command-line argument argv[1]
    ; argv[0] contains the program-name and is at [rsp + 8] (8 bits offset from rsp (argc))
    ; argv[1] contains the first arugment (if it exists) and is at [rsp + 16] (8 * 2)
    mov rsi, [rsp+16]       ; argv[1]
    mov al, [rsi]           ; first character (pointer to rsi)
    movzx rbx, al           ; zero-extend into rbx (value 0..255)

    ; Prepare buffer pointer - fill from end
    lea rdi, [buf+15]       ; rdi will point to end; we'll decrement before writing digits
    xor rcx, rcx            ; digit count. Zero out for start

    ; handle value == 0. specially (print "0")
    cmp rbx, 0
    jne .dec_loop

    mov byte [rdi], '0'
    dec rdi
    inc rcx
    jmp .after_conversion

.dec_loop:
    ; Standard division loop:
    ; rbx = value
    ; we want (quotient, remainder) = value / 10
    mov rax, rbx        
    xor rdx, rdx        ; Zero out rdx
    mov r10, 10
    div r10             ; quotient -> rax, remainder -> rdx
    add dl, '0'         ; Ascii offset for 0 (as a string)
    dec rdi
    mov [rdi], dl
    mov rbx, rax        ; new value = quotient
    inc rcx

    test rax, rax
    jnz .dec_loop

.after_conversion:
    ; At this point:
    ; rdi -> pointer to first digit (we decremented before storing)
    ; rcx -> number of digits

    ; Save values before write macro clobbers them
    mov rsi, rdi        ; buffer pointer
    mov rdx, rcx        ; byte count


    ; Write decimal string
    mov rax, SYS_WRITE
    mov rdi, FD_STDOUT
    ; rsi and rdx are already set
    syscall

    ; Write newline
    print newline

    ; Exit with Success Status Code
    exit EXIT_SUCCESS

; Print the usage message and exit
.usage:
    print usage_msg
    exit EXIT_FAILURE
