#!/bin/bash -e
echo "Update"
	apt-get update -y
	sleep 10

echo "Fix apt https"
	apt-get install -y apt-transport-https ca-certificates

echo "Add repo"
	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
	echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list

echo "Update"
	apt-get update -y

echo "Install Ruby"
	apt-get install -y mongodb-org

echo "Check install"
	systemctl start mongod
	systemctl enable mongod
	systemctl status mongod
