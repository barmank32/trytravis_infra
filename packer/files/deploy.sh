#!/bin/bash -e

echo "Update"
        apt update

echo "Install Ruby"
        apt-get install -y git

echo "Copy app"
        cd ~
        git clone -b monolith https://github.com/express42/reddit.git

echo "Build app"
	cd reddit && bundle install

echo "SystemD"
        curl raw | cat > /etc/systemd/system/puma.service
        systemctl start puma
	systemctl enable puma
	systemctl status puma
