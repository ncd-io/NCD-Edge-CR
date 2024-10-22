#!/bin/bash

#version=${1:-@latest}

cd ~

sudo npm install -g --unsafe-perm node-red@4.0.5

# run node-red in background to initialize ~/.node-red/package.json in order to install libraries
node-red &
# sleep for 10 seconds to make sure it initialized
sleep 10

cd ~/.node-red
npm install @ncd-io/node-red-enterprise-sensors
npm install @flowfuse/node-red-dashboard

sudo reboot
