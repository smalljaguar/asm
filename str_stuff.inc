strlen:
    xor   ecx,ecx; rcx = 0
    dec   rcx    ; rcx = -1 (0xFFFFFFFFFFFFFFFF)
    ; rcx = maximum length to scan
    xor   eax,eax; rax = 0 (al = 0 value to scan for)
    repne scasb      ; scan the memory for AL
    sub   rax,rcx; rax = 0 - rcx_leftover = scanned bytes + 1
    sub   rax,2  ; fix that into "string length" (-1 for '\0')
    ret
strnlen:
    ; rdi = string
    ; rsi = max length
    mov rax,0
    .loop:
        cmp byte [rdi+rax],0
        je .done
        cmp rax,rsi
        je .done

        inc rax
        jmp .loop
    
    .done:
        ret
count_words:
    ; rsi = buf
    ; rdx = buf_len
    ; returns in rax
    ; matches non-space space
    ;TODO


strcmp:
    ; rdi = string 1
    ; rsi = string 2
    ; returns in rax
    mov rax, 1 ; if strings are equal, rax will be 0
    .strcmp_loop:
        mov al,[rdi]
        mov bl,[rsi]
        cmp al,bl
        jne .strcmp_done
        inc rdi
        inc rsi
        cmp al,0
        jne .strcmp_loop
        cmp bl, 0
        jne .strcmp_loop
        xor rax,rax
        jmp .strcmp_done
    .strcmp_done:
        ret

simd_strcmp:
    ; rdi = string 1
    ; rsi = string 2
    ; returns in rax
    mov rax, 1 ; if strings are equal, rax will be 0
    .strcmp_loop:
        movdqu xmm0,[rdi]
        movdqu xmm1,[rsi]
        pcmpeqb xmm0,xmm1
        pmovmskb eax,xmm0
        cmp eax,0xffff
        jne .strcmp_done
        add rdi,16
        add rsi,16
        jmp .strcmp_loop
    .strcmp_done:
        ret


shortstrcpy:
    ; rdi = string
    ; rsi = buffer
    .loop:
        mov al,[rdi]
        mov [rsi],al
        inc rdi
        inc rsi
        cmp al,0
        jne .loop
        ret
strcpy:
    ; uses str instructions
    ; rdi = string
    ; rsi = buffer
    .loop:
        movsb
        cmp byte [rdi-1],0
        jne .loop
        ret

zerobuf:
    ; rdi = buffer
    ; rax = length
    cmp [rdi],0
    je .done
    cmp rax,0
    je .done
    .loop:        
        mov byte [rdi],0
        inc rdi
        dec rax
        jne .done
    .done:
        ret