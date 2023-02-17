#!/bin/bash

# Get the username argument or default to "ncdio"
username=${1:-ncdio}

# Add current user to docker group
sudo usermod -aG docker $username

# Add current user to dialout group
sudo usermod -a -G dialout $username
