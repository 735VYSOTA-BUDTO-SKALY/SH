import sys
from pyzabbix import ZabbixAPI
# # Установка дополнительных пакетов
#apt install python3-dev python3-setuptools -y
#pip3 install pyzabbix
# Конфигурация подключения к Zabbix
ZABBIX_URL = "http://192.166.1.1/zabbix"
ZABBIX_USER = "Admin"
ZABBIX_PASSWORD = "zabbix"

# Группа и шаблон для новых хостов
GROUP_NAME = "Linux servers"
TEMPLATE_NAME = "Linux by Zabbix agent"

# Файл с данными о хостах (формат: IP - имя)
HOSTS_FILE = "hosts_list.txt"


def main():
    # Подключение к Zabbix API
    zapi = ZabbixAPI(ZABBIX_URL)
    zapi.session.verify = False  # Отключаем проверку SSL сертификата
    try:
        zapi.login(user=ZABBIX_USER, password=ZABBIX_PASSWORD)
        print(f"Успешно подключились к Zabbix серверу {ZABBIX_URL}")
    except Exception as e:
        print(f"Ошибка при подключении к Zabbix: {e}")
        sys.exit(1)

    # Получаем ID группы "Linux servers"
    group_id = get_group_id(zapi, GROUP_NAME)
    if not group_id:
        print(f"Группа '{GROUP_NAME}' не найдена в Zabbix")
        sys.exit(1)

    # Получаем ID шаблона "Linux by Zabbix agent"
    template_id = get_template_id(zapi, TEMPLATE_NAME)
    if not template_id:
        print(f"Шаблон '{TEMPLATE_NAME}' не найден в Zabbix")
        sys.exit(1)

    # Чтение списка хостов из файла
    try:
        with open(HOSTS_FILE, mode="r", encoding="utf-8") as file:
            for line_num, line in enumerate(file, 1):
                line = line.strip()
                if not line or line.startswith('#'):  # Пропускаем пустые строки и комментарии
                    continue

                # Разбираем строку формата: IP - имя
                parts = line.split(' - ')
                if len(parts) != 2:
                    print(f"Неверный формат строки {line_num}: {line}")
                    continue

                ip_address = parts[0].strip()
                host_name = parts[1].strip()

                # Заменяем @ на . в имени хоста
                host_name = host_name.replace("@", ".")

                # Проверяем, существует ли хост с данным IP в Zabbix
                if is_host_exists_by_ip(zapi, ip_address):
                    print(f"Хост с IP {ip_address} уже существует в Zabbix. Пропускаем.")
                    continue

                # Проверяем, существует ли хост с таким именем
                if is_host_exists_by_name(zapi, host_name):
                    print(f"Хост с именем {host_name} уже существует в Zabbix. Пропускаем.")
                    continue

                # Создаем новый хост
                try:
                    create_host(zapi, ip_address, host_name, group_id, template_id)
                    print(f"Добавлен новый хост: {host_name} ({ip_address})")
                except Exception as e:
                    print(f"Ошибка при добавлении хоста {host_name} ({ip_address}): {e}")

    except FileNotFoundError:
        print(f"Файл {HOSTS_FILE} не найден")
        sys.exit(1)
    except Exception as e:
        print(f"Ошибка при чтении файла: {e}")
        sys.exit(1)

    print("Завершение скрипта.")


def get_group_id(zapi, group_name):
    """Получение ID группы по имени"""
    groups = zapi.hostgroup.get(filter={"name": group_name})
    if groups:
        return groups[0]["groupid"]
    return None


def get_template_id(zapi, template_name):
    """Получение ID шаблона по имени"""
    templates = zapi.template.get(filter={"host": template_name})
    if templates:
        return templates[0]["templateid"]
    return None


def is_host_exists_by_ip(zapi, ip_address):
    """Проверка существования хоста по IP"""
    hosts = zapi.host.get(filter={"ip": ip_address})
    return bool(hosts)


def is_host_exists_by_name(zapi, host_name):
    """Проверка существования хоста по имени"""
    hosts = zapi.host.get(filter={"host": host_name})
    return bool(hosts)


def create_host(zapi, ip_address, host_name, group_id, template_id):
    """Создание нового хоста в Zabbix"""
    zapi.host.create(
        host=host_name,
        interfaces=[
            {
                "type": 1,  # 1 - интерфейс типа Zabbix agent
                "main": 1,
                "useip": 1,
                "ip": ip_address,
                "dns": "",
                "port": "10050",
            }
        ],
        groups=[{"groupid": group_id}],
        templates=[{"templateid": template_id}],
    )


if __name__ == "__main__":
    main()
