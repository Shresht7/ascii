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

FLAG_DEC equ 1                  ; 0000 0001 - Print decimal representation
FLAG_BIN equ 2                  ; 0000 0010 - Print binary representation
FLAG_HEX equ 4                  ; 0000 0100 - Print hexadecimal representation
FLAG_OCT equ 8                  ; 0000 1000 - Print octal representation
FLAG_CHAR equ 16                ; 0001 0000 - Print character glyph
FLAG_LOOKUP equ 32              ; 0010 0000 - Interpret values as numeric codes
FLAG_OUTPUT_MASK equ FLAG_DEC | FLAG_BIN | FLAG_HEX | FLAG_OCT | FLAG_CHAR

section .data

    ; USAGE
    ; -----

    usage_msg db "Usage: ascii <value> [value ...] | [flag]", 0xA, 0xA
              db "Display ASCII information for one or more values.", 0xA, 0xA
              db "Values can be:", 0xA
              db "  Characters:        A   Hello   (each character is processed individually)", 0xA
              db "  Numeric (--lookup): 65   0x41   0o101   0b1000001", 0xA, 0xA
              db "Flags:", 0xA
              db "  -f, --full        Display the full ASCII table.", 0xA
              db "  -h, --help        Display this help message.", 0xA
              db "  -d, --dec         Show decimal representation", 0xA
              db "  -x, --hex         Show hexadecimal representation", 0xA
              db "  -o, --oct         Show octal representation", 0xA
              db "  -b, --bin         Show binary representation", 0xA
              db "  -c, --char        Show character glyph", 0xA
              db "  -l, --lookup      Treat values as numeric codes", 0xA, 0xA
              db "Examples:", 0xA
              db "  ascii A               Show all representations of 'A'", 0xA
              db "  ascii Hello           Process each character in 'Hello'", 0xA
              db "  ascii A B --hex       Show hex only for 'A' and 'B'", 0xA
              db "  ascii --lookup 65     Look up decimal code 65", 0xA
              db "  ascii -l 0x41 --char  Look up hex 0x41, show glyph only", 0xA
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

    flag_lookup db "--lookup", 0
    flag_l db "-l", 0
    flag_char db "--char", 0
    flag_c db "-c", 0

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

    err_invalid_lookup_msg db "Error: Invalid numeric code. Expected a valid decimal, hex (0x), octal (0o), or binary (0b) number", 0xA
    err_invalid_lookup_msg_len equ $ - err_invalid_lookup_msg

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
        mov rsi, flag_o             ; Load the address of "-o" into rsi
        call strcmp                 ; Compare the argument with "-o"
        cmp rax, 0                  ; Check if they are equal
        jne .check_lookup           ; If not equal, check for lookup flag
        or byte [flags], FLAG_OCT   ; Set the octal flag
        jmp .next_arg               ; Move to the next argument

        .check_lookup:
        mov rdi, [r14]                  ; Load the current argument pointer into rdi
        mov rsi, flag_lookup            ; Load the address of "--lookup" into rsi
        call strcmp                     ; Compare the argument with "--lookup"
        cmp rax, 0                      ; Check if they are equal
        jne .check_lookup_short         ; If not equal, check for short version
        or byte [flags], FLAG_LOOKUP    ; Set the lookup flag
        jmp .next_arg                   ; Move to the next argument

        .check_lookup_short:
        mov rdi, [r14]                  ; Load the current argument pointer into rdi
        mov rsi, flag_l                 ; Load the address of "-l" into rsi
        call strcmp                     ; Compare the argument with "-l"
        cmp rax, 0                      ; Check if they are equal
        jne .check_char                 ; If not equal, check for char flag
        or byte [flags], FLAG_LOOKUP    ; Set the lookup flag
        jmp .next_arg

        .check_char:
        mov rdi, [r14]                  ; Load the current argument pointer into rdi
        mov rsi, flag_char              ; Load the address of "--char" into rsi
        call strcmp                     ; Compare the argument with "--char"
        cmp rax, 0                      ; Check if they are equal
        jne .check_char_short           ; If not equal, check for short version
        or byte [flags], FLAG_CHAR      ; Set the char flag
        jmp .next_arg                   ; Move to the next argument

        .check_char_short:
        mov rdi, [r14]                  ; Load the current argument pointer into rdi
        mov rsi, flag_c                 ; Load the address of "-c" into rsi
        call strcmp                     ; Compare the argument with "-c"
        cmp rax, 0                      ; Check if they are equal
        jne err_unknown_flag            ; If not equal, it's an unknown flag
        or byte [flags], FLAG_CHAR      ; Set the char flag
        jmp .next_arg                   ; Move to the next argument

        ; If none of the known flags matched, it's an unknown flag
        jmp err_unknown_flag

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
    movzx r15, byte [value_count]       ; Load value_count into r15
    cmp r15, 0                          ; Check if there are any values to process
    je done                             ; If no values, exit successfully

    lea r14, [values]                   ; Load the address of the values array into r14
    xor r13, r13                         ; Initialize index to 0

    .value_loop:
        cmp r13, r15                     ; Compare index with value_count
        je done                          ; If index equals value_count, all values have been processed

        mov rdi, [r14 + r13 * 8]         ; Load the argument pointer (values[r13]) into rdi
        test byte [flags], FLAG_LOOKUP   ; Check if lookup mode is enabled
        jnz .do_lookup                   ; If lookup mode, call process_lookup
        call process_string              ; Otherwise, process the entire string
        jmp .next_value

        .do_lookup:
        call process_lookup              ; Process as numeric code

        .next_value:
        inc r13                          ; Increment index
        jmp .value_loop                  ; Repeat the loop

