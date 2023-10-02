macro printnum num,buf
{
    ; clobbers rax,rdi,overwrites buf
    inc r10
    mov rdi,buf
    mov rax,num
    call itoa
    sub rdi,buf
    dec rdi
    write stdout,buf,rdi
}

macro filesize fd
{
    ; returns in rax
    ; statbuf in buffer
    ; stat.st_size = 48
    ; sizeof_stat = 144
    fstat fd,statbuf
    mov eax,[statsize] ; st_size
}

macro filesize32 fd
{
    ; returns in eax
    ; statbuf in buffer
    ; stat.st_size = 48
    ; sizeof_stat = 144
    fstat32 fd,statbuf
    mov eax,[statsize] ; st_size
}

macro imm_cmove cmp_a,cmp_b,reg,val
{
    local skip
    cmp cmp_a, cmp_b
    jne skip
    mov reg, val
    label skip
}