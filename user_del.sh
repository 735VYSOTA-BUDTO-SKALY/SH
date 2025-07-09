#!/bin/bash

FILE="/etc/ansible/hosts_userroot"

# Проверяем, существует ли файл
if [ ! -f "$FILE" ]; then
    echo "Ошибка: файл $FILE не найден!" >&2
    exit 1
fi

# Удаляем только строки с точным словом 'user' (не userroot, не username и т. д.)
if grep -q -w "user" "$FILE"; then
    echo "Удаление строк, содержащих слово 'user'..."
    sudo sed -i '/\<user\>/d' "$FILE"
    echo "Готово! Строки с 'user' удалены."
else
    echo "Строк с точным словом 'user' не найдено. Файл не изменён."
fi
