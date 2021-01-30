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

## Домашняя работа №11

**Один playbook, один сценарий**

Закомментировал в модулях терафформ провиженеры.
Заменил в inventory ansible IP на актуальные.
Добавил файл reddit_app.yml
Создал плейбук в нем. Данный плейбук открывает доступ к mongodb со всех адресов (0.0.0.0). Реализуется это с помощью модуля template. Шаблон находится в директории templates/mongod.conf.j2. Тестовый запуск выполняется с помощью команды
```
ansible-playbook reddit_app.yml --check --limit db
```
Добавим хендлер для перезапуска службы mongod после внесения изменений
Добавил в директорию files, unit-file puma.service и заменил appuser на ubuntu.
```
EnvironmentFile=/home/ubuntu/db_config
```
С помощью этой строки Puma сервер обращается в файл db_config, который содержит внутренний IP адрес ВМ базы данных.
После этого в плейбук добавил модули с деплоем приложения.
Команды для запуска определенной части playbook (db, app, deploy)
```
ansible-playbook reddit_app.yml --limit db --tags db-tag
ansible-playbook reddit_app.yml --limit app --tags app-tag
ansible-playbook reddit_app.yml --limit app --tags deploy-tag
```

**Один плейбук, несколько сценариев**

Создал файл reddit_app2.yml. На основе уже созданного playbook создал новый. Разбил на отдельные сценарии в зависимости от тегов. То есть у каждого сценария свой раздел name, vars, handlers, hosts. Вынес отдельно tags, become.
```
ansible-playbook reddit_app2.yml --tags db-tag --check
ansible-playbook reddit_app2.yml --tags db-tag
ansible-playbook reddit_app2.yml --tags app-tag --check
ansible-playbook reddit_app2.yml --tags app-tag
ansible-playbook reddit_app2.yml --tags deploy-tag --check
ansible-playbook reddit_app2.yml --tags deploy-tag
```

**Несколько плейбуков**

Разделил все сценарии на несколько плейбуков (app.yml, db.yml, deploy_app.yml). Назвать файл deploy.yml не получилось, возникала ошибка файла.
В файле site.yml перечислим все файлы с playbook.
```
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy_app.yml
```
Проверка и запуск
```
ansible-playbook site.yml --check
ansible-playbook site.yml
```

**Провижининг в Packer**

Необходимо заменить провиженеры в Packer с shell на ansible.
Создал файлы, вместо install_ruby.sh и install_mongodb.sh:
ansible/packer_app.yml - устанавливает Ruby и Bundler
ansible/packer_db.yml - добавляет репозиторий MongoDB, устанавливает ее и включает сервис.

Столкнулся с проблемой, при запуске создания образа, во время выполнения playbook была ошибка
```
yandex: failed to handshake
    yandex: fatal: [default]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Warning: Permanently added '[127.0.0.1]:34579' (RSA) to the list of known hosts.\r\nubuntu@127.0.0.1: Permission denied (publickey).", "unreachable": true}
```
Решил добавив в провиженер
```
"use_proxy": "false"
```
В результате создал два новых образа. На основе данных образов создал ВМ с помощью terraform и выполнил деплой приложения с помощью site.yml.

### Проверка

Скачать данный репозиторий
```
git clone git@github.com:Otus-DevOps-2020-11/parshyn-dima_infra.git
```
Перейти в каталог parshyn-dima_infra
Ввести в файлах prod/key.json.example, prod/terraform.tfvars.example, stage/key.json.example, stage/terraform.tfvars.example, packer/variables.json.example, packer/key.json.example изменений согласно вашей конфигурации YandexCloud.

**Создать образы packer**

Перейти в каталог packer и выполнить команды в терминале
```
packer build -var-file=variables.json app.json
packer build -var-file=variables.json db.json
```
Будут созданы образы в YC, их необходимо переименовать в YC *reddit-app-base-ansible* и *reddit-db-base-ansible* (в файлах packer имя образа reddit-app-base-{{timestamp}}, чтобы каждый раз оно было разным и образ не нужно было удалять при повторном запуске сборки образа).

