#!/bin/bash

sudo apt update
sudo apt-get install -y avahi-utils
sudo apt-get install -y nano

sudo bash ./setup-mdns.sh
