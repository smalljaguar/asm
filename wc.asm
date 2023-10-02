format ELF64 executable 3

include 'macros.inc'
include 'linux.inc'
include 'utils.inc'

segment readable executable

strlen:
    ; rdi = string
    ; rax = length
    mov rax,0
    .loop:
        cmp byte [rdi+rax],0
        je .done
        inc rax
        jmp .loop
    .done:
        ret
count_words:
    ; rdi = fd
    ; returns in rax

strcpy:
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

zerobuf:
    ; rdi = buffer
    ; rax = length
    .loop:
        cmp rax,0
        je .done
        mov byte [rdi],0
        inc rdi
        dec rax
        jmp .loop
    .done:
        ret

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
        
hex_itoa:
    push 0 ; so we know when we're done
    cmp rax,0
    jge .itoa_begin
    neg rax
    mov [rdi], byte '-'
    inc rdi
    .itoa_begin:
    mov [rdi], word '0x'
    add rdi,2
    .loop:
        mov rdx,rax
        and rdx,0xf
        cmp rdx,9
        jle .hex_itoa_num
        add rdx,'a'-10
        jmp .hex_itoa_write
        .hex_itoa_num:
        add rdx,'0'
        .hex_itoa_write:
        push rdx
        shr rax,4 
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

entry main
main:
    ; get args of stack and write to stdout
    pop rbx
    cmp    rbx,0
    add rbx,0
    jz .no_args ; is this even possible?                             
        .loop:
        pop rdi
        pusha
        mov rax,rdi
        mov rdi, buffer
        call itoa
        sub rdi, buffer
        dec rdi ; remove newline
        write  stdout,buffer,rdi
        write  stdout,colon,1
        popa
        cmp rdi,255
        jl .loop ; don't dereference zero page
        call strlen
        write  stdout,rdi,rax
        write  stdout,newline,1
        dec rbx
        cmp rbx,0
        jnz .loop
    ; read file
    open filename, O_RDONLY, 0
    cmp rax,0
    jl .fail
    mov rdi,rax
    push rdi ; save fd
    filesize rdi ; rdi is not modified
    push rax ; save filesize
    lseek rdi,0,0 ; seek to beginning
    ; printnum rax,buffer
    ; write stdout,newline,1
    pop rax ; restore filesize
    pop rdi ; restore fd (broken?)
    mov rdx,rax ; save filesize in rdx
    alloc rax ; allocate buffer
    read 3,brk_addr,rdx
    write stdout,brk_addr,rdx
    .no_args:
    exit 0
    .fail:
    exit rax ; exit with error code


segment readable writeable
newline db 0xa
colon db ":"
help db "usage: wc [OPTION].. [FILE]...",0xa
     db "With no FILE, or when FILE is -, read standard input.",0xa
     db "options:-c, --bytes            print the byte counts",0xa
     db "        -m, --chars            print the character counts",0xa
     db "        -l, --lines            print the newline counts",0xa
     db "        -w, --words            print the word counts",0xa
     db "        -h, --help             display this help and exit",0xa
filename db "fasm/fasm.txt",0
help_len = $ - help
buffer db 1000 dup (?)
statsize = $ + 48
statbuf db 200 dup (?)
brk_addr rb $