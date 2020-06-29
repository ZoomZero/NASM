
global main

section .rodata
  inpfmt: db '%d', 0x0 ; строки стандартной библиотеки libc оканчиваются на 0
  outfmt: db 't=%d, %.5f', 0xa, 0x0 ; будем переводить строку каждый раз
  phi: dq 0.2

section .bss
  result: resq 1
  samples: resd 1
  t: resd 1

section .text
  extern scanf
  extern printf
main:
  push rbp
  mov rbp, rsp
  mov rdi, inpfmt
  mov rsi,  samples
  call scanf ; scanf("%d", &samples)
  mov ebx, DWORD [samples]
  finit
  fld QWORD [phi]
  fld1
  fadd st0
  fldpi
  fmulp st1
  fild DWORD [samples]
  fdivp st1
  mov DWORD [t], 0
.cycle:
  cmp DWORD [t], ebx
  jae .exit
  fild DWORD [t]
  fmul st1
  fadd st2
  fsin
  fstp QWORD [result]
  movsd xmm0, QWORD [result]
  mov eax, 0x1
  mov rdi, outfmt
  mov esi, DWORD [t]
  call printf
  inc DWORD [t]
  jmp .cycle
.exit:
  xor eax, eax
  leave
  ret
