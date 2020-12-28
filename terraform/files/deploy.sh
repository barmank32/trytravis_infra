#!/bin/bash -e

APP_DIR=${1:-$HOME}

echo "Update"
        sudo apt update
        sleep 10

echo "Install Ruby"
        sudo apt-get install -y git

echo "Copy app"
        git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit

echo "Build app"
	cd $APP_DIR/reddit && bundle install

echo "SystemD"
        sudo mv /tmp/puma.service /etc/systemd/system/puma.service
        sudo systemctl start puma
	sudo systemctl enable puma
