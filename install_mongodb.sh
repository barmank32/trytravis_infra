#!/bin/bash

echo "Add repo"
	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

echo "Update"
	sudo apt update

echo "Install Ruby"
	sudo apt-get install -y mongodb-org

echo "Check install"
	sudo systemctl start mongod
	sudo systemctl enable mongod
	sudo systemctl status mongod
