
; size optimisations stolen from menuetos
__eregs fix <eax,ebx,ecx,edx,esi,edi,ebp,esp>
__rregs fix <rax,rbx,rcx,rdx,rsi,rdi,rbp,rsp>

macro etor ereg {
    match ereg,eax \{rax\}
    match ereg,ebx \{rbx\}
    match ereg,ecx \{rcx\}
    match ereg,edx \{rdx\}
    match ereg,esi \{rsi\}
    match ereg,edi \{rdi\}
    match ereg,ebp \{rbp\}
    match ereg,esp \{rsp\}
    match ereg,rax \{rax\}
    match ereg,rbx \{rbx\}
    match ereg,rcx \{rcx\}
    match ereg,rdx \{rdx\}
    match ereg,rsi \{rsi\}
    match ereg,rdi \{rdi\}
    match ereg,rbp \{rbp\}
    match ereg,rsp \{rsp\}
}

macro rtoe rreg {
    match rreg,rax \{eax\}
    match rreg,rbx \{ebx\}
    match rreg,rcx \{ecx\}
    match rreg,rdx \{edx\}
    match rreg,rsi \{esi\}
    match rreg,rdi \{edi\}
    match rreg,rbp \{ebp\}
    match rreg,rsp \{esp\}
    match rreg,eax \{eax\}
    match rreg,ebx \{ebx\}
    match rreg,ecx \{ecx\}
    match rreg,edx \{edx\}
    match rreg,esi \{esi\}
    match rreg,edi \{edi\}
    match rreg,ebp \{ebp\}
    match rreg,esp \{esp\}
}

macro add arg1,arg2
    {
    if (arg2 eqtype 0)
        if (arg2) = 1
        inc arg1
        else
        add arg1,arg2
        end if
    else
        add arg1,arg2
    end if
    }
    
macro sub arg1,arg2
    {
    if (arg2 eqtype 0)
        if (arg2) = 1
        dec arg1
        else
        sub arg1,arg2
        end if
    else
        sub arg1,arg2
    end if
    }
    
macro mov arg1,arg2
    {
    ; TODO: convert rregs to eregs automatically
    if arg1 eq arg2 ; remove redundant movs
    else if (arg1 in __rregs) & ((arg2 eqtype 0) | (arg2 eqtype '0'))
        if (arg2) = 0
        xor arg1,arg1
        else if (arg2) = 1
        xor arg1,arg1
        inc arg1
        else if (arg2) = -1
        or  arg1,-1
        else if (arg2) > -128 & (arg2) < 128
        push arg2
        pop  arg1
        else
        mov  arg1,arg2
        end if
    else if (arg1 in __eregs) & ((arg2 eqtype 0) | (arg2 eqtype '0'))
        if (arg2) = 0
        xor arg1,arg1
        else if (arg2) = 1
        xor arg1,arg1
        inc arg1
        else if (arg2) = -1
        or  arg1,-1
        else if (arg2) > -128 & (arg2) < 128
        push arg2
        pop  arg1 ; apply etor here
        else
        mov  arg1,arg2
        end if
    else
        mov arg1,arg2
    end if
    }

macro check_error
{
    if errorcheck eq true
    ; print where we are in the program
    cmp eax,0
    printnum __LINE__, buffer
    write stdout, newline, 1
    jmp fail
    end if
}

macro pusha
{
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    ; push rbp
    ; push r8
    ; push r9
    ; push r10
    ; push r11
    ; push r12
    ; push r13
    ; push r14
    ; push r15
}

macro popa
{
    ; pop r15
    ; pop r14
    ; pop r13
    ; pop r12
    ; pop r11
    ; pop r10
    ; pop r9
    ; pop r8
    ; pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
}
