; ----------------
; STRING UTILITIES
; ----------------

section .text

; strcmp: Compares two null-terminated strings
; C-like convention
; Input:
;   rdi: pointer to the first string
;   rsi: pointer to the second string
;
; Output:
;   rax: 0 if the strings are equal, 1 otherwise
global strcmp
strcmp:
    .loop:
        mov al, [rdi]           ; Load byte from first string
        mov bl, [rsi]           ; Load byte from second string

        cmp al, bl              ; Compare bytes
        jne .ret_not_equal      ; If not equal, strings are different

        cmp al, 0               ; Check for null terminator
        je .ret_equal           ; If null terminator, strings are equal

        inc rdi                 ; Move to next character in first string
        inc rsi                 ; Move to next character in second string
        jmp .loop               ; Repeat the loop

    .ret_not_equal:
        mov rax, 1
        ret

    .ret_equal:
        mov rax, 0
        ret
