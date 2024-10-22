#!/bin/bash

# Get the username argument or default to "ncdio"
username=${1:-ncdio}

sudo apt update
sudo apt-get install -y avahi-utils
sudo apt-get install -y nano

sudo bash ./setup-mdns.sh

# Run the install-docker.sh script
# sudo bash ./ncd-install-docker.sh

# Run the add-user-to-groups.sh script, passing in the username argument
sudo bash ./set-user-permissions.sh $username
