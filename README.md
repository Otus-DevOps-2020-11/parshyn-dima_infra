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

## Домашняя работа №8

### Cоздание и описание инфраструктуры при помощи Terraform

Установил 12-ю версию.
Развернул по методичке тестовое приложение с помощью terraform.

### Самостоятельные задания

1. в файле terraform.tfvars добавил параметр
```
private_key_path = "~/.ssh/id_rsa"
```
	  В файле main.tf первой строкой добавил
```
variable "private_key_path" {}
```
2. Если не задавать зону в ресурсе, то используется значение по умолчанию, что нам и нужно. То есть ничего указывать и не нужно.
3. Применил команду terraform fmt в текущей директории.
4. Добавил файл terraform.tfvars.example

### Задание с ** (1)

По официальной документации добавил load balancer.
### Задание с ** (2)

Добавил еще один инстанс тестового приложения, с помощью копирования кода.
Добавил вывод переменных балансировщика в output

Создание инстансов с помощью дублирования кода является крайне неудобным решением. Нет возможности масштабирования инфраструктуры, большое количество строк кода, можно очень легко допустить ошибку.

### Задание с ** (3)
Настроил создание инстансов с помощью переменной count

## Домашняя работа №9

Развернул ВМ с отдельным vpc.
Связал создаваемые ресурсы с данным vpc. Тем самым мы создали зависимость между ресурсами. Так как один ресурс ссылается на другой, при развертывании эти зависимости учитываются. Сначала создаётся сеть, затем подсеть, затем инстанс.

```
network_id     = yandex_vpc_network.app-network.id
```
Создал два файла db.json и app.json, скопировал содержимое файла ubuntu16.json. Это новые шаблоны для образов Packer. В каждом оставил свой провиженер.

Разбил main.tf на разные файлы (app.tf, db.tf, vpc.tf)

### Модули

Далее работа с модулями, это своего рода шаблоны для ВМ. Модули создаём для bd и app. В директорию модулю добавляются необходимые файлы (main.tf, variables.tf, outputs.tf).

Далее необходимо создать инфраструктуры для stage и prod на основе существующих модулей. Для stage и prod создаются отдельные каталоги в которых создаются файлы (main.tf, variables.tf, outputs.tf, terraform.tfvars, key.json) В main указывается провайдер, и описывается модуль. В модуле можно указывать переменные из другого модуля. Например, чтобы указать ip базы данных для приложения, создавалась переменная, которая брала данные из модуля db.
```
database_url     = "${module.db.external_ip_address_db}"
```
### Задание со *

Для хранения состояний создал через вэб консоль Object Storage и настроил хранение tfstate в данном storage. Хорошая инструкция в официальной документации. https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-state-storage
Настройки для хранения сохранены в backend.tf
```
terraform {
  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "dparshin-hw09-tfstate"
    region                      = "ru-central1"
    key                         = "prod/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```
Доступ открыл только для авторизованных пользователей.

### Задание со **

Так как мы разделили инстансы на BD и APP, то приложение не работает. Для того чтобы указать приложению адрес БД, необходимо:

1) В модуле app указать ip базы данных для приложения.
```
database_url     = "${module.db.external_ip_address_db}"
```

2) Для запуска службы puma с ip БД, необходимо модифицировать файл systemd
```
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Environment="DATABASE_URL=${database_url}"
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

3) Для того чтобы передавать данные из модуля в ВМ, воспользовался функцией templatefile. Создал новые проженеры для деплоя приложения
```
provisioner "file" {
    content     = templatefile("${path.module}/files/puma.service.tmpl", { database_url = "${var.database_url}" })
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
```

4) В базе данных необходимо было открыть доступ с внешних адресов, по умолчанию доступ через localhost. Для этого добавил в terraform/modules/db/main.tf
```
provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/ *bindIp:.*/  bindIp: 0.0.0.0/' /etc/mongod.conf",
      "sudo systemctl restart mongod",
    ]
  }
```
Так как все виртуалки находятся за NAT, то они имеют только внутренние адреса, поэтому пришлось вписывать 0.0.0.0 (с любого ip).

5) Возникла проблема с запуском одновременно stage и prod, так как имена ВМ совладают. Для этого в main.tf (prod и stage) добавил
```
locals {
  app_name = "reddit-app-${var.environment}"
  db_name  = "reddit-db-${var.environment}"
}
```
Теперь в конце имени ВМ добавляется stage или prod

## Домашняя работа №10

Установил ansible 2.9.16 через dnf
```
sudo dnf inatsll ansible
```

Запустил инстансы из директории stage
Создал файл inventory в директории ansible
```
appserver ansible_host=<external_ip_reddit-app-stage> ansible_user=ubuntu ansible_private_key_file=~/.ssh/id_rsa.pub
appserver ansible_host=<external_ip_reddit-db-stage> ansible_user=ubuntu ansible_private_key_file=~/.ssh/id_rsa.pub
```
Выполнил команду из директории ansible
```
ansible appserver -i ./inventory -m ping
ansible dbserver -i ./inventory -m ping
```
appserver - имя хоста в инвентори
-i - путь к файлу инвентори
-m - модуль
Создал и изменил ansible.cfg, чтобы каждый раз не указывать пользователя, путь к ssh ключу, и файлу инвентори.
```
ansible dbserver -m command -a uptime
```
Создал в инвентори группы [app] и [db]
Проверка
```
ansible app -m ping
```
Создал инвентори в формате yml
```
---
all:
  children:
    app:
      hosts:
        appserver:
          ansible_host: 84.201.172.235
    db:
      hosts:
        dbserver:
          ansible_host: 84.201.128.116
```
Проверим, что на app сервере установлены компоненты для работы приложения (ruby и bundler):
```
ansible app -m command -a 'ruby -v'
ansible app -m command -a 'bundler -v'
```
Через command нельзя выполнить две команды, так как в нем не работают перенаправления. Для этого необходимо использовать модуль shell
```
ansible app -m shell -a 'ruby -v; bundler -v'
```
Проверим статус службы
```
ansible db -m command -a 'systemctl status mongod'
ansible db -m shell -a 'systemctl status mongod'
```
Это же можно выполнить через модуль systemd или service для более старых систем
```
ansible db -m systemd -a name=mongod
ansible db -m service -a name=mongod
```
Преимуществом модулей перед shell командами заключается в том, что модули выдают информацию в качестве набора переменных и его легко парсить, и обрабатывать в дальнейшем.
Выполнил клонирование репозитория приложения
```
ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
```
Так как в предыдущем уроке выполнял задание со *, то приложение уже развернуто и никаких изменений не произошло.
Добавил плейбук clone.yml, который также будет клонировать приложение из github. Так как каталог уже существует, то при выполнение данного прейбука никаких изменений не произошло.
Если удалить каталог reddit и вновь запустить плайбук, то изменения буду
```
ansible app -m command -a 'rm -rf ~/reddit'
```
То есть ansible определил, что каталога нет и выполнил плайбук.
