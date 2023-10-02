stdin equ 0
stdout equ 1
stderr equ 2
O_RDONLY = 0
O_WRONLY = 1
O_CREAT = 64
O_TRUNC = 512

macro write fd,buf,len
{
    ; returns number of bytes written in rax
    push len
    mov rdx,len
    mov rsi,buf
    mov rdi,fd
    mov rax,1
    syscall
    pop rbx
    cmp rax,rbx
    jne main.exit
}

macro write32 fd,buf,len
{
    ; returns number of bytes written in rax
    mov edx,len
    mov esi,buf
    mov edi,fd
    mov eax,1
    syscall
    check_error
}

macro read fd,buf,len
{
    ; read from fd into buf, len bytes
    ; returns number of bytes read in rax
    mov rdi,fd
    mov rsi,buf
    mov rdx,len
    mov rax,0
    syscall
    check_error
}

macro read32 fd,buf,len
{
    ; read from fd into buf, len bytes
    ; returns number of bytes read in rax
    mov edi,fd
    mov esi,buf
    mov edx,len
    mov eax,0
    syscall
    check_error
}
macro mmap addr,len,prot,flags,fd,offset
{
    ; returns address of mapped memory in rax
    mov rdi,addr
    mov rsi,len
    mov rdx,prot
    mov r10,flags
    mov r8,fd
    mov r9,offset
    mov rax,9
    syscall
    check_error
}
macro x86mmap addr,len,prot,flags,fd,offset
{
    ; returns address of mapped memory in eax
    mov ebx,addr
    mov ecx,len
    mov edx,prot
    mov esi,flags
    mov edi,fd
    mov ebp,offset
    mov eax,90
    int 0x80
    check_error
}
macro brk pos
{
    ; clobbers rdi, rax
    ; using brk
    mov rdi,pos
    mov rax,12
    syscall
    check_error
}

macro brk32 pos
{
    ; clobbers edi, eax
    ; using brk
    mov edi,pos
    mov rax,12
    syscall
    check_error
}

macro alloc size
{
    ; shave 13 bytes using 32 bit registers
    brk 0 ; get brk address in rax
    mov rsi, rax ; return brk address in rbx    
    add rax,size
    brk rax
}

macro sendfile out_fd,in_fd,offset,count
{
    ; returns number of bytes sent in rax
    mov rsi,in_fd
    mov rdi,out_fd
    mov r10,count
    mov rdx,offset
    mov rax,40
    syscall
    check_error
}

macro sendfile32 out_fd,in_fd,offset,count
{
    ; returns number of bytes sent in rax
    mov ebx, out_fd     ; destination file descriptor
    mov ecx, in_fd      ; source file descriptor
    mov esi, count       ; number of bytes to transfer
    mov edx, offset      ; file offset
    mov rax, 187         ; syscall number for sendfile
    int 0x80
    check_error
}

macro no_ebx_sendfile32 in_fd,offset,count
{
    ; returns number of bytes sent in rax
    mov ecx, in_fd      ; source file descriptor
    mov esi, count       ; number of bytes to transfer
    mov edx, offset      ; file offset
    mov rax, 187         ; syscall number for sendfile
    int 0x80
    check_error
}

aslr equ true
macro alloc32 size
{
    ; shave 13 bytes using 32 bit registers
    if aslr eq true 
    ; to disable aslr run:
    ; echo 1 | sudo tee /proc/sys/kernel/randomize_va_space
    brk32 0 ; get brk address in rax
    mov esi, eax ; return brk address in rbx
    else    
    mov esi, brk_end ; return brk address in rbx    
    end if
    add eax,size
    brk32 eax
}

macro time ptr
{
    ; returns time in rax
    ; if ptr is not null, time is stored in ptr
    mov rax,201
    mov rdi, ptr
    syscall
    check_error
}

macro open32 path,flags,mode
{
    mov rdi,path ; path requires 49 bits so uses 64 bit reg
    mov esi,flags
    mov edx,mode ; used only when file is created, otherwise ignored
    mov rax,2
    syscall
    check_error
    ; returns fd in rax
}

macro no_edx_open32 path,flags
{
    mov rdi,path ; path requires 49 bits so uses 64 bit reg
    mov esi,flags
    mov rax,2
    syscall
    check_error
    ; returns fd in rax
}


macro open path,flags,mode
{
    mov rdi,path
    mov rsi,flags
    mov rdx,mode ; used only when file is created, otherwise ignored
    mov rax,2
    syscall
    check_error
    ; returns fd in rax
}

macro close fd
{
    mov rdi,fd
    mov rax,3
    syscall
    check_error
}

macro close32 fd
{
    mov edi,fd
    mov rax,3
    syscall
    check_error
}

macro stat path,buf
{
    mov rdi,path
    mov rsi,buf
    mov rax,4
    syscall
    check_error
}

macro getdents fd,buf,count 
{
; gets entries in directory, can be used for recursive
    mov rdi,fd
    mov rsi,buf ; contains ptr to dirent
    mov rdx,count
    mov rax,78
    syscall
    check_error
}

macro fstat fd,buf
{
    mov rdi,fd
    mov rsi,buf
    mov rax,5
    syscall
    check_error
}

macro fstat32 fd,buf
{
    mov edi,fd
    mov esi,buf
    mov rax,5
    syscall
    check_error
}

macro x86fstat fd,buf
{
    mov ebx,fd
    mov ecx,buf
    mov eax,108
    int 0x80
    check_error
}

macro lseek fd,offset,whence
{
    mov rdi,fd
    mov rsi,offset
    mov rdx,whence
    mov rax,8
    syscall
    check_error
}

macro lseek32 fd,offset,whence
{
    mov edi,fd
    mov esi,offset
    mov edx,whence
    mov rax,8
    syscall
    check_error
} 

macro exit code
{
    mov rdi,code
    mov rax,60
    syscall
    check_error
}

macro exit32 code
{
    mov edi,code
    mov eax,60
    syscall
    check_error
}

macro unsafe_exit
{
    int3
}
macro segfault_exit
{
}