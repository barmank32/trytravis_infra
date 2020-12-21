#!/bin/bash -e

echo "Update"
	apt-get update -y
	sleep 10

echo "Install Ruby"
	apt-get install -y ruby-full ruby-bundler build-essential

echo "Check install"
	ruby -v
	bundler -v
