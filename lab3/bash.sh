#!/bin/bash

# Проверка количества аргументов
if [ $# -ne 2 ]; then
    echo "Использование: $0 <строка_для_поиска> <выходной_файл>"
    exit 1
fi

search_string="$1"
output_file="$2"

# Проверка существования выходного файла
if [ -e "$output_file" ]; then
    read -p "Файл '$output_file' уже существует. Перезаписать? (y/n): " answer
    if [ "$answer" != "y" ]; then
        echo "Операция отменена."
        exit 1
    fi
fi

# Поиск файлов .txt, содержащих искомую строку
echo "Поиск строки '$search_string' в файлах .txt..."
grep -rl --include="*.txt" "$search_string" . > "$output_file"

# Проверка результатов
if [ -s "$output_file" ]; then
    count=$(wc -l < "$output_file")
    echo "Найдено $count файлов. Список сохранён в '$output_file'"
else
    echo "Файлы, содержащие строку '$search_string', не найдены."
    rm -f "$output_file"
fi