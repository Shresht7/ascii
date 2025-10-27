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

; --------
; INCLUDES
; --------

%include "src/lib/chars.asm"
%include "src/lib/strings.asm"

; ----------------
; INITIALIZED DATA
; ----------------

section .data
    usage_msg db "Usage: ascii <character> | [flag]", 0xA, 0xA
              db "Flags:", 0xA
              db "  -f, --full      Display the full ASCII table.", 0xA
              db "  -h, --help      Display this help message.", 0xA
    usage_msg_len equ $ - usage_msg

    arg_help db "--help", 0
    arg_full db "--full", 0
    arg_h db "-h", 0
    arg_f db "-f", 0

    newline db 0xA
    newline_len equ $ - newline

    separator db ' '
    separator_len equ $ - separator

    ten db ""           ; dec is a keyword so... ten it is
    ten_len equ 0

    hex db "0x"
    hex_len equ $ - hex

    oct db "0o"
    oct_len equ $ - oct

    bin db "0b"
    bin_len equ $ - bin

    err_out_of_ascii_bounds_msg db "Error: Out of bounds for ASCII. Should be a valid ASCII character between 0 and 127", 0xA
    err_out_of_ascii_bounds_msg_len equ $ - err_out_of_ascii_bounds_msg

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

; Prints the correct representation
; %1 = repr prefix (or empty), %2 = base
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
    mov rdi, [rsp+16]       ; argv[1]

    ; Check for --help
    mov rsi, arg_help
    call strcmp
    cmp rax, 0
    je .usage

    ; Check for -h
    mov rdi, [rsp+16]
    mov rsi, arg_h
    call strcmp
    cmp rax, 0
    je .usage

    ; Check for --full
    mov rdi, [rsp+16]
    mov rsi, arg_full
    call strcmp
    cmp rax, 0
    je .full_table

    ; Check for -f
    mov rdi, [rsp+16]
    mov rsi, arg_f
    call strcmp
    cmp rax, 0
    je .full_table

    ; If no flag matches, process as a character
    mov rsi, [rsp+16]       ; argv[1]
    mov al, [rsi]           ; first character (pointer to rsi)

    ; Check that argv[1] is not empty
    cmp al, 0
    je .usage               ; empty string, show usage

    ; Check ASCII range (0..127)
    cmp al, 127
    ja .err_out_of_ascii_bounds     ; Error: Out of ASCII Bounds (0..127)

.process_chars:
    movzx r12, al           ; Save original value in r12

    ; Print decimal representation
    repr ten, 10            ; No prefix after repr => decimal representation

    ; Print space separator
    print separator

    ; Print hexadecimal representation
    repr hex, 16

    ; Print space separator
    print separator

    ; Print octal representation
    repr oct, 8

    ; Print space separator
    print separator

    ; Print binary representation
    repr bin, 2

    ; Write newline
    print newline

    jmp .done

.full_table:
    xor r12, r12            ; Counter = 0
    .table_loop:
        call print_char
        mov rdi, r12
        repr ten, 10
        print separator
        repr hex, 16
        print separator
        repr oct, 8
        print separator
        repr bin, 2
        print newline
        inc r12
        cmp r12, 128
        jne .table_loop         ; Loop until 128
        jmp .done

.done:
    ; Exit with Success Status Code
    exit EXIT_SUCCESS

; ERROR BRANCHES
; --------------

; Print the usage message and exit
.usage:
    print usage_msg
    exit EXIT_FAILURE

.err_out_of_ascii_bounds:
    print err_out_of_ascii_bounds_msg
    exit 1

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

