#!/bin/bash

echo "Update"
        sudo apt update

echo "Install Ruby"
        sudo apt-get install -y git

echo "Copy app"
        cd ~
        git clone -b monolith https://github.com/express42/reddit.git

echo "Build app"
	cd reddit && bundle install
	puma -d

echo "Check app"
	ps aux | grep puma