; Process a null-terminated string, printing representations for each character
; rdi = pointer to the string
process_string:
    push r14
    mov r14, rdi                    ; r14 = string pointer (preserved for multiple passes)

    cmp byte [flags], 0
    jne .ps_flags

    ; No flags: one line per character with all four representations
.ps_default:
    mov al, [r14]
    cmp al, 0
    je .ps_done
    cmp al, 127
    ja err_out_of_ascii_bounds
    movzx r12, al
    call print_char
    repr ten, 10
    print separator
    repr hex, 16
    print separator
    repr oct, 8
    print separator
    repr bin, 2
    print newline
    inc r14
    jmp .ps_default

    ; Flags set: one line per set flag
.ps_flags:
    test byte [flags], FLAG_DEC
    jz .psf_hex
    call .ps_line_dec

.psf_hex:
    test byte [flags], FLAG_HEX
    jz .psf_oct
    call .ps_line_hex

.psf_oct:
    test byte [flags], FLAG_OCT
    jz .psf_bin
    call .ps_line_oct

.psf_bin:
    test byte [flags], FLAG_BIN
    jz .psf_done
    call .ps_line_bin

.psf_done:
.ps_done:
    pop r14
    ret

; Macro to define a per-flag line printer
; %1 = short name (dec, hex, oct, bin)
; %2 = repr prefix (ten, hex, oct, bin)
; %3 = base (10, 16, 8, 2)
%macro def_ps_line 3
.ps_line_%1:
    push r14
    xor r15, r15
%%loop:
    mov al, [r14]
    cmp al, 0
    je %%done
    cmp al, 127
    ja err_out_of_ascii_bounds
    movzx r12, al
    cmp r15, 0
    je %%no_sep
    print separator
%%no_sep:
    repr %2, %3
    inc r15
    inc r14                 ; advance to next character
    jmp %%loop
%%done:
    pop r14
    print newline
    ret
%endmacro

def_ps_line dec, ten, 10
def_ps_line hex, hex, 16
def_ps_line oct, oct, 8
def_ps_line bin, bin, 2

