# barmank32_infra
barmank32 Infra repository
# ДЗ № 3 стр 12
Для подключения к удаленному серверу через Bastion необходимо ввести, при этом SSH Agent Forwarding ненужен.
```bash
$ ssh -i ~/.ssh/appuser -J appuser@<Bastion IP> appuser@<Someinternalhost IP>
```
## Дополнительное задание:
Создаем конфигурационный файл SSH и устанавливаем ему права.
```bash
$ touch ~/.ssh/config && chmod 600 ~/.ssh/config
```
Добавляем в файл данные для соединения с сервером
```bash
$cat >> ~/.ssh/config << EOF
Host Bastion
    HostName 178.154.228.57
    User appuser
    IdentityFile ~/.ssh/appuser

Host someinternalhost
    HostName 10.130.0.31
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump Bastion
EOF
```
Осуществляем соединение
```bash
$ ssh someinternalhost
```
# ДЗ № 3 стр 15
```
bastion_IP = 178.154.228.57
someinternalhost_IP = 10.130.0.31
```
# ДЗ № 4
```
testapp_IP=178.154.228.131
testapp_port=9292
```
## Дополнительное задание
```bash
$ yc compute instance create \
  --zone ru-central1-a \
  --core-fraction 5 \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=./metadata.yaml
```
# ДЗ № 5
## Установка Packer на Ubuntu
```bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install packer
```
проверка установки
```bash
$ packer -v
```
## Создание сервисного аккаунта для Packer
смотрим параметры
```bash
$ yc config list
$ SVC_ACCT="<придумываем>"
$ FOLDER_ID="<заменить на собственный>"
$ yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
$ ACCT_ID=$(yc iam service-account get $SVC_ACCT | grep ^id | awk '{print $2}')
$ yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
```
Создаем ключ, он должен хранится за пределами репозитория
```bash
$ yc iam key create --service-account-id $ACCT_ID --output key.json
```
## Создаем ubuntu16.json и variables.json для запекания образа
Проверка на ошибки
```bash
$ packer validate -var-file=variables.json ./ubuntu16.json
```
Создаем образ
```bash
$ packer build -var-file=variables.json ./ubuntu16.json
```
## Задание*
Создаем `immutable.json` для запекания образа с приложением<br>
Создаем `puma.service` для Systemd<br>
Создаем образ
```bash
$ packer build -var-file=variables.json ./immutable.json
```
Запускаем create-reddit-vm.sh для создания ВМ
# ДЗ № 6
## Установка Terraform на Ubuntu
```bash
$ sudo app install terraform=0.12.26
```
Заносим в `.gitignore`
```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```
## Terraform init
Создаем main.tf основной файл с кодом terraform
Добавляем секцию Provider которая  позволит  Terraform  управлять  ресурсами через  API
```
provider "yandex" {
  # yc config list
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```
Для загрузки модуля провайдера terraform выполняем
```bash
$ terraform init
```
## Terraform resource
Дополняем main.tf ресурсом
```
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      # yc compute image list
      image_id = "fd8fg4r8mrvoq6q2ve76"
    }
  }

  network_interface {
    # yc vpc subnet list
    subnet_id = "e9bem33uhju28r5i7pnu"
    nat       = true
  }
}
```
Просмотреть вносимые изменения
```bash
$ terraform plan
```
Знак  "+"  перед  наименованием  ресурса  означает,  что  ресурс будет добавлен<br>
Создаем ресурсы согласно плана
```bash
$ terraform apply
-auto-approve для автоподтверждения
```
Для подключения к ВМ добавляем metadata с ключём
```
resource "yandex_compute_instance" "app" {
...
  metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/yc.pub")}"
  }
...
}
```
Удаляем и создаем заново ресурс
``` bash
$ terraform destroy
$ terraform apply
```
## Terraform provisioner
Provisioners  в  terraform  вызываются  в  момент  создания/удаления ресурса и позволяют выполнять команды на удаленной или локальной машине. Их используют для запуска инструментов управления конфигурацией или начальной настройки системы.
```
connection {
  # параметры подключения
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/yc")
  }
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
```
## Input vars
Создаем файл variables.tf с содержанием
```
variable cloud_id{
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable image_id {
  description = "Disk image"
}
variable subnet_id{
  description = "Subnet"
}
variable service_account_key_file{
  description = "key .json"
}
```
Теперь можем использовать input переменные в определении других ресурсов.Чтобы получить значение пользовательской переменной внутри ресурса используется синтаксис `var.var_name`.<br>
Определим переменные используя специальный файл `terraform.tfvars`, из которого тераформ загружает значения автоматически при каждом запуске.
```
cloud_id = "b1g7mh55020i2hpup3cj"
folder_id = "b1g4871feed9nkfl3dnu"
zone = "ru-central1-a"
image_id = "fd8mmtvlncqsvkhto5s6"
public_key_path = "~/.ssh/yc.pub"
subnet_id = "e9bem33uhju28r5i7pnu"
service_account_key_file = "key.json"
```

