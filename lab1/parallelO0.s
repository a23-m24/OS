.file	"parallel.c"        ; Имя исходного файла
	.text                 ; Начало секции кода

	; Объявление глобальных переменных
	.globl	mutex          ; Объявление mutex как глобального символа
	.bss                  ; Секция неинициализированных данных
	.align 8              ; Выравнивание на 8 байт
mutex:
	.space 8              ; Выделение 8 байт для mutex
	.globl	shared_result  ; Объявление shared_result как глобального символа
	.align 4              ; Выравнивание на 4 байта
shared_result:
	.space 4              ; Выделение 4 байт для shared_result

	.text                 ; Возврат в секцию кода
	.globl	calculate_fibonacci  ; Объявление функции
	.def	calculate_fibonacci;	.scl	2;	.type	32;	.endef  ; Метаданные для отладки
	.seh_proc	calculate_fibonacci  ; Начало функции (SEH)
calculate_fibonacci:
	pushq	%rbp          ; Сохранение базового указателя
	.seh_pushreg	%rbp  ; Информация для отладчика
	movq	%rsp, %rbp    ; Установка нового базового указателя
	.seh_setframe	%rbp, 0  ; Информация для отладчика
	subq	$48, %rsp     ; Выделение места в стеке
	.seh_stackalloc	48    ; Информация для отладчика
	.seh_endprologue      ; Конец пролога SEH

	movq	%rcx, 16(%rbp) ; Сохранение аргумента (указателя на n) в стеке
	movq	16(%rbp), %rax ; Загрузка указателя
	movl	(%rax), %eax   ; Загрузка значения n
	movl	%eax, -4(%rbp) ; Сохранение n в стеке
	movl	-4(%rbp), %eax ; Загрузка n
	movl	%eax, %ecx     ; Подготовка аргумента для fibonacci
	call	fibonacci     ; Вызов fibonacci(n)
	movl	%eax, -8(%rbp) ; Сохранение результата в стеке

	; Блокировка мьютекса
	leaq	mutex(%rip), %rax  ; Загрузка адреса mutex
	movq	%rax, %rcx     ; Подготовка аргумента
	call	pthread_mutex_lock  ; Вызов pthread_mutex_lock

	; Обновление shared_result
	movl	shared_result(%rip), %edx  ; Загрузка shared_result
	movl	-8(%rbp), %eax  ; Загрузка результата fibonacci
	addl	%edx, %eax      ; Сложение результатов
	movl	%eax, shared_result(%rip)  ; Сохранение обратно

	; Разблокировка мьютекса
	leaq	mutex(%rip), %rax  ; Загрузка адреса mutex
	movq	%rax, %rcx     ; Подготовка аргумента
	call	pthread_mutex_unlock  ; Вызов pthread_mutex_unlock

	movl	$0, %eax        ; Возвращаемое значение (0)
	addq	$48, %rsp       ; Освобождение стека
	popq	%rbp            ; Восстановление базового указателя
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
	pushq	%rbp          ; Сохранение базового указателя
	.seh_pushreg	%rbp  ; Информация для отладчика
	movq	%rsp, %rbp    ; Установка нового базового указателя
	.seh_setframe	%rbp, 0  ; Информация для отладчика
	subq	$80, %rsp     ; Выделение места в стеке
	.seh_stackalloc	80    ; Информация для отладчика
	.seh_endprologue      ; Конец пролога SEH

	call	__main        ; Инициализация (для MinGW)

	; Инициализация аргументов для потоков
	movl	$10, -40(%rbp)  ; thread_args[0] = 10
	movl	$15, -36(%rbp)  ; thread_args[1] = 15

	; Инициализация мьютекса
	movl	$0, %edx      ; NULL для атрибутов
	leaq	mutex(%rip), %rax  ; Загрузка адреса mutex
	movq	%rax, %rcx    ; Подготовка аргумента
	call	pthread_mutex_init  ; Вызов pthread_mutex_init

	; Создание потоков
	movl	$0, -4(%rbp)  ; i = 0
	jmp	.L4            ; Переход к проверке условия
.L5:
	; Подготовка аргументов для pthread_create
	leaq	-40(%rbp), %rax  ; Адрес thread_args
	movl	-4(%rbp), %edx  ; i
	movslq	%edx, %rdx     ; Расширение до 64 бит
	salq	$2, %rdx       ; Умножение на 4 (размер int)
	leaq	(%rax,%rdx), %rcx  ; &thread_args[i] (3-й аргумент)
	leaq	-32(%rbp), %rax  ; Адрес массива threads
	movl	-4(%rbp), %edx  ; i
	movslq	%edx, %rdx     ; Расширение до 64 бит
	salq	$3, %rdx       ; Умножение на 8 (размер указателя)
	addq	%rdx, %rax     ; &threads[i] (1-й аргумент)
	movq	%rcx, %r9      ; 3-й аргумент
	leaq	calculate_fibonacci(%rip), %r8  ; 2-й аргумент (функция)
	movl	$0, %edx       ; NULL для атрибутов (4-й аргумент)
	movq	%rax, %rcx     ; 1-й аргумент
	call	pthread_create  ; Вызов pthread_create

	addl	$1, -4(%rbp)   ; i++
.L4:
	cmpl	$1, -4(%rbp)   ; Сравнение i <= 1
	jle	.L5            ; Если true, продолжаем цикл

	; Ожидание завершения потоков
	movl	$0, -8(%rbp)   ; j = 0
	jmp	.L6            ; Переход к проверке условия
.L7:
	movl	-8(%rbp), %eax ; j
	cltq                 ; Расширение до 64 бит
	movq	-32(%rbp,%rax,8), %rax  ; threads[j]
	movl	$0, %edx       ; NULL для возвращаемого значения
	movq	%rax, %rcx     ; Подготовка аргумента
	call	pthread_join   ; Вызов pthread_join

	addl	$1, -8(%rbp)   ; j++
.L6:
	cmpl	$1, -8(%rbp)   ; Сравнение j <= 1
	jle	.L7            ; Если true, продолжаем цикл

	; Вывод результата
	movl	shared_result(%rip), %eax  ; Загрузка shared_result
	movl	%eax, %edx     ; Подготовка аргумента
	leaq	.LC0(%rip), %rax  ; Загрузка строки формата
	movq	%rax, %rcx     ; Подготовка аргумента
	call	printf        ; Вызов printf

	; Уничтожение мьютекса
	leaq	mutex(%rip), %rax  ; Загрузка адреса mutex
	movq	%rax, %rcx     ; Подготовка аргумента
	call	pthread_mutex_destroy  ; Вызов pthread_mutex_destroy

	movl	$0, %eax        ; Возвращаемое значение (0)
	addq	$80, %rsp       ; Освобождение стека
	popq	%rbp            ; Восстановление базового указателя
	ret                   ; Возврат из main
	.seh_endproc         ; Конец функции (SEH)

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