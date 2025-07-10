#!/bin/bash
## сначало пингует если пинг есть проверяет есть ли ключ если нет кидывает , ip берутся из файла  HOSTS_FILE="pas_ini.txt" USER=это юсер под которым нужно подключаться тоесть кому нужно скинуть ключ

USER="user"
PASS_FILE="ssh_pass.txt"
SSH_KEY="/root/.ssh/id_ed25519.pub"
HOSTS_FILE="pas_ini.txt"

# Проверка файлов
for file in "$PASS_FILE" "$SSH_KEY" "$HOSTS_FILE"; do
    [ ! -f "$file" ] && { echo "❌ Файл $file не найден!" >&2; exit 1; }
done

PASS=$(head -n 1 "$PASS_FILE")
PUB_KEY=$(cat "$SSH_KEY")

process_host() {
    local host="$1"
    echo -n "🔎 Хост $host... "
    
    # Проверка доступности (ping + порт 22)
    if ! { ping -c 2 -W 1 "$host" &>/dev/null || nc -z -w 1 "$host" 22 &>/dev/null; }; then
        echo "❌ Недоступен (ping/port 22 FAILED)"
        return 1
    fi

    # Проверка ключа (с перенаправлением stdin)
    if sshpass -p "$PASS" ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$USER@$host" \
        "grep -qF '$PUB_KEY' ~/.ssh/authorized_keys" </dev/null 2>/dev/null; then
        echo "✅ Ключ есть"
        return 0
    fi

    # Добавление ключа (с перенаправлением stdin)
    echo -n "Добавляем... "
    if sshpass -p "$PASS" ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$USER@$host" \
        "mkdir -p ~/.ssh; chmod 700 ~/.ssh; echo '$PUB_KEY' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys" </dev/null 2>/dev/null; then
        echo "🎉 Успех!"
        return 0
    else
        echo "❌ Ошибка!"
        return 1
    fi
}

# Основной цикл (счетчик реально обработанных хостов)
TOTAL_HOSTS=$(grep -vc -e '^$' -e '^#' "$HOSTS_FILE")
PROCESSED=0

while IFS= read -r host; do
    [[ -z "$host" || "$host" == "#"* ]] && continue
    process_host "$host"
    ((PROCESSED++))
done < <(grep -v -e '^$' -e '^#' "$HOSTS_FILE")

echo "🏁 Реально обработано хостов: $PROCESSED/$TOTAL_HOSTS."
