#!/bin/bash

nodeRedCommand=$(which node-red)

if [ -z "$nodeRedCommand" ]; then
  echo "Error: node-red command not found. Install Node-Red."
  exit 1
fi

sudo npm install -g pm2

pm2 start $nodeRedCommand -- -v
pm2 save
pm2 startup systemd
sudo env PATH=$PATH:/usr/local/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u ncdio --hp /home/ncdio

pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:compress false
pm2 set pm2-logrotate:retain 14
pm2 set pm2-logrotate:workerInterval 600
pm2 set pm2-logrotate:rotateInterval '0 0 * * *'

sudo reboot