; -----------
; LOOKUP MODE
; -----------

; Treats each value as a numeric code and prints the matching ASCII character.
; Supports decimal (default), hex (0xNN), octal (0oNN), and binary (0bNN) formats.
process_lookup:
    push r14                        ; Save r14 for later restoration
    mov r14, rdi                    ; r14 = pointer to the argument string

    ; Determine base from prefix
    mov al, [r14]                   ; Check first character of the string
    cmp al, '0'                     ; If first character is '0', check for known prefixes
    jne .parse_dec                  ; If not '0', treat as decimal

    mov al, [r14 + 1]               ; Check second character for known prefixes
    cmp al, 'x'                     ; If second character is 'x', it's hex
    je .parse_hex                   ; Jump to hex parsing
    cmp al, 'o'                     ; If second character is 'o', it's octal
    je .parse_oct                   ; Jump to octal parsing
    cmp al, 'b'                     ; If second character is 'b', it's binary
    je .parse_bin                   ; Jump to binary parsing

    ; No known prefix after '0' — treat as decimal (e.g. "065")
    jmp .parse_dec

.parse_dec:
    xor r12, r12                    ; Clear r12 to accumulate the decimal value
    .dec_loop:
        mov al, [r14]               ; Load the current character
        cmp al, 0                   ; Check for null terminator
        je .validate                ; If null terminator, validate the accumulated value
        cmp al, '0'                 ; Check if character is a valid decimal digit
        jb err_invalid_lookup       ; If less than '0', invalid
        cmp al, '9'                 ; Check if character is a valid decimal digit
        ja err_invalid_lookup       ; If greater than '9', invalid
        sub al, '0'                 ; Convert ASCII digit to numeric value
        movzx rax, al               ; Multiply the current accumulated value by 10 and add the new digit
        imul r12, 10                ; Multiply r12 by 10
        add r12, rax                ; Add the new digit to r12
        inc r14                     ; Advance to the next character
        jmp .dec_loop               ; Repeat the loop for the next character

.parse_hex:
    add r14, 2                      ; Skip the "0x" prefix
    xor r12, r12                    ; Clear r12 to accumulate the hexadecimal value
    .hex_loop:
        mov al, [r14]               ; Load the current character
        cmp al, 0                   ; Check for null terminator
        je .validate                ; If null terminator, validate the accumulated value
        cmp al, '0'                 ; Check if character is a valid hex digit
        jb err_invalid_lookup       ; If less than '0', invalid
        cmp al, '9'                 ; Check if the character is a digit
        jle .hex_digit              ; If less/equal to '9', it's a valid digit
        or al, 0x20                 ; lowercase
        cmp al, 'a'                 ; Check if character is a valid hex letter
        jb err_invalid_lookup       ; If less than 'a', invalid (between '9' and 'a')
        cmp al, 'f'                 ; Check if character is a valid hex letter
        ja err_invalid_lookup       ; If greater than 'f', invalid
        sub al, 'a' - 10            ; Convert ASCII letter to numeric value (A=10, B=11, ..., F=15)
        jmp .hex_add
    .hex_digit:
        sub al, '0'                 ; Convert ASCII digit to numeric value
    .hex_add:
        shl r12, 4                  ; Shift the accumulated value left by 4 bits (multiply by 16)
        movzx rax, al               ; Move the numeric value of the current character into rax
        add r12, rax                ; Add the current digit to the accumulated value
        inc r14                     ; Advance to the next character
        jmp .hex_loop               ; Repeat the loop for the next character