**Создать ВМ**

Перейти в каталог terraform/stage и выполнить команду в терминале
```
terraform init
terraform plan
terraform apply
```
На основе созданных образов будут созданы 2 ВМ в YC.

**Деплой приложения**

Заменить IP ВМ на актуальные в файлах inventory.yml и в app.yml заменить значение переменной *db_host* на актуальный внутренний адрес ВМ с базой данных
Перейти в директорию *ansible* и выполнить команду в терминале
```
ansible-playbook site.yml
```

В результате приложение будет доступно по адресу <Внешний IP reddit-app-stage>:9292

## Домашняя работа №12

Создал с помощью ansible-galaxy init структуру каталогов для ролей stage и прод.
```
ansible-galaxy init app
ansible-galaxy init db
```
Распределил по директориям файлы шаблонов и файлов конфигураций. Из playbook перенес раздел tasks в директорию tasks.
Поэтому в модулях не нужно указывать полный путь к шаблонам и файлам, а достаточно имени. Хендлеры и переменные также выносятся в отдельную директорию. В плейбуках app и db указываем только необходимые роли.

Далее настраиваем файлы для разных окружений (prod и stage). Для каждого окружения создадим свой инвентори файл. В файл конфигурации запишем путь к stage инвентори. В каждом окружении создал директорию group_vars. В нем создаём файлы с переменными.

Добавил роль из ansible-galaxy jdauphant.nginx. Добавил переменные в group_vars
```
nginx_sites:
default:
- listen 80
- server_name "reddit"
- location / {
proxy_pass http://127.0.0.1:порт_приложения;
}
```
Добавил роль jdauphant.nginx в плайбук app.

**Работа с Ansible Vault**

Создал файл vault.key с помощью команды
```
md5sum ansible.cfg | awk '{print $1}' > vault.key
```
Добавил плейбук для создания пользователей и создал файл с данными пользователей credentials.yml
Зашифровал файл с помощью ansible-vault.
```
ansible-vault encrypt environments/prod/credentials.yml
ansible-vault encrypt environments/stage/credentials.yml
```

### Проверка
Скачать данный репозиторий
```
git clone git@github.com:Otus-DevOps-2020-11/parshyn-dima_infra.git
```
Перейти в каталог parshyn-dima_infra
Ввести в файлах prod/key.json.example, prod/terraform.tfvars.example, stage/key.json.example, stage/terraform.tfvars.example, packer/variables.json.example, packer/key.json.example изменений согласно вашей конфигурации YandexCloud. Измени файл vault.key.example с помощью которого будем шифровать. Все файлы с example необходимо переименовать, убрав .example

**Создать ВМ**
Перейти в каталог terraform/stage и выполнить команду в терминале
```
terraform init
terraform plan
terraform apply
```
На основе созданных образов будут созданы 2 ВМ в YC.

**Шифрование файлов с паролями**

Заменить файл ansible/environments/stage/credentials.yml на файл вида
```
credentials:
users:
admin:
password: admin123
groups: sudo
```
Зашифровать можно с помошью команд
```
ansible-vault encrypt environments/prod/credentials.yml
ansible-vault encrypt environments/stage/credentials.yml
```

**Деплой приложения**

Заменить IP ВМ на актуальные в файлах inventory.yml и в app.yml заменить значение переменной *db_host* на актуальный внутренний адрес ВМ с базой данных
Перейти в директорию *ansible* и выполнить команду в терминале
```
ansible-playbook site.yml
```
В результате приложение будет доступно по адресу <Внешний IP reddit-app-stage>:9292

## Домашняя работа №13

### Vagrantfile

Создал ansible/Vagrantfile. Команды для работы с vagrant
```
vagrant up - создание ВМ
vagrant box list
vagrant status - список запущенных ВМ
vagrant ssh appserver - подключение к ВМ appserver
```

