# barmank32_infra
barmank32 Infra repository

ДЗ № 4 стр 12

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

ДЗ № 4 стр 15

bastion_IP = 178.154.228.57
someinternalhost_IP = 10.130.0.31
