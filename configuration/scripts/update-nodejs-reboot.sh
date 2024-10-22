#!/bin/bash

# Set the version to the argument provided, or to "16.19.1" if no argument is provided
version=${1:-"20.18.0"}

cd ~
sudo npm install -g n
sudo n $version
n prune
sudo n prune
sudo reboot
