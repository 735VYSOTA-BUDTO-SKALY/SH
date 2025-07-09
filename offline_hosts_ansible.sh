#!/bin/bash
##
# PROSTO ZAPUSTIT SAM SCRIPT
##
# Запускаем ansible ping и сохраняем вывод
ANSIBLE_OUTPUT=$(ansible -m ping all 2>&1)

# Проверяем, была ли ошибка выполнения ansible
if [ $? -ne 0 ]; then
    echo "Ошибка выполнения ansible:" >&2
    echo "$ANSIBLE_OUTPUT" >&2
    exit 1
fi

# Извлекаем неактивные хосты (IP или имена)
FAILED_HOSTS=$(echo "$ANSIBLE_OUTPUT" | grep -E 'UNREACHABLE!|FAILED!' | awk '{print $1}')

# Фильтруем только IP-адреса (если нужно)
FAILED_IPS=$(echo "$FAILED_HOSTS" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

# Сохраняем результат в файл
if [ -n "$FAILED_IPS" ]; then
    echo "$FAILED_IPS" > failed_ips.txt
    echo "Сохранено неактивных IP-адресов: $(wc -l < failed_ips.txt)" >&2
else
    echo "Все хосты активны." >&2
    touch failed_ips.txt  # Создаем пустой файл для совместимости
fi


































