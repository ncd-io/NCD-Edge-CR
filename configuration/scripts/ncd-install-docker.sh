#!/bin/bash

# Download Docker installation script
sudo curl -fsSL get.docker.com -o get-docker.sh

# Run Docker installation script with Aliyun mirror
sudo sh get-docker.sh --mirror Aliyun