.parse_oct:
    add r14, 2                      ; Skip the "0o" prefix
    xor r12, r12                    ; Clear r12 to accumulate the octal value
    .oct_loop:
        mov al, [r14]               ; Load the current character
        cmp al, 0                   ; Check for null terminator
        je .validate                ; If null terminator, validate the accumulated value
        cmp al, '0'                 ; Check if character is a valid octal digit
        jb err_invalid_lookup       ; If less than '0', invalid
        cmp al, '7'                 ; Check if character is a valid octal digit
        ja err_invalid_lookup       ; If greater than '7', invalid
        sub al, '0'                 ; Convert ASCII digit to numeric value
        movzx rax, al               ; Move the numeric value of the current character into rax
        shl r12, 3                  ; Shift the accumulated value left by 3 bits (multiply by 8)
        add r12, rax                ; Add the current digit to the accumulated value
        inc r14                     ; Advance to the next character
        jmp .oct_loop               ; Repeat the loop for the next character

.parse_bin:
    add r14, 2                      ; Skip the "0b" prefix
    xor r12, r12                    ; Clear r12 to accumulate the binary value
    .bin_loop:
        mov al, [r14]               ; Load the current character
        cmp al, 0                   ; Check for null terminator
        je .validate                ; If null terminator, validate the accumulated value
        cmp al, '0'                 ; Check if character is a valid binary digit
        jb err_invalid_lookup       ; If less than '0', invalid
        cmp al, '1'                 ; Check if character is a valid binary digit
        ja err_invalid_lookup       ; If greater than '1', invalid
        sub al, '0'                 ; Convert ASCII digit to numeric value
        movzx rax, al               ; Move the numeric value of the current character into rax
        shl r12, 1                  ; Shift the accumulated value left by 1 bit (multiply by 2)
        add r12, rax                ; Add the current digit to the accumulated value
        inc r14                     ; Advance to the next character
        jmp .bin_loop               ; Repeat the loop for the next character

.validate:
    cmp r12, 127                    ; Check if the accumulated value is greater than 127
    ja err_out_of_ascii_bounds      ; If greater than 127, it's out of bounds for ASCII. Show error message and exit

    ; Determine output format
    test byte [flags], FLAG_OUTPUT_MASK     ; Check if any output flags are set
    jnz .pl_selected                        ; If any output flags are set, jump to the selected output printing routine

    ; No output flags: print glyph + all four representations (like full table)
    mov rdi, r12
    call print_char
    repr ten, 10
    print separator
    repr hex, 16
    print separator
    repr oct, 8
    print separator
    repr bin, 2
    print newline
    pop r14
    ret

.pl_selected:
    test byte [flags], FLAG_CHAR            ; Check if the character glyph flag is set
    jz .pl_dec                              ; If not set, jump to decimal representation printing
    mov rdi, r12                            ; Move the ASCII value to rdi for printing
    call print_char                         ; Print the character glyph
    print newline                           ; Print a newline after the character glyph

.pl_dec:
    test byte [flags], FLAG_DEC             ; Check if the decimal representation flag is set
    jz .pl_hex                              ; If not set, jump to hexadecimal representation printing
    repr ten, 10                            ; Print the decimal representation
    print newline                           ; Print a newline after the decimal representation

.pl_hex:
    test byte [flags], FLAG_HEX             ; Check if the hexadecimal representation flag is set
    jz .pl_oct                              ; If not set, jump to octal representation printing
    repr hex, 16                            ; Print the hexadecimal representation
    print newline                           ; Print a newline after the hexadecimal representation

.pl_oct:
    test byte [flags], FLAG_OCT             ; Check if the octal representation flag is set
    jz .pl_bin                              ; If not set, jump to binary representation printing
    repr oct, 8                             ; Print the octal representation
    print newline                           ; Print a newline after the octal representation

.pl_bin:
    test byte [flags], FLAG_BIN             ; Check if the binary representation flag is set
    jz .pl_done                             ; If not set, jump to done
    repr bin, 2                             ; Print the binary representation
    print newline                           ; Print a newline after the binary representation

.pl_done:
    pop r14             ; Restore r14
    ret                 ; Return from process_lookup

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

err_invalid_lookup:
    print err_invalid_lookup_msg
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