## Output vars

Создаем файл outputs.tf с содержанием
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
  }
```
Используем команду
`terraform refresh`, чтобы выходная переменная приняла значение.<br>
Значение выходных переменных можно посмотреть, используя команду `terraform output`.

## Задание*
При настройке балансировщика как ниже, проблема возникает при горизонтальном масштабировании ресурсов, из-зи того что приходиться копировать много однотипного кода.
```
# lb.tf

resource "yandex_lb_target_group" "app_group" {
  name      = "app-target-group"
#   region_id = "ru-central1"

  target {
    subnet_id = var.subnet_id
    address   = yandex_compute_instance.app.network_interface.0.ip_address
  }

    target {
    subnet_id = var.subnet_id
    address   = yandex_compute_instance.app2.network_interface.0.ip_address
  }
}

resource "yandex_lb_network_load_balancer" "lb-app" {
  name = "lb-app"

  listener {
    name = "my-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_group.id
    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
```
```
# outputs.tf
output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}

output "balancer_ip_address" {
  value = [for ex_ip in yandex_lb_network_load_balancer.lb-app.listener: ex_ip.external_address_spec].0
}
```
## Задание**
При использовании параметра count, наращивание мощности производится путем увеличения числа.
```
# lb.tf

resource "yandex_lb_target_group" "app_group" {
  name = "app-target-group"

  dynamic "target" {
    for_each = [for s in yandex_compute_instance.app : {
      address = s.network_interface.0.ip_address
      subnet_id = s.network_interface.0.subnet_id
    }]

    content {
      subnet_id = target.value.subnet_id
      address   = target.value.address
    }
  }
}

resource "yandex_lb_network_load_balancer" "lb-app" {
  name = "lb-app"

  listener {
    name = "my-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_group.id
    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
```
# ДЗ № 7
## VPC Network
Определяем ресурсы `yandex_vpc_network` и `yandex_vpc_subnet` в конфигурационном файле `main.tf`.
```
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
Переопределяем интерфейс ВМ на новый ресурс
```
  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
```
## Несколько VM
Создаем с помощью Packer два образа один с Ruby другой с MangoDB.<br>
Разделяем main.tf на на несколько конфигов.
- main.tf - остается секция provider
- app.tf - ВМ с образом Ruby
- db.tf - ВМ с образом MongoDB
- vpc.tf - ресурс Yandex VPC

Проверяем `terraform apply`.
## Модули
Модули используются для шаблонизации ВМ с разных проектах.<br>
Создаем папки для модулей
- modules/db/
- modules/app/

Со следующей структурой
- main.tf - описание ресурса ВМ
- variables.tf - input vars
- outputs.tf - output vars

Приведем основной файлы к следующему виду
```
# main.tf
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
module "app" {
  source          = "./modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "./modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = var.subnet_id
}
```
```
# outputs.tf
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
```
Файлы `db.tf` `app.tf` `vpc.tf` больше не нужны.<br>
Проверяем `terraform plan` и применяем `terraform apply` конфигурацию.
## Задание*
Для хранения tfstate информации в Yandex Object Storage.
```
# backend.tf
terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket   = "terraform-object-storage-barmank32"
    region   = "us-east-1"
    key      = "prod.tfstate"

    access_key = "Yr_cAJ5scJDdtYhwhLOe"
    secret_key = "PtNIbknOxAkM7iaLrnzKdqTRnJX5MUQjmSrUaH5q"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```
Для работы блокировки необходимо использовать DynamoDB которая на Yandex тока реализовывается в виде Yandex Database. Опции отвечающие за блокировку `dynamodb_endpoint` и `dynamodb_table`.
## Задание**
Для подключения к БД вносим следующие исправления
```
# module app
...
connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.privat_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "../files/deploy.sh"
  }
  depends_on = [local_file.generate_service]
  ...
  resource "local_file" "generate_service" {
  content = templatefile("${path.module}/puma.tpl", {
    addrs = var.db_url,
  })
  filename = "${path.module}/puma.service"
}
```
Создается `puma.service` имеющий строчку `Environment="DATABASE_URL=${addrs}"` для указания IP DB через окружение.
```
# module db
...
  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.privat_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }
...
```
Изменяется конфигурационные файл для того чтобы сервис слушал подключения ч внешних адресов.<br>
Незабываем прокидывать соответствующие Variables.
# ДЗ № 8
## Ansible
Установка Ansible
```
pip install ansible>=2.4
```
Создаем ВМ с помощью Terraform `terraform apply` из папки stage.<br>
Создадим инвентори файл ansible/inventory.
```
appserver ansible_host=35.195.186.154 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
```
проверка сервера
```
$ ansible appserver -i ./inventory -m ping
```
## ansible.cfg
Укажем значения по умолчанию для работы Ansible.
```
# ansible/ansible.cfg
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```
Теперь можно удалить лишние параметры из инвентори файла.
## Выполнение команд
Выполнить команду на сервере можно с помощью модуля `command`, он выполняет команды не используя Shell.
```
$ ansible app -m command -a 'ruby -v'
```
Выполнить команду на сервере можно с помощью модуля `shell`.
```
$ ansible app -m shell -a 'ruby -v; bundler -v'
```
Модуль `systemd` предназначен для управления сервисами.
```
$ ansible db -m systemd -a name=mongod
```
Или еще лучше с помощью модуля `service`, который болееуниверсален  и  будет  работать  и  в  более  старых  ОС.
```
$ ansible db -m service -a name=mongod
```
Модуль git  для  клонирования  репозитория  с приложением на app сервер.
```
ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
```
## Напишем простой плейбук
```
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit
```
И выполните: `ansible-playbook clone.yml`
# ДЗ № 9
## Один playbook, один сценарий
Создадим плейбук таким образом, чтобы получился один play c множеством tasks с tags.
```
---
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 10.130.0.6
  tasks:
    - name: Change mongo config file
      become : true
      template:
        src : templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      tags: db-tags
      notify: restart mongod

    - name: APT Install
      become : true
      apt:
        name: git
        state: present
        update_cache: yes
      tags: deploy-tag

    - name: Add unit file for Puma
      become : true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma
...
  handlers:
  - name: restart mongod
    become : true
    service: name=mongod state=restarted
  - name: reload puma
    become : true
    service: name=puma state=restarted
```
чтобы работать с таким playbook необходимы команды следующего вида:
```
$ ansible-playbook reddit_app.yml --limit db --tags db-tag
$ ansible-playbook reddit_app.yml --limit app --tags app-tag
$ ansible-playbook reddit_app.yml --limit app --tags deploy-tag
```
также можно использовать ключ `--check` для выполнения сценария без его применения.
## Один плейбук, несколько сценариев
Создадим плейбук таким образом, чтобы получился несколько play.
```
---
- name: Configure MongoDB
  hosts: db
  become : true
  tags: db-tag
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src : templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure app
  hosts: app
  become : true
  tags: app-tag
  vars:
   db_host: 10.130.0.33
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted

- name: deploy application
  hosts: app
  tags: deploy-tag
  tasks:
    - name: APT Install
      become : true
      apt:
        name: git
        state: present
        update_cache: yes

    - name: Fetch the latest version of application code
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit

  handlers:
  - name: reload puma
    become : true
    systemd: name=puma state=restarted
```
чтобы работать с таким playbook необходимы команды следующего вида:
```
$ ansible-playbook reddit_app2.yml --tags db-tag
$ ansible-playbook reddit_app2.yml --tags app-tag
$ ansible-playbook reddit_app2.yml --tags deploy-tag
```
В таком виде playbook проще управлять, так как не надо запоминать к какой групп серверов относится тег.
## Несколько плейбуков
Разделим предыдущий playbook и занесем каждый play в отдельный файл.<br>
Создадим еще один файл с import_playbook.
```
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```
теперь можно одним файлом запустить все сценарии.
## Интегрируем Ansible в Packer
Заменим секцию Provision в Packer на Ansible:
```
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_app.yml"
        }
    ]
```
# ДЗ № 10
[![Build Status](https://travis-ci.com/barmank32/trytravis_infra.svg?branch=ansible-3)](https://travis-ci.com/barmank32/trytravis_infra)
