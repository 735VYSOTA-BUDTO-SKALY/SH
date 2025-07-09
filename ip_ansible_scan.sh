#!/bin/bash

# Список сетей для сканирования (START_IP END_IP COMMENT)
NETWORKS="
10.223.152.1 10.223.155.255 tts
10.223.123.1 10.223.123.255 elx
10.8.117.1 10.8.117.255 elx-zai
10.223.124.1 10.223.124.255 nft
10.9.67.1 10.9.67.255 elb
10.3.217.1 10.3.217.255 sul
10.5.75.1 10.5.75.255 azn-ener
10.6.57.1 10.6.57.255 azn-akt
10.7.123.1 10.7.123.255 nur-shosse
10.7.122.1 10.7.122.255 nur-kolona
10.10.78.1 10.10.78.255 bavly
10.16.116.1 10.16.116.255 niz-shina
10.16.117.1 10.16.117.255 niz-perv
10.201.123.1 10.201.123.255 nol-nov8
10.221.213.1 10.221.213.255 tol-nov41-23
10.11.220.1 10.11.220.255 lensk-chay
10.11.221.1 10.11.221.255 lensk-trub
10.2.56.1 10.2.56.255 bug
10.15.15.1 10.15.15.255 kzn
"

output_file="successful_ips.txt"
port=22

user1="userroot"
pass1="Gthdsqhfp!2#4"
user2="user"
pass2="Gfgbhec@9"

# Функция преобразования IP в число
ip_to_num() {
  local ip="$1"
  local IFS=.
  read -r i1 i2 i3 i4 <<EOF
$ip
EOF
  echo $((i1 * 256 * 256 * 256 + i2 * 256 * 256 + i3 * 256 + i4))
}

# Функция преобразования числа в IP
num_to_ip() {
  local num="$1"
  echo "$(( (num >> 24) & 255 )).$(( (num >> 16) & 255 )).$(( (num >> 8) & 255 )).$(( num & 255 ))"
}

# Проверка доступности хоста
ping_host() {
  ping -c 1 -W 1 "$1" >/dev/null 2>&1
}

# Проверка SSH доступа
check_ssh() {
  local ip="$1" user="$2" pass="$3"
  if sshpass -p "$pass" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo connected" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

main() {
  # Очищаем выходной файл
  > "$output_file"

  echo "$NETWORKS" | while IFS= read -r line; do
    # Пропускаем пустые строки
    [ -z "$line" ] && continue

    # Разбираем строку на компоненты
    start_ip=$(echo "$line" | awk '{print $1}')
    end_ip=$(echo "$line" | awk '{print $2}')
    comment=$(echo "$line" | awk '{print $3}')

    # Проверяем, что все компоненты есть
    [ -z "$start_ip" ]  [ -z "$end_ip" ]  [ -z "$comment" ] && continue

    echo "Сканируем сеть: $start_ip - $end_ip ($comment)"
    network_has_hosts=0

    # Преобразуем IP в числа
    start_num=$(ip_to_num "$start_ip")
    end_num=$(ip_to_num "$end_ip")

    # Перебираем все IP в диапазоне
    ip_num="$start_num"
    while [ "$ip_num" -le "$end_num" ]; do
      ip=$(num_to_ip "$ip_num")

      echo "Проверяем хост: $ip"
      if ping_host "$ip"; then
        echo "Хост доступен, пробуем SSH..."
        if check_ssh "$ip" "$user1" "$pass1"; then
          [ "$network_has_hosts" -eq 0 ] && echo "[$comment]" >> "$output_file"
          echo "$ip ansible_user=$user1" >> "$output_file"
          network_has_hosts=1
        elif check_ssh "$ip" "$user2" "$pass2"; then
          [ "$network_has_hosts" -eq 0 ] && echo "[$comment]" >> "$output_file"
          echo "$ip ansible_user=$user2" >> "$output_file"
          network_has_hosts=1
        fi
      else
        echo "Хост не отвечает на ping"
      fi

      ip_num=$((ip_num + 1))
    done

    [ "$network_has_hosts" -eq 1 ] && echo >> "$output_file"
  done

  echo "Сканирование завершено. Результаты в $output_file"
}

main
