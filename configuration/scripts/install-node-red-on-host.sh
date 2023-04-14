#!/bin/bash

version=${1:-@latest}

cd ~

sudo npm install -g --unsafe-perm node-red${version}
mkdir ~/.node-red
cd ~/.node-red
npm install @ncd-io/node-red-enterprise-sensors
npm install node-red-dashboard
# sudo reboot
