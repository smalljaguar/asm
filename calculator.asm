format ELF64 executable 3

include 'macros.inc'
include 'linux.inc'
include 'utils.inc'
include 'display.inc'

segment readable executable

include 'str_stuff.inc'

atoi:
    ; ptr to null-terminated buffer given in rdi
    ; returns in rax
    xor rax,rax
    xor rbx,rbx
    ; mov rcx,10
    mov rcx, rdi
    cmp [rdi], byte '-'
    jne .atoi_loop
    inc rdi
    .atoi_loop:
        mov bl,[rdi] ; load char
        ; if newline or null, exit
        cmp bl, 0xA
        jz .atoi_done
        cmp bl,0
        je .atoi_done        
        sub bl,'0'   ; convert char to digit
        cmp bl,9
        ja .atoi_done ; if not a digit, exit
        ; mul rcx
        imul rax,rax,10      ; mul rax by 10
        add rax,rbx
        inc rdi      ; next char
        jmp .atoi_loop
    .atoi_done:
        cmp [rcx], byte '-' ; check for negative
        jne .not_neg
        neg rax
        .not_neg:
        ret
hex_atoi:
    ; ptr to null-terminated buffer given in rdi
    ; returns in rax
    xor rax,rax
    xor rbx,rbx
    mov rcx, rdi
    cmp [rdi], byte '-'
    jne .atoi_loop
    inc rdi
    .atoi_loop:
        mov bl,[rdi] ; load char
        ; if newline or null, exit
        cmp bl, 0xA
        jz .atoi_done
        cmp bl,0
        je .atoi_done        
        sub bl,'0'   ; convert char to digit
        cmp bl,9
        ja .atoi_done ; if not a digit, exit
        ; mul rcx
        imul rax,rax,16      ; mul rax by 10
        add rax,rbx
        inc rdi      ; next char
        jmp .atoi_loop
    .atoi_done:
        cmp [rcx], byte '-' ; check for negative
        jne .not_neg
        neg rax
        .not_neg:
        ret
itoa:
    ; rdi = buffer
    ; rax = value
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
float_itoa:
    ; rdi = buffer
    ; float in st0
    ; rax = decimal places

    ; works by checking nan,inf, then sign
    ; takes integral part and runs itoa
    ; takes fractional part and multiplies by 10^decimal places, 
    ; then convs to int and runs itoa

    push 0 ; so we know when we're done
    ; check for nans
    fld st0
    fcomi st0,st0
    je .nan
    ;check for infs
    ; get sign of float
    fld st0
    fabs
    fcomi st0,st1
    fstp st0
    je .begin
    mov [rdi], byte '-'
    inc rdi
    .begin:
    ; get integer part
    fistp dword [rdi]
    mov eax,[rdi]
    call itoa
    ret
    .nan:
    mov [rdi], dword 'nan'
    add rdi,4
    ret

float_atoi:
    ret



div_zero:
    mov rdi,div_zero_txt
    mov rsi,div_zero_txt_len
    write stdout,rdi,rsi
entry main
main:
    mov rbx, -1 ; opflag
    read_op:
    write stdout,start_txt,start_txt_len
    read stdin,buffer,1000
    imm_cmove [buffer], byte 'm', rbx, 0
    imm_cmove [buffer], byte 'a', rbx, 1
    imm_cmove [buffer], byte 's', rbx, 2
    imm_cmove [buffer], byte 'd', rbx, 3
    cmp rbx , -1
    je read_op
    push rbx ; so itoa doesn't clobber it
    mov rax, rbx
    mov rdi, buffer
    read stdin,buffer,1000
    mov rdi,buffer
    call atoi
    push rax
    read stdin,buffer,1000
    mov rdi,buffer
    call atoi
    mov rcx,rax ; recover second number
    pop rax ; recover first number
    pop rbx ; recover opflag
    cmp rbx,0
    je .mul
    cmp rbx,1
    je .add
    cmp rbx,2
    je .sub
    cmp rbx,3
    je .div
    jmp done
    .mul:
    imul rcx
    jmp done
    .add:
    add rax,rcx
    jmp done
    .sub:
    sub rax,rcx
    jmp done
    .div:
    cmp rcx,0
    je div_zero
    xor rdx,rdx ; clear rdx (top bits of dividend)
    div rcx ; div rax by rcx
    xor rbx,rbx
    ; mov rbx, 0x8000000000000000 ; 2^63, no imm64 so load over rdx
    ; cmp rbx,rdx ; check if tot is negative
    ; jge done
    ; sub rax, rbx
    done:
    mov rdi,buffer
    call itoa ; rax to cstr in buffer
    sub rdi, buffer ; calculate length to prevent printing garbage
	write stdout,buffer,rdi
    jmp main
    exit 0

segment readable writeable
start_txt db "Enter operation (add,multiply,subtract,divide): ",0xa
start_txt_len = $ - start_txt
div_zero_txt db "Cannot divide by zero, try again",0xa
div_zero_txt_len = $ - div_zero_txt
buffer db 1000 dup (?)