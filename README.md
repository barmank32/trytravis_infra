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
    HostName Bastion
    User appuser
    IdentityFile ~/.ssh/appuser

Host someinternalhost
    HostName someinternalhost
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyJump Bastion
EOF

Осуществляем соединение
$ ssh someinternalhost
