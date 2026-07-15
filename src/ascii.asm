; ASCII Lookup

; --------
; INCLUDES
; --------

%include "src/lib/syscalls.asm"
%include "src/lib/chars.asm"
%include "src/lib/strings.asm"

; ----------------
; INITIALIZED DATA
; ----------------

FLAG_DEC equ 1 ; 0001 - Indicates that the decimal representation should be printed
FLAG_BIN equ 2 ; 0010 - Indicates that the binary representation should be printed
FLAG_HEX equ 4 ; 0100 - Indicates that the hexadecimal representation should be printed
FLAG_OCT equ 8 ; 1000 - Indicates that the octal representation should be printed

section .data

    ; USAGE
    ; -----

    usage_msg db "Usage: ascii <character> [character ...] | [flag]", 0xA, 0xA
              db "Flags:", 0xA
              db "  -f, --full      Display the full ASCII table.", 0xA
              db "  -h, --help      Display this help message.", 0xA
    usage_msg_len equ $ - usage_msg

    ; FLAGS
    ; -----

    flag_help db "--help", 0
    flag_h db "-h", 0
    
    flag_full db "--full", 0
    flag_f db "-f", 0

    flag_dec db "--dec", 0
    flag_d db "-d", 0
    flag_bin db "--bin", 0
    flag_b db "-b", 0
    flag_hex db "--hex", 0
    flag_x db "-x", 0
    flag_oct db "--oct", 0
    flag_o db "-o", 0

    ; PREFIXES
    ; --------

    ten db ""           ; dec is a keyword so... ten it is
    ten_len equ 0

    hex db "0x"
    hex_len equ $ - hex

    oct db "0o"
    oct_len equ $ - oct

    bin db "0b"
    bin_len equ $ - bin

    ; ERRORS
    ; ------

    err_unknown_flag_msg db "Error: Unknown flag provided", 0xA
    err_unknown_flag_msg_len equ $ - err_unknown_flag_msg

    err_out_of_ascii_bounds_msg db "Error: Out of bounds for ASCII. Should be a valid ASCII character between 0 and 127", 0xA
    err_out_of_ascii_bounds_msg_len equ $ - err_out_of_ascii_bounds_msg

    ; COMMON
    ; ------

    newline db 0xA
    newline_len equ $ - newline

    separator db ' '
    separator_len equ $ - separator

; ------------------
; UNINITIALIZED DATA
; ------------------

section .bss
    buf resb 32                         ; Reserve 32 bytes for digits and prefixes
    flags resb 1                        ; Reserve 1 byte for flags
    values resb 1024                    ; Buffer for up to 128 value pointers (8 bytes each)
    value_count resb 1                  ; How many values were stored

; ------
; MACROS
; ------

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

; ----
; CODE
; ----

section .text
    global _start

