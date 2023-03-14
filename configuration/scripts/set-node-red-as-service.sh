#!/bin/bash

nodeRedCommand=$(which node-red)

if [ -z "$nodeRedCommand" ]; then
  echo "Error: node-red command not found. Install Node-Red."
  exit 1
fi

pm2 start $nodeRedCommand -- -v
pm2 save
pm2 startup systemd
sudo env PATH=$PATH:/usr/local/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u ncdio --hp /home/ncdio
sudo reboot
