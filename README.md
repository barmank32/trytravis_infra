# barmank32_infra
barmank32 Infra repository

ДЗ № 3 стр 12

Для подключения к удаленному серверу через Bastion необходимо ввести, при этом SSH Agent Forwarding ненужен.

$ ssh -i ~/.ssh/appuser -J appuser@<Bastion IP> appuser@<Someinternalhost IP>

Дополнительное задание:

Создаем конфигурационный файл SSH и устанавливаем ему права.
$ touch ~/.ssh/config && chmod 600 ~/.ssh/config

Добавляем в файл данные для соединения с сервером
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

Осуществляем соединение
$ ssh someinternalhost

ДЗ № 3 стр 15

bastion_IP = 178.154.228.57
someinternalhost_IP = 10.130.0.31

ДЗ № 4

testapp_IP=178.154.228.131
testapp_port=9292

дополнительное задание

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

ДЗ № 5

Установка Packer на Ubuntu
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install packer

проверка установки
$ packer -v

Создание сервисного аккаунта для Packer

смотрим параметры
$ yc config list

$ SVC_ACCT="<придумываем>"
$ FOLDER_ID="<заменить на собственный>"
$ yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
$ ACCT_ID=$(yc iam service-account get $SVC_ACCT | grep ^id | awk '{print $2}')
$ yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
Создаем ключ, он должен хранится за пределами репозитория
$ yc iam key create --service-account-id $ACCT_ID --output key.json

Создаем ubuntu16.json и variables.json для запекания образа

Проверка на ошибки
$ packer validate -var-file=variables.json ./ubuntu16.json

Создаем образ
$ packer build -var-file=variables.json ./ubuntu16.json

Задание*
Создаем immutable.json для запекания образа с приложением
Создаем puma.service для Systemd

Создаем образ
$ packer build -var-file=variables.json ./immutable.json

Запускаем create-reddit-vm.sh для создания ВМ


# ДЗ № 6

Установка Terraform на Ubuntu
```bash
$ sudo app install terraform=0.12.26
```
Заносим в .gitignore
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
Теперь можем использовать input переменные в определении других ресурсов.Чтобы получить значение пользовательской переменной внутри ресурса используется синтаксис var.var_name.<br>
Определим переменные используя специальный файл terraform.tfvars,из которого тераформ загружает значения автоматически при каждом запуске.
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
```terraform refresh```, чтобы выходная переменная приняла значение.<br>
Значение выходных переменных можно посмотреть, используя команду ```terraform output```.
