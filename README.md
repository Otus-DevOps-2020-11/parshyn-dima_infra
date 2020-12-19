# parshyn-dima_infra
parshyn-dima Infra repository
### Настройка ssh agent forward
Для доступа к внутренним ресурсам через bastion, можно создать файл config в домашнем каталоге пользователя ~/.ssh/config, следующего содержания.
```
Host    bastion
        hostname <External IP bastion>

Host    someinternalhost
        ProxyJump bastion

Host *
        user <username>
        ForwardAgent yes
        ControlMaster auto
        ControlPersist 5
```
### Настройка VPN Pritunl
Настройка выполняется по методичке.
В процессе установки с помощью скрипта столкнулся с тем, что для установки необходим пакет iptables. Добавил команду для установки iptables
в скрипт.

IP серверов:
```
bastion_IP = 130.193.40.162
someinternalhost_IP = 10.129.0.29
```
Для настройки ssl сертификата использовал следующее доменное имя **bastion.130.193.40.162.xip.io**.
Данное dns имя внес в настройки settings - Lets Encrypt Domain.

## Домашняя работа №6
### Деплой тестового приложения

```
testapp_IP = 178.154.226.247
testapp_port = 9292
```

В данном ДЗ установил Yandex CLI.
С помощью Yandex CLI развернул ВМ в Yandex Cloud.
```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/<public key>
  ```
По методичке установил  Ruby, MongoDB, тестовое приложение.
Команды с помощью, которых настраивал приложение, сохранил в bash скрипты.
Дополнительно для установки приложения необходимо добавить такие пакеты как:
 - apt-transport-https
 - ca-certificates
 - git
Без данных пакетов деплой в TravicCI заканчивается ошибкой.

### Задание со *

Создал bash скрипт **setup.sh** для развертывания инстанса и деплоя приложения.
При выполнении задания столкнулся с тем, что необходимо указывать полный путь куда необходимо
клонировать репозиторий приложения, а также указать полный путь для перехода в директорию приложения.

Для проверки необходимо скачать файл setup.sh и выполнить команду

        bash setup.sh
