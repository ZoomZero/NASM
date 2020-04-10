global _start

section .bss
buf: resb 256 ; аллоцируем буфер размером 256 байт
buflen: equ $-buf
base_in: resq 1; основание входного числа
base_out: resq 1; основание для печати числа
number: resq 1; само число

section .data
msg db "Error! Base must be under 63" ;, 0xa
entr db 0xa
len equ $-msg
const equ 63

section .text

_start:
	; читаем основание по основанию 10
	call read_buf ; читаем с клавиатуры
	mov BYTE [buf+rax], 0 ; обнуляем последний символ
	mov rbx, 10 ; загружаем базу в rbx
	mov rsi, buf ; а в rsi -- адрес глобального буфера
	call decode ; пытаемся распознать в строке число
	cmp rax, const
 	ja print_err
	mov [base_in], rax ; сохранить в base_in

	; читаем число по основанию base_in
	call read_buf ;
	mov BYTE [buf+rax], 0
	mov rbx, [base_in]
	call decode
	mov [number], rax ; результат сохраняем в number

	; читаем основание по основанию 10
	call read_buf
	mov BYTE [buf+rax], 0
	mov rbx, 10
	mov rsi, buf
	call decode
	cmp rax, const
	ja print_err
	mov [base_out], rax

	; выводим число
	mov rbx, [base_out] ; основание -- в rbx
	mov rax, [number] ; само число -- в rax
	lea rsi, [buf+buflen-1] ; буфер -- в rsi
	call encode
	; результат -- в rsi
	; количество символов -- в rax
	call print_buf
	call print_entr
	; syscall exit
	;call exit

decode:
	; converts buffer to number in rax
	; адрес буфера - rsi
	; основание - rbx
	; результат - rax
	push rsi ; сохраняем регистры на стек
	push rdx
	push rcx
	xor rax, rax
	xor rdx, rdx
	xor rcx, rcx
.cycle:
	mov cl, [rsi] ; читаем байт из строки
	cmp cl, '`'
	ja .check_alpha
	cmp cl, '9'
	ja .check_big_alpha
	cmp cl, '0'
	jb .exit
	sub cl, '0' ; сформировать инкремент
	jmp .inc    ; идти дальше
.check_alpha: ; проверяем попадание в диап. 'a'-'z'
	cmp cl, 'a'
	jb .exit
	cmp cl, 'z'
	ja .exit
	; формируем инкремент
	sub cl, 'a'-10
	jmp .inc
.check_big_alpha:
	cmp cl, 'A'
	jb .exit
	cmp cl, 'Z'
	ja .exit
	sub cl, 'A'-36
.inc:
	; сдвигаем разряд
	mul rbx
	; прибавляем смещение
	add rax, rcx
	; двигаемся дальше по буферу
	inc rsi
	jmp .cycle
.exit:
	pop rcx
	pop rdx
	pop rsi
	ret

encode:
	; encode rsi -- конец буфера, rax (число) rbx (основание)
	mov BYTE [rsi], 0 ; конец строки
	mov rdi, rsi ; сохраняем адрес конца строки
.cycle:
	xor rdx, rdx
	div rbx;  [rdx, rax] / rbx ->  rdx (остаток), rax (частное)
	cmp dl, 35
	ja .process_big_alpha
	cmp dl, 9
	ja .process_alpha
	add dl, '0'
	jmp .proc
.process_alpha:
	add dl, 'a'-10
	jmp .proc
.process_big_alpha:
	add dl, 'A'-36
.proc:
	dec rsi
	mov [rsi], dl
	test rax, rax ; быстрый тест на 0
	jnz .cycle
	mov rax, rdi
	sub rax, rsi ; количество символов -- в rax
	inc rax ; не забываем символ 0 на конце
	ret

read_buf:
	push rbx
	push rcx
	push rdx
	mov rax, 0x3 ; системный вызов read(rbx, rcx, rdx)
	mov rbx, 0x0 ; stdin
	mov rcx, buf ;
	mov rdx, 256 ;
	; количество прочитанных байт возвращается в rax
	int 80h
	pop rdx
	pop rcx
	pop rbx
	ret

print_buf:
	mov rdx, rax ; количество выводимых символов -- в rdx
	mov rcx, rsi ; буфер - в rcx
	mov rax, 0x4 ; syscall write
	mov rbx, 0x1 ; to stdout
	int 80h
	ret

print_err:
	mov eax, 4 ; системный вызов № 4 — sys_write
	mov ebx, 1 ; поток № 1 — stdout
	mov ecx, msg ; указатель на выводимую строку
	mov edx, len ; длина строки
	int 80h
	call exit

print_entr:
	mov eax, 4 ; системный вызов № 4 — sys_write
	mov ebx, 1 ; поток № 1 — stdout
	mov ecx, entr ; указатель на выводимую строку
	mov edx, 1 ; длина строки
	int 80h
	call _start

exit:
	mov rax, 0x1
	mov rbx, 0x0
	int 80h


;nasm -f elf64 -o name.o name.asm
;ld -o name name.o
