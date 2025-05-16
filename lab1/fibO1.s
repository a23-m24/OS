.file	"fib.c"                ; Имя исходного файла
	.text                   ; Секция кода
	.globl	fibonacci       ; Объявление fibonacci как глобального символа
	.def	fibonacci;	.scl	2;	.type	32;	.endef  ; Определение для отладчика
	.seh_proc	fibonacci  ; Начало функции (SEH)
fibonacci:
	pushq	%rsi            ; Сохраняем rsi
	.seh_pushreg	%rsi    ; Информация для отладчика
	pushq	%rbx            ; Сохраняем rbx
	.seh_pushreg	%rbx    ; Информация для отладчика
	subq	$40, %rsp       ; Выделяем 40 байт в стеке
	.seh_stackalloc	40      ; Информация для отладчика
	.seh_endprologue        ; Конец пролога SEH
	movl	%ecx, %ebx      ; Сохраняем аргумент n в ebx
	movl	%ecx, %eax      ; Копируем n в eax
	cmpl	$1, %ecx        ; Сравниваем n с 1
	jle	.L1              ; Если n <= 1, переходим к L1
	leal	-1(%rcx), %ecx  ; Вычисляем n-1 и сохраняем в ecx
	call	fibonacci       ; Рекурсивный вызов fibonacci(n-1)
	movl	%eax, %esi      ; Сохраняем результат в esi
	leal	-2(%rbx), %ecx  ; Вычисляем n-2 и сохраняем в ecx
	call	fibonacci       ; Рекурсивный вызов fibonacci(n-2)
	addl	%esi, %eax      ; Складываем результаты
.L1:
	addq	$40, %rsp       ; Освобождаем стек
	popq	%rbx            ; Восстанавливаем rbx
	popq	%rsi            ; Восстанавливаем rsi
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
	subq	$40, %rsp       ; Выделяем 40 байт в стеке
	.seh_stackalloc	40      ; Информация для отладчика
	.seh_endprologue        ; Конец пролога SEH
	call	__main          ; Инициализация для MinGW
	movl	$10, %ecx       ; Устанавливаем аргумент n=10
	call	fibonacci       ; Вызов fibonacci(10)
	movl	%eax, %r8d      ; Третий аргумент printf - результат
	movl	$10, %edx       ; Второй аргумент - n=10
	leaq	.LC0(%rip), %rcx ; Первый аргумент - строка формата
	call	printf          ; Вызов printf
	movl	$0, %eax        ; Возвращаем 0
	addq	$40, %rsp       ; Освобождаем стек
	ret                     ; Возврат из main
	.seh_endproc           ; Конец функции для SEH

	.def	__main;	.scl	2;	.type	32;	.endef  ; Определение для отладчика
	.ident	"GCC: (Rev2, Built by MSYS2 project) 14.2.0"  ; Информация о компиляторе
	.def	printf;	.scl	2;	.type	32;	.endef  ; Определение printf для отладчика