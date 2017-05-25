#!/bin/sh

sudo parted "$1" mklabel gpt
sudo parted -a minimal "$1" mkpart primary ext4 1MiB '100%'
sudo parted "$1" name 1 "data"
sudo mkfs.ext4 -F -L "" "$1"1