### Провиженеры

Добавил провиженер в Vagrantfile для DB.
Запуcтил провиженер
```
vagrant provision dbserver
```
Добавил плейбук base.yml, в котором описал установку python. И добавил его в site.yml. (Все работало и без этого плейбука)
Добавил файл db/tasks/install_mongo.yml, перенес в него таски установки MongoDB из packer_db.yml. Добавил тег **install_mongo**. В файл db/tasks/config_mongo.yml добавил таску с настройкой конфига MongoDB.
Аналогичные действия выполним и для роли app. В app/tasks/ruby.yml перенес таски относящиеся к установке ruby. В app/tasks/puma.yml относящиеся к установке puma server.
Добавил провиженер в Vagrantfile для APP.
Параметризировал конфигурацию, чтобы мы могли использовать ее для другого пользователя, не appuser. То есть во всех файлах заменил **ubuntu** на **{{ deploy_user }}**.
Так как плейбуки выполняются из-под пользователя vagrant, поэтому в vagrantfile прописал
```
ansible.extra_vars = {
          "deploy_user" => "vagrant"
        }
```
### Задание со *

Для передачи параметров nginx в роли jdauphant.nginx  есть два способа:
1. Добавить в Vagrantfile
```
ansible.extra_vars = {
          "deploy_user" => "vagrant",
          nginx_sites: {
          default: ["listen 80", "server_name 'reddit'", "location / {proxy_pass http://127.0.0.1:9292;}"]
        }
```
2. Добавить в app/vars/main.yml
```
nginx_sites:
  default:
  - listen 80
  - server_name "reddit"
  - location / {
      proxy_pass http://127.0.0.1:9292;
    }
```
В итоге при выполнение *vagrant up* бедут созданы две ВМ (db и app). Для доступа к тестовому приложениею необходимо в баузере ввести **http://192.168.56.120/**

### Тестирование роли

Для тестирования ролей ansible необходимо установить Molecule, Ansible, Testinfra. Рекомендуется все работы по тестированию проводить в virtualenv.
Команды выполняются в каталоге проекта. Использовал следующие версии приложений
molecule 3.2.3 using python 3.9
ansible:2.10.5
delegated:3.2.3 from molecule
vagrant:0.6.1 from molecule_vagrant
```
pip install virtualenv
virtualenv venv
source venv/bin/activate
pip install -r ansible/requirements.txt
python -m pip install --upgrade pip
pip install molecule-vagrant
pip install 'molecule_vagrant'
```

Для создания тестов необходимо инициализировать molecule
```
cd ansible/roles/db/
molecule init scenario default --role-name db -d vagrant
molecule test
molecule destroy
molecule list
```

Откорректировал db/molecule/default/molecule.yml. Так в методичке описана molecule v2, столкнулся с проблемой несоответствия синтаксиса для v3.
Линтеры должны быть списком и в verifier необходимо указать путь к директории с тестами на python
```
lint: |
  yamllint .
  ansible-lint
  flake8
verifier:
  name: testinfra
  directory: ./tests/
```
Используемые команды
```
molecule create -создать VM для проверки роли
molecule list
molecule login -h instance
molecule converge - вызывается наша роль к  созданному хосту
molecule verify
```

### Самостоятельно

В файл test_default.py добавил проверку доступности порта 27017.
В провиженерах packer изменил путь к плайбукам. Добавил теги  по которым необходимо устанавливать необходимые таски. Также добавил путь к ролям ansible.
Столкнулся с проблемой, что запускать сборку образов необходимо с корня проекта, когда запускал непосредственно из директории packer, при сборке была ошибка об невозможности найти директорию с ролями.
Сборка новых образов
```
packer build -var-file=./packer/variables.json ./packer/db.json
packer build -var-file=./packer/variables.json ./packer/app.json
```
