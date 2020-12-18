# parshyn-dima_infra
parshyn-dima Infra repository
## Домашнее задание №5
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

## Домашнее задание №6

### Деплой тестового приложения

testapp_IP = 178.154.227.88
testapp_port = 9292
