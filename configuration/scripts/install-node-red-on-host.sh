#!/bin/bash

version=${1:-@latest}

cd ~

sudo npm install -g --unsafe-perm node-red${version}
cd ~/.node-red
npm install ncd-red-wireless-2
npm install node-red-dashboard
# sudo reboot
