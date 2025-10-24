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
    newline_len equ $ - newline

    separator db ' '
    separator_len equ $ - separator

    hex_prefix db "0x"
    hex_prefix_len equ $ - hex_prefix

    oct_prefix db "0o"
    oct_prefix_len equ $ - oct_prefix

    bin_prefix db "0b"
    bin_prefix_len equ $ - bin_prefix

; ------------------
; UNINITIALIZED DATA
; ------------------

section .bss
    buf resb 32             ; Reserve 32 bytes for digits and prefixes

; ----
; CODE
; ----

section .text
    global _start

%macro repr 2
    ; Print the appropriate prefix
    print %1 
    ; Prepare call arguments
    mov rdi, r12    ; The number to convert
    mov rsi, %2     ; The conersion base
    call convert
%endmacro

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
    movzx r12, al           ; Save original value in r12

    ; Print decimal representation
    mov rdi, r12
    mov rsi, 10
    call convert

    ; Print space separator
    print separator

    ; Print hexadecimal representation
    repr hex_prefix, 16

    ; Print space separator
    print separator

    ; Print octal representation
    repr oct_prefix, 8

    ; Print space separator
    print separator

    ; Print binary representation
    repr bin_prefix, 2

    ; Write newline
    print newline

    ; Exit with Success Status Code
    exit EXIT_SUCCESS

; Print the usage message and exit
.usage:
    print usage_msg
    exit EXIT_FAILURE

; --------
; ROUTINES
; --------

; convert: rdi = number, rsi = base (e.g. 10, 16, 8, 2)
; Prints the appropriate representation
convert:
    lea rbx, [buf+31]
    xor rcx, rcx
    mov rax, rdi
    mov r8, rsi         ; Store base -> r8 for later reuse 

    cmp rax, 0
    jne .loop

    dec rbx
    mov byte [rbx], '0'
    inc rcx
    jmp .done

    .loop:
        xor rdx, rdx
        div r8          ; divide rax by base, remainder in rdx
        mov dl, dl      ; remainder in dl

        cmp rdx, 9
        jg .hex_digit
        add dl, '0'
        jmp .store

    .hex_digit:
        add dl, 'A' - 10

    .store:
        dec rbx
        mov [rbx], dl
        inc rcx
        test rax, rax
        jnz .loop

    .done:
        ; Write digits
        ; rbx -> pointer to first digit (we decremented before storing)
        ; rcx -> number of digits
        ; Save values before write macro clobbers them
        mov rsi, rbx        ; buffer pointer
        mov rdx, rcx        ; byte count

        ; Write number string
        mov rax, SYS_WRITE
        mov rdi, FD_STDOUT
        ; rsi and rdx are already set
        syscall
        ret

