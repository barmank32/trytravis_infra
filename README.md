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
