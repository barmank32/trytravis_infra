#!/bin/bash

echo "Update"
	sudo apt update

echo "Install Ruby"
	sudo apt install -y ruby-full ruby-bundler build-essential

echo "Check install"
	ruby -v
	bundler -v
