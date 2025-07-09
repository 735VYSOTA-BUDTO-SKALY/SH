#!/bin/bash
#сканит сеть, если нет пинга то отбрасывает адрес, если есть пытается войти под разными пользаками  и потом под каким пользаком смог войти выводит в файл  succesful_ips.txt в формате  ansible inventory
start_ip="10.221.213.1"
end_ip="10.221.213.255"
output_file="successful_ips.txt"
port=22

user1="userroot"
pass1="Gthdsqhfp!2#4"

user2="user"
pass2="Gfgbhec@9"

# Преобразование IP в число
ip_to_num() {
  local IFS=.
  read -r i1 i2 i3 i4 <<< "$1"
  echo $((i1 * 256 * 256 * 256 + i2 * 256 * 256 + i3 * 256 + i4))
}

# Преобразование числа в IP
num_to_ip() {
  local num=$1
  echo "$(( (num >> 24) & 255 )).$(( (num >> 16) & 255 )).$(( (num >> 8) & 255 )).$(( num & 255 ))"
}

# Пинг хоста
ping_host() {
  ping -c 1 -W 1 "$1" &>/dev/null
}

# Проверка SSH с sshpass
check_ssh() {
  local ip=$1 user=$2 pass=$3

  # Пытаемся выполнить простую команду
  if sshpass -p "$pass" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $port "$user@$ip" "echo connected" &>/dev/null; then
    echo "$ip ansible_user=$user" >> "$output_file"  # Записываем IP и ansible_user
    echo "Success: $user@$ip"
    return 0
  else
    echo "Failed: $user@$ip"
    return 1
  fi
}

main() {
  start_num=$(ip_to_num "$start_ip")
  end_num=$(ip_to_num "$end_ip")

  > "$output_file"  # Очищаем файл перед началом

  for ((ip_num=start_num; ip_num<=end_num; ip_num++)); do
    ip=$(num_to_ip "$ip_num")

    if ping_host "$ip"; then
      echo "Host $ip is up. Trying SSH..."

      # Попытка 1: userroot + pass1
      if check_ssh "$ip" "$user1" "$pass1"; then
        continue
      fi

      # Попытка 2: user + pass2
      if check_ssh "$ip" "$user2" "$pass2"; then
        continue
      fi

      echo "SSH connection failed for $ip with all credentials"
    else
      echo "Host $ip is down. Skipping."
    fi
  done
}

main
