.file	"parallel.c"        ; Имя исходного файла
	.text                 ; Начало секции кода

	.globl	calculate_fibonacci  ; Объявление функции
	.def	calculate_fibonacci;	.scl	2;	.type	32;	.endef  ; Метаданные для отладки
	.seh_proc	calculate_fibonacci  ; Начало функции (SEH)
calculate_fibonacci:
	pushq	%rsi          ; Сохранение rsi
	.seh_pushreg	%rsi  ; Информация для отладчика
	pushq	%rbx          ; Сохранение rbx
	.seh_pushreg	%rbx  ; Информация для отладчика
	subq	$40, %rsp     ; Выделение места в стеке
	.seh_stackalloc	40    ; Информация для отладчика
	.seh_endprologue      ; Конец пролога SEH

	movl	(%rcx), %ecx  ; Загрузка n из переданного указателя
	call	fibonacci     ; Вызов fibonacci(n)
	movl	%eax, %ebx    ; Сохранение результата в ebx

	; Блокировка мьютекса
	leaq	mutex(%rip), %rsi  ; Загрузка адреса mutex
	movq	%rsi, %rcx    ; Подготовка аргумента
	call	pthread_mutex_lock  ; Вызов pthread_mutex_lock

	; Обновление shared_result
	addl	%ebx, shared_result(%rip)  ; shared_result += результат

	; Разблокировка мьютекса
	movq	%rsi, %rcx    ; Подготовка аргумента
	call	pthread_mutex_unlock  ; Вызов pthread_mutex_unlock

	movl	$0, %eax        ; Возвращаемое значение (0)
	addq	$40, %rsp       ; Освобождение стека
	popq	%rbx            ; Восстановление rbx
	popq	%rsi            ; Восстановление rsi
	ret                   ; Возврат из функции
	.seh_endproc         ; Конец функции (SEH)

	.section .rdata,"dr"  ; Секция read-only данных
.LC0:
	.ascii "Combined result: %d\12\0"  ; Строка формата для printf

	.text                 ; Секция кода
	.globl	main          ; Объявление main
	.def	main;	.scl	2;	.type	32;	.endef  ; Метаданные для отладки
	.seh_proc	main    ; Начало функции (SEH)
main:
	pushq	%rbx          ; Сохранение rbx
	.seh_pushreg	%rbx  ; Информация для отладчика
	subq	$64, %rsp     ; Выделение места в стеке
	.seh_stackalloc	64    ; Информация для отладчика
	.seh_endprologue      ; Конец пролога SEH

	call	__main        ; Инициализация (для MinGW)

	; Инициализация аргументов для потоков
	movl	$10, 40(%rsp)  ; thread_args[0] = 10
	movl	$15, 44(%rsp)  ; thread_args[1] = 15

	; Инициализация мьютекса
	movl	$0, %edx      ; NULL для атрибутов
	leaq	mutex(%rip), %rbx  ; Загрузка адреса mutex
	movq	%rbx, %rcx    ; Подготовка аргумента
	call	pthread_mutex_init  ; Вызов pthread_mutex_init

	; Создание первого потока
	leaq	48(%rsp), %rcx  ; &threads[0]
	leaq	40(%rsp), %r9  ; &thread_args[0]
	leaq	calculate_fibonacci(%rip), %r8  ; Функция
	movl	$0, %edx       ; NULL для атрибутов
	call	pthread_create  ; Вызов pthread_create

	; Создание второго потока
	leaq	56(%rsp), %rcx  ; &threads[1]
	leaq	44(%rsp), %r9  ; &thread_args[1]
	leaq	calculate_fibonacci(%rip), %r8  ; Функция
	movl	$0, %edx       ; NULL для атрибутов
	call	pthread_create  ; Вызов pthread_create

	; Ожидание завершения первого потока
	movl	$0, %edx       ; NULL для возвращаемого значения
	movq	48(%rsp), %rcx ; threads[0]
	call	pthread_join   ; Вызов pthread_join

	; Ожидание завершения второго потока
	movl	$0, %edx       ; NULL для возвращаемого значения
	movq	56(%rsp), %rcx ; threads[1]
	call	pthread_join   ; Вызов pthread_join

	; Вывод результата
	movl	shared_result(%rip), %edx  ; Загрузка shared_result
	leaq	.LC0(%rip), %rcx  ; Загрузка строки формата
	call	printf        ; Вызов printf

	; Уничтожение мьютекса
	movq	%rbx, %rcx     ; Подготовка аргумента
	call	pthread_mutex_destroy  ; Вызов pthread_mutex_destroy

	movl	$0, %eax        ; Возвращаемое значение (0)
	addq	$64, %rsp       ; Освобождение стека
	popq	%rbx            ; Восстановление rbx
	ret                   ; Возврат из main
	.seh_endproc         ; Конец функции (SEH)

	; Объявление глобальных переменных
	.globl	shared_result
	.bss
	.align 4
shared_result:
	.space 4              ; Выделение 4 байт для shared_result
	.globl	mutex
	.align 8
mutex:
	.space 8              ; Выделение 8 байт для mutex

	.def	__main;	.scl	2;	.type	32;	.endef  ; Метаданные для отладки
	.ident	"GCC: (Rev2, Built by MSYS2 project) 14.2.0"  ; Информация о компиляторе
	; Объявления внешних функций
	.def	fibonacci;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_lock;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_unlock;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_init;	.scl	2;	.type	32;	.endef
	.def	pthread_create;	.scl	2;	.type	32;	.endef
	.def	pthread_join;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_destroy;	.scl	2;	.type	32;	.endef