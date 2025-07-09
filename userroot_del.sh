#!/bin/bash

# Проверяем, существует ли файл
if [ ! -f "/etc/ansible/hosts" ]; then
    echo "Файл /etc/ansible/hosts не найден!"
    exit 1
fi

# Создаем временный файл для хранения отфильтрованных данных
temp_file=$(mktemp)

# Удаляем строки с 'userroot' и сохраняем во временный файл
grep -v "userroot" /etc/ansible/hosts > "$temp_file"

# Проверяем, есть ли изменения
if ! diff /etc/ansible/hosts "$temp_file" > /dev/null; then
    # Перемещаем временный файл на место оригинального (с сохранением прав)
    sudo mv "$temp_file" /etc/ansible/hosts
    echo "Строки с 'userroot' успешно удалены."
else
    echo "Строк с 'userroot' не найдено, файл не изменен."
    rm "$temp_file"
fi
