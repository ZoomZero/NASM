
global main

section .rodata
  ;inpfmt: db '%d', 0x0 ; строки стандартной библиотеки libc оканчиваются на 0
  ;outfmt: db '%d', 0xa, 0x0 ; будем переводить строку каждый раз
  try_number_format db '%f', 0
  try_string_format db '%s', 0
  outfmt: db 'result = %.5f', 0xa, 0x0 ; будем переводить строку каждый раз
  s_err db 'Scan error!' ;, 0xa
  len1 equ $-s_err
  o_err db 'Wrong operator or function!' ;, 0xa
  len2 equ $-o_err
  func db 'f'

section .bss
  result: resq 1
  samples: resq 1
  operation: resb 256

section .text
  extern scanf
  extern printf
main:
    finit
    push rbp
    mov rbp, rsp
.try_number:
    mov rdi, try_number_format
    mov rsi, samples
    call scanf
    test eax, eax ; проверяем результат scanf
    jnz .this_is_number ; если не 0 -- то прочитано число
    mov rdi, try_string_format
    mov rsi, operation
    call scanf
    test eax, eax ; проверям результат scanf
    jnz .this_is_operation ; если не 0 -- то прочитана строка
    jmp .scan_error
.this_is_number:
    ; обработка, если число
    fld DWORD [samples]
    jmp .try_number
.this_is_operation:
    ; обработка если операция
    ;mov cl
    ;mov BYTE [rsi+rax], 0
    mov rax, 0x0
    mov rsi, operation
  .cycle:
    mov cl, [rsi] ; читаем байт из строки
    cmp cl, 'a'
    jae .check_alpha
    cmp cl, '/'
    je .op_div
    cmp cl, '*'
    je .op_mul
    ;cmp cl, '+'
    ;je .op_sum
    ;cmp cl, '-'
    ;je .op_sub
    cmp cl, '='
    je .print_res
    jmp .func_qualifier
  .check_alpha: ; проверяем попадание в диап. 'a'-'z'
  	; прибавляем смещение
  	add rax, rcx
  	inc rsi
  	jmp .cycle
  .func_qualifier:
    cmp rax, 330
    je .f_sin
    cmp rax, 325
    je .f_cos
    cmp rax, 452
    je .op_sum
    cmp rax, 556
    je .op_sub
    jmp .op_error
  .f_sin:
    fsin
    jmp .try_number
  .f_cos:
    fcos
    jmp .try_number
  .op_sum:
    faddp st1
    jmp .try_number
  .op_sub:
    fsubp st1
    jmp .try_number
  .op_div:
    fdivp st1
    jmp .try_number
  .op_mul:
    fmulp st1
    jmp .try_number
.print_res:
    fstp QWORD [result]
    movsd xmm0, QWORD [result]
    mov eax, 0x1
    mov rdi, outfmt
    call printf
    jmp .exit
.scan_error:
    mov eax, 4 ; системный вызов № 4 — sys_write
    mov ebx, 1 ; поток № 1 — stdout
    mov ecx, s_err ; указатель на выводимую строку
    mov edx, len1 ; длина строки
    int 80h
    jmp .exit
.op_error:
    mov eax, 4 ; системный вызов № 4 — sys_write
    mov ebx, 1 ; поток № 1 — stdout
    mov ecx, o_err ; указатель на выводимую строку
    mov edx, len2 ; длина строки
    int 80h
.exit:
    xor eax, eax
    leave
    ret
