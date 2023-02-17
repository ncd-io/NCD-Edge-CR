#!/bin/bash

# Get the username argument or default to "ncdio"
username=${1:-ncdio}

# Run the install-docker.sh script
sudo ./install-docker.sh

# Run the add-user-to-groups.sh script, passing in the username argument
sudo ./add-user-to-groups.sh $username
