format ELF64 executable 3
; next shave is shrinking header
include 'macros.inc'
include 'linux.inc'
include 'utils.inc'
include 'display.inc'

errorcheck equ false
segment readable executable

; strlen:
;     ; rdi = string
;     ; rax = length
;     mov rax,0
;     .loop:
;         cmp byte [rdi+rax],0
;         je .done
;         inc rax
;         jmp .loop
;     .done:
;         ret
; count_words:
;     ; rdi = fd
;     ; returns in rax

; strcpy:
;     ; rdi = string
;     ; rsi = buffer
;     .loop:
;         mov al,[rdi]
;         mov [rsi],al
;         inc rdi
;         inc rsi
;         cmp al,0
;         jne .loop
;         ret

; zerobuf:
;     ; rdi = buffer
;     ; rax = length
;     .loop:
;         cmp rax,0
;         je .done
;         mov byte [rdi],0
;         inc rdi
;         dec rax
;         jmp .loop
;     .done:
;         ret
if errorcheck eq true
itoa:
    ; rdi = buffer
    ; rax = value
    ; rcx,rdx,rax are clobbered
    ; returns in rdi
    mov rcx,10
    push 0 ; so we know when we're done
    ; check sign of rax
    cmp rax,0
    jge .loop
    neg rax
    mov [rdi], byte '-'
    inc rdi
    .loop:
        xor rdx,rdx
        div rcx
        add dl,'0'
        push rdx
        ; mov [rdi],dl
        test rax,rax
        jnz .loop
        ; reverse the chars on stack
    .itoa_reverse:
        pop rdx
        cmp dl,0
        je .itoa_done
        mov [rdi],dl
        inc rdi
        jmp .itoa_reverse
    .itoa_done:
        mov [rdi], byte 0xa
        inc rdi
        mov [rdi], byte 0
        ret
end if
; hex_itoa:
;     push 0 ; so we know when we're done
;     cmp rax,0
;     jge .itoa_begin
;     neg rax
;     mov [rdi], byte '-'
;     inc rdi
;     .itoa_begin:
;     mov [rdi], word '0x'
;     add rdi,2
;     .loop:
;         mov rdx,rax
;         and rdx,0xf
;         cmp rdx,9
;         jle .hex_itoa_num
;         add rdx,'a'-10
;         jmp .hex_itoa_write
;         .hex_itoa_num:
;         add rdx,'0'
;         .hex_itoa_write:
;         push rdx
;         shr rax,4 
;         test rax,rax
;         jnz .loop
;         ; reverse the chars on stack
;     .itoa_reverse:
;         pop rdx
;         cmp dl,0
;         je .itoa_done
;         mov [rdi],dl
;         inc rdi
;         jmp .itoa_reverse
;     .itoa_done:
;         mov [rdi], byte 0xa
;         inc rdi
;         mov [rdi], byte 0
;         ret
dynamicalloc equ false
dealloc equ false
send_file equ true
; down to 48 bytes of instructions
entry main
main:
disp 'start address is ',<main,16>
    ; get args of stack and write to stdout
    pop rcx 
    ; save 3 bytes using ecx instead of r9 without push pop
    ;4 bytes for ecx not rcx
    dec ecx; remove filename
    if send_file eq true
        inc ebx ; set outfd stdout
    end if
    if errorcheck eq true
        cmp ecx,0
        jz .no_args ; send stdin to stdout
    end if

    pop rdi ; discard exename

    .loop:
        pop rdi ; get filename
        push rcx ; save loop counter
        if send_file eq true
        no_edx_open32 rdi, O_RDONLY ; use edi to shave 3 bytes
        ; registers are zeroed at start so may not have to xor them
        else
        open32 rdi, O_RDONLY, 0 ; use edi to shave 3 bytes
        end if
        mov edi,eax
        fstat32 edi,statbuf ; edi is not modified
        if send_file eq true
            mov esi,[statsize] ; save filesize in edx
        else if
            mov edx,[statsize] ; save filesize in edx
        end if
        ; pusha
        ;     printnum rax,buffer ; print filesize for debugging
        ;     write stdout,bytecnt_mesg,bytecnt_len
        ; popa
        if send_file eq true
            ; sendfile stdout,rdi,0,rdx
            no_ebx_sendfile32 edi,0,esi
        else if dynamicalloc eq true
            push rdi ; save fd
            alloc32 edx ; allocate buffer (clobbers rax,rdi)
            ; ASLR randomises the brk memory, so we get address in rbx at runtime
            pop rdi ; restore fd after alloc
            read32 edi,esi,edx
            close32 edi ; close file
            write32 stdout,esi,edx
            if dealloc eq true
                brk32 esi ; free buffer by shrinking down to initial size
            end if
        else
            read32 edi,brk_buf,edx
            close32 edi ; close file
            write32 stdout,brk_buf,edx
        end if
        
        pop rcx ; restore loop counter
        loop .loop ; shave 5 bytes, slightly slower
    ; read file
    
    
    .no_args:
        segfault_exit
    if errorcheck eq true
        fail:
        write stdout,error_msg,error_len
        printnum rax,buffer
        write stdout,newline,1
        exit rax ; exit with error code
    end if

segment readable writeable
if errorcheck eq true

    newline db 0xa
    colon db ":"
    bytecnt_mesg db " bytes",0xa
    bytecnt_len = $ - bytecnt_mesg

    error_msg db "error code:"
    error_len = $ - error_msg

end if
buffer db 1000 dup (?)
statsize = $ + 48
statbuf db 200 dup (?)
if dynamicalloc eq false
    brk_buf db 1000000 dup (?)
end if
brk_end:
; d for define, r for reserve
; b for byte, w for word, d for doubleword, q for quadword
