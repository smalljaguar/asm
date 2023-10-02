format ELF64 executable 3
include 'macros.inc'
include 'linux.inc'
include 'utils.inc'
include 'display.inc'
; TODO: Fix /dev/* files (pipes) by checking with fstat before getting len,
; and using stream io
errorcheck equ false
segment readable executable

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
send_file equ false
; down to 48 bytes of instructions
entry main
main:
disp 'start address is ',<main,16>
    ; get args of stack and write to stdout
    pop rcx
    ; save 3 bytes using ecx instead of r9 without push pop
    ;4 bytes for ecx not rcx
    dec ecx; remove filename
    jnz .args ; send stdin to stdout if no args, otherwise loop through args
    .read_stdin:
    read stdin,buffer,1024
    write stdout,buffer,rax
    pop rcx
    dec rcx
    jnz .loop
    jmp .exit 
    .args:
    pop rdi ; discard exename
    .loop:
        pop rdi ; get filename
        cmp byte [rdi], '-' ; check if flag
        jne .open_file
            cmp dword [rdi], '--he'
            jne .n_help
            write stdout,help_msg,help_len    
            jmp .exit
        .n_help:
            cmp dword [rdi], '--ve'
            jne .n_version
            write stdout,version_msg,version_len
            jmp .exit
        .n_version:
            cmp byte [rdi+1], 0
            push rcx ; save loop counter
            je .read_stdin
        .open_file:
        push rcx ; save loop counter
        open32 rdi, O_RDONLY, 0 ; use edi to shave 3 bytes
        mov edi,eax
        fstat32 edi,statbuf ; edi is not modified
        mov edx,[statsize] ; save filesize in edx
        ; pusha
        ;     printnum rax,buffer ; print filesize for debugging
        ;     write stdout,bytecnt_mesg,bytecnt_len
        ; popa
        if dynamicalloc eq true
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
        dec rcx
        jnz .loop
    ; read file
    
    
    .exit:
        exit 0
    if errorcheck eq true
        fail:
        write stdout,error_msg,error_len
        printnum rax,buffer
        write stdout,newline,1
        exit rax ; exit with error code
    end if

segment readable writeable

newline db 0xa
colon db ":"
help_msg db "usage: cat [file ...]",0xa
help_len = $ - help_msg
version_msg db "mycat version 0.1",0xa
version_len = $ - version_msg
bytecnt_mesg db " bytes",0xa
bytecnt_len = $ - bytecnt_mesg

error_msg db "error code:"
error_len = $ - error_msg

buffer db 1024 dup 32
statsize = $ + 48
statbuf db 200 dup (?)
if dynamicalloc eq false
    brk_buf db 1000000 dup (?)
end if
brk_end:
; d for define, r for reserve
; b for byte, w for word, d for doubleword, q for quadword
