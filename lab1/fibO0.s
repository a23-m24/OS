.file	"fib.c"                ; Имя исходного файла
	.text                   ; Начало секции кода
	.globl	fibonacci       ; Объявление fibonacci как глобального символа
	.def	fibonacci;	.scl	2;	.type	32;	.endef  ; Определение функции для отладчика
	.seh_proc	fibonacci  ; Начало функции (SEH - Structured Exception Handling)
fibonacci:
	pushq	%rbp            ; Сохраняем базовый указатель
	.seh_pushreg	%rbp    ; Информация для отладчика - сохранение регистра
	pushq	%rbx            ; Сохраняем регистр rbx
	.seh_pushreg	%rbx    ; Информация для отладчика
	subq	$40, %rsp       ; Выделяем 40 байт в стеке
	.seh_stackalloc	40      ; Информация для отладчика
	leaq	32(%rsp), %rbp  ; Устанавливаем новый базовый указатель
	.seh_setframe	%rbp, 32 ; Информация для отладчика
	.seh_endprologue        ; Конец пролога SEH
	movl	%ecx, 32(%rbp)  ; Сохраняем аргумент n в стеке
	cmpl	$1, 32(%rbp)    ; Сравниваем n с 1
	jg	.L2              ; Если n > 1, переходим к L2
	movl	32(%rbp), %eax  ; Возвращаем n (базовый случай)
	jmp	.L3              ; Переход к завершению функции
.L2:
	movl	32(%rbp), %eax  ; Получаем n из стека
	subl	$1, %eax        ; Вычисляем n-1
	movl	%eax, %ecx      ; Подготовка аргумента для вызова
	call	fibonacci       ; Рекурсивный вызов fibonacci(n-1)
	movl	%eax, %ebx      ; Сохраняем результат в ebx
	movl	32(%rbp), %eax  ; Получаем n из стека
	subl	$2, %eax        ; Вычисляем n-2
	movl	%eax, %ecx      ; Подготовка аргумента
	call	fibonacci       ; Рекурсивный вызов fibonacci(n-2)
	addl	%ebx, %eax      ; Складываем результаты двух вызовов
.L3:
	addq	$40, %rsp       ; Освобождаем стек
	popq	%rbx            ; Восстанавливаем rbx
	popq	%rbp            ; Восстанавливаем rbp
	ret                     ; Возврат из функции
	.seh_endproc           ; Конец функции для SEH

	.section .rdata,"dr"    ; Секция read-only данных
.LC0:
	.ascii "Fibonacci(%d) = %d\12\0"  ; Строка формата для printf

	.text                   ; Секция кода
	.globl	main            ; Объявление main как глобального символа
	.def	main;	.scl	2;	.type	32;	.endef  ; Определение для отладчика
	.seh_proc	main      ; Начало функции main
main:
	pushq	%rbp            ; Сохраняем базовый указатель
	.seh_pushreg	%rbp    ; Информация для отладчика
	movq	%rsp, %rbp      ; Устанавливаем новый базовый указатель
	.seh_setframe	%rbp, 0 ; Информация для отладчика
	subq	$48, %rsp       ; Выделяем 48 байт в стеке
	.seh_stackalloc	48      ; Информация для отладчика
	.seh_endprologue        ; Конец пролога SEH
	call	__main          ; Инициализация для MinGW (если нужно)
	movl	$10, -4(%rbp)   ; Сохраняем n=10 в стеке
	movl	-4(%rbp), %eax  ; Получаем n
	movl	%eax, %ecx      ; Подготовка аргумента
	call	fibonacci       ; Вызов fibonacci(10)
	movl	%eax, %edx      ; Сохраняем результат
	movl	-4(%rbp), %eax  ; Получаем n
	movl	%edx, %r8d      ; Третий аргумент printf - результат
	movl	%eax, %edx      ; Второй аргумент - n
	leaq	.LC0(%rip), %rax ; Загружаем адрес строки формата
	movq	%rax, %rcx      ; Первый аргумент printf
	call	printf          ; Вызов printf
	movl	$0, %eax        ; Возвращаем 0
	addq	$48, %rsp       ; Освобождаем стек
	popq	%rbp            ; Восстанавливаем rbp
	ret                     ; Возврат из main
	.seh_endproc           ; Конец функции для SEH

	.def	__main;	.scl	2;	.type	32;	.endef  ; Определение для отладчика
	.ident	"GCC: (Rev2, Built by MSYS2 project) 14.2.0"  ; Информация о компиляторе
	.def	printf;	.scl	2;	.type	32;	.endef  ; Определение printf для отладчика