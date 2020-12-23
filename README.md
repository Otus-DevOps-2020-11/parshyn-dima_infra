# parshyn-dima_infra
parshyn-dima Infra repository
## Домашняя работа №5
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
testapp_IP = 178.154.246.93
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

## Домашняя работа №7
### Сборка образов VM при помощи Packer

Установил Packer.
Создал сервисный аккаунт
Для создания через CLI сервисного аккаунта, необходимы настройки профиля
```
yc config list
```
Добавил переменные с именем пользователя и ID каталога
SVC_ACCT=packer
FOLDER_ID=
```
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```
Назначил права для сервисного аккаунта
```
ACCT_ID=$(yc iam service-account get $SVC_ACCT | grep ^id | awk '{print $2}')
yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
```
Создал service account key file (файл добавил .gitignore)
```
yc iam key create --service-account-id $ACCT_ID --output ./key.json
```
Создал файл ubuntu16.json. Данный файл описывает параметры и этапы сборки образа.
Заменил информацию на свою в "service_account_key_file" и "folder_id".
Добавил два новых параметра  "subnet_id" (зайти в консоль в настройки сети и найти ip конкретной зоны, в моём случае это ru-central1-a, так как он указывался в профиле) и "use_ipv4_nat". ID сетей можно посмотреть командой
```
yc vpc subnet list
```
В скриптах удалил во всех строках sudo и в install_ruby.sh первой строкой добавил **apt list --upgradable** без этой команды сборка заканчивалась ошибкой.

Проверка синтаксиса файла для сборки (из дериктории packer)
```
packer validate ./ubuntu16.json
```
Запуск сборки (из дериктории packer)
```
packer build ./ubuntu16.json
```

После сборки образ появится в соответствующем меню в консоли.
В качестве загрузочного диска выбрал данный образ и создал ВМ.
Установил приложение из прошлого ДЗ, команды из скрипта deploy.sh
Проверка http://<внешний IP машины>:9292

Параметризовал созданный шаблон.
Создал файл variables.json с переменными и добавил в .gitignore.
Добавил следующие параметры:
```
    "folder_id":
    "source_image_id":
    "service_account_key_file":
    "source_image_family"
    "subnet_id"
```

### Задания со *
Для создания образа с уже развернутым приложением создал шаблон **immutable.json**.
Для установки приложения использовал скрипты из предыдущего ДЗ. Для запуска web сервера Puma создал файл systemd unit, puma.service.
По аналогии из предыдущего занятия создал скрипт с помощью, которого можно развернуть ВМ на основе собранного образа.

### Проверка

Скачать git репозиторий
```
git clone git@github.com:Otus-DevOps-2020-11/parshyn-dima_infra.git
```
Перейти в директорию **packer**
Для сборки образа без развернутого приложения необходимо выполнить
```
packer build -var-file=variables.json ubuntu16.json
```
Для сборки образа с развернутым приложением необходимо выполнить
```
packer build -var-file=variables.json immutable.json
```
В текущей директории должен быть создан файл с параметрами, заполненные собственными значениями.
```
    "folder_id":
    "source_image_id":
    "service_account_key_file":
    "source_image_family"
    "subnet_id"
```
Для развертывания ВМ на основе собранных образов, необходимо запустить скрипт
```
bash ../config-scripts/create-reddit-vm.sh
```
Предварительно заменив параметр **image-id** на своё значение. Получить список образов в каталоге по умолчанию можно
```
yc compute image list
```
