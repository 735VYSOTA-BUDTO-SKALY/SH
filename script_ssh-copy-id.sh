#!/bin/bas#!/bin/bash

KEY_PATH="/root/.ssh/id_ed25519.pub"
HOSTS_FILE="/etc/ansible/11"

# Массив пользователей в нужном порядке
USER_ORDER=("userroot" "user" "adminis")

# Ассоциативный массив: пользователь -> пароли (для user два варианта)
declare -A USERS
USERS["userroot"]="Gthdsqhfp!2#4"
USERS["user"]="Gfgbhec@9 123123"  # Два пароля через пробел
USERS["adminis"]="Gfgbhec@9"

for HOST in $(cat "$HOSTS_FILE"); do
    echo "==== Обработка $HOST ===="
    SUCCESS=0
    
    for USER in "${USER_ORDER[@]}"; do
        # Получаем пароли для текущего пользователя
        read -ra PASSWORDS <<< "${USERS[$USER]}"
        
        for PASS in "${PASSWORDS[@]}"; do
            echo "Пробуем $USER@$HOST с паролем $PASS"
            
            # Команда для копирования ключа
            SSH_CMD="sshpass -p '$PASS' ssh-copy-id -i '$KEY_PATH' -o StrictHostKeyChecking=no '$USER@$HOST' 2>/dev/null"
            
            if eval "$SSH_CMD"; then
                echo "Успешно: $USER@$HOST"
                SUCCESS=1
                break 2  
	    fi
        done
    done
    
    if [[ $SUCCESS -eq 0 ]]; then
        echo "Ошибка: не удалось подключиться к $HOST ни под одним пользователем!"
    fi
    
    echo
done












##

















##!/bin/bash

#KEY_PATH="/root/.ssh/id_ed25519"
#HOSTS_FILE="./hosts.txt"

# Массив пользователей в нужном порядке
#USER_ORDER=("userroot" "user" "user" "adminis")

# Ассоциативный массив: пользователь -> пароль
#declare -A USERS
#USERS["userroot"]="Gthdsqhfp!2#4"
#USERS["user"]="Gfgbhec@9"
#USERS["user"]="123123"
#USERS["adminis"]="Gfgbhec@9"

#for HOST in $(cat "$HOSTS_FILE"); do
#    echo "==== Обработка $HOST ===="
#    SUCCESS=0
#    for USER in "${USER_ORDER[@]}"; do
#        PASS="${USERS[$USER]}"
#        # Для user пробуем оба пароля
#        if [[ "$USER" == "user" ]]; then
#            for UPASS in "Gfgbhec@9" "123123"; do
#                echo "Пробуем $USER@$HOST с паролем $UPASS"
#                sshpass -p "$UPASS" ssh-copy-id -i "$KEY_PATH" -o StrictHostKeyChecking=no "$USER@$HOST" 2>/dev/null
#                if [[ $? -eq 0 ]]; then
#                    echo "Успешно: $USER@$HOST"
#                    SUCCESS=1
#                    break 2
#                fi
#            done
#        else
#            echo "Пробуем $USER@$HOST с паролем $PASS"
#            sshpass -p "$PASS" ssh-copy-id -i "$KEY_PATH" -o StrictHostKeyChecking=no "$USER@$HOST" 2>/dev/null
#            if [[ $? -eq 0 ]]; then
#                echo "Успешно: $USER@$HOST"
#                SUCCESS=1
#                break
#            fi
#        fi
#    done
#    if [[ $SUCCESS -eq 0 ]]; then
#        echo "Не удалось подключиться к $HOST ни под одним пользователем!"
#    fi
#    echo
#done