; The main entrypoint of the application
_start:

    ; ENSURE AT LEAST ONE ARGUMENT IS PROVIDED
    ; ----------------------------------------

    ; Retrieve argument count (argc)
    ; When the program starts, rsp points to argc
    mov r13, [rsp]                  ; Move argc value ([rsp]) into r13
    mov byte [flags], 0             ; Initialize flags to 0000
    cmp r13, 2                      ; Compare argc with 2 (program_name + first_argument)
    jl err_usage                    ; less than 2 => Insufficient Arguments. Show Usage message and exit

    ; PROCESS COMMAND-LINE ARGUMENTS
    ; ------------------------------

    mov byte [value_count], 0       ; Initialize value_count to 0
    lea r14, [rsp + 16]             ; Load address of argv[1] into r14 (argv starts at rsp + 8, argv[1] is at rsp + 16)
    mov r15, 1                      ; Initialize argument index to 1

    .process_args_loop:

        ; Exit loop if all arguments have been processed

        cmp r15, r13                ; Compare argument index with argc
        je .process_args_done       ; If they are equal, all arguments have been processed, exit the loop

        ; Check if the current argument is a flag or a value

        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov al, [rdi]               ; Load the first character of the argument into al
        cmp al, '-'                 ; Check if the argument starts with '-'
        jne .store_value            ; If its not a flag, store the value and move to the next argument

        ; Check for -h flag
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_h             ; Load the address of "-h" into rsi
        call strcmp                 ; Compare the argument with "-h"
        cmp rax, 0                  ; Check if they are equal
        je usage                    ; If equal, show usage message

        ; Check for --help flag
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_help          ; Load the address of "--help" into rsi
        call strcmp                 ; Compare the argument with "--help"
        cmp rax, 0                  ; Check if they are equal
        je usage                    ; If equal, show usage message

        ; Check for -f flag
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_f             ; Load the address of "-f" into rsi
        call strcmp                 ; Compare the argument with "-f"
        cmp rax, 0                  ; Check if they are equal
        je full_table               ; If equal, display the full ASCII table

        ; Check for --full flag
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_full          ; Load the address of "--full" into rsi
        call strcmp                 ; Compare the argument with "--full"
        cmp rax, 0                  ; Check if they are equal
        je full_table               ; If equal, display the full ASCII table

        ; --dec or -d flag check
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_dec            ; Load the address of "--dec" into rsi
        call strcmp                 ; Compare the argument with "--dec"
        cmp rax, 0                  ; Check if they are equal
        jne .check_dec_short        ; If not equal, check for short version
        or byte [flags], FLAG_DEC   ; Set the decimal flag
        jmp .next_arg               ; Move to the next argument

        .check_dec_short:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_d              ; Load the address of "-d" into rsi
        call strcmp                 ; Compare the argument with "-d"
        cmp rax, 0                  ; Check if they are equal
        jne .check_bin              ; If not equal, check for binary flag
        or byte [flags], FLAG_DEC   ; Set the decimal flag
        jmp .next_arg               ; Move to the next argument

        .check_bin:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_bin            ; Load the address of "--bin" into rsi
        call strcmp                 ; Compare the argument with "--bin"
        cmp rax, 0                  ; Check if they are equal
        jne .check_bin_short        ; If not equal, check for short version
        or byte [flags], FLAG_BIN   ; Set the binary flag
        jmp .next_arg               ; Move to the next argument

        .check_bin_short:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_b              ; Load the address of "-b" into rsi
        call strcmp                 ; Compare the argument with "-b"
        cmp rax, 0                  ; Check if they are equal
        jne .check_hex              ; If not equal, check for hexadecimal flag
        or byte [flags], FLAG_BIN   ; Set the binary flag
        jmp .next_arg               ; Move to the next argument

        .check_hex:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_hex           ; Load the address of "--hex" into rsi
        call strcmp                 ; Compare the argument with "--hex"
        cmp rax, 0                  ; Check if they are equal
        jne .check_hex_short        ; If not equal, check for short version
        or byte [flags], FLAG_HEX   ; Set the hexadecimal flag
        jmp .next_arg               ; Move to the next argument

        .check_hex_short:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_x              ; Load the address of "-x" into rsi
        call strcmp                 ; Compare the argument with "-x"
        cmp rax, 0                  ; Check if they are equal
        jne .check_oct              ; If not equal, check for octal flag
        or byte [flags], FLAG_HEX   ; Set the hexadecimal flag
        jmp .next_arg               ; Move to the next argument

        .check_oct:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_oct            ; Load the address of "--oct" into rsi
        call strcmp                 ; Compare the argument with "--oct"
        cmp rax, 0                  ; Check if they are equal
        jne .check_oct_short        ; If not equal, check for short version
        or byte [flags], FLAG_OCT   ; Set the octal flag
        jmp .next_arg               ; Move to the next argument

        .check_oct_short:
        mov rdi, [r14]              ; Load the current argument pointer into rdi
        mov rsi, flag_o              ; Load the address of "-o" into rsi
        call strcmp                 ; Compare the argument with "-o"
        cmp rax, 0                  ; Check if they are equal
        jne .unknown_flag           ; If not equal, it's an unknown flag
        or byte [flags], FLAG_OCT   ; Set the octal flag
        jmp .next_arg               ; Move to the next argument

        ; If none of the known flags matched, it's an unknown flag
        jmp err_unknown_flag        ; Unknown flag, show usage message

        .store_value:
            movzx rbx, byte [value_count]       ; Load current value_count into rbx
            lea rcx, [values + rbx * 8]         ; Calculate the address to store the value pointer
            mov [rcx], rdi                      ; Store the argument pointer (rdi) into values[rbx]
            inc byte [value_count]              ; Increment value_count
            jmp .next_arg                       ; Move to the next argument

        .next_arg:
            add r14, 8                  ; Move to the next argument pointer (argv[i] is 8 bytes apart)
            inc r15                     ; Increment argument index
            jmp .process_args_loop      ; Repeat the loop

        ; All arguments have been processed
        .process_args_done:
            jmp process_values

process_values:
    ; TODO: Implement processing of values based on flags set in [flags]

; Validate and print the first character from argv[i]
; rdi = pointer to the argument string
process_char_arg:
    mov al, [rdi]           ; first character (pointer to rdi)

    ; Check that argv[1] is not empty
    cmp al, 0
    je usage                ; empty string, show usage

    ; Check ASCII range (0..127)
    cmp al, 127
    ja err_out_of_ascii_bounds      ; Error: Out of ASCII Bounds (0..127)

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
    ret

; ----------
; FULL-TABLE
; ----------

full_table:
    xor r12, r12                    ; Counter = 0
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
        jne .table_loop             ; Loop until 128
        jmp .table_done
    .table_done:
        jmp done

; Program Completed. Exit Successfully!
done:
exit EXIT_SUCCESS

; ERROR BRANCHES
; --------------

err_unknown_flag:
    print err_unknown_flag_msg
    print newline
    print usage_msg
    exit EXIT_FAILURE

err_out_of_ascii_bounds:
    print err_out_of_ascii_bounds_msg
    exit EXIT_FAILURE

; USAGE
; -----

; Print the usage message and exit with failure status code
err_usage:
    print usage_msg
    exit EXIT_FAILURE

; Print the usage message and exit
usage:
    print usage_msg
    exit EXIT_SUCCESS

; ------------
; SUB-ROUTINES
; ------------

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

