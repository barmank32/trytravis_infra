#!/bin/bash -e

yc compute instance create \
  --zone ru-central1-a \
  --core-fraction 5 \
  --name reddit-vm \
  --hostname reddit-vm \
  --memory=4 \
  --create-boot-disk image-family=reddit-full,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata-from-file user-data=./metadata2.yaml
