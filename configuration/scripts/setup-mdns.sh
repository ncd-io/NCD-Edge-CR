#!/bin/bash

bridge_nic="br0"
mac=$(ip addr show $bridge_nic | awk '/ether/ {print $2}' | awk -F: '{print $(NF-1)$NF}')
echo "MAC address of $bridge_nic: $mac"

if [ ! -f "/bin/ncd-mdns" ]; then
    sudo touch /bin/ncd-mdns
    sudo sh -c "echo '#!/bin/bash' > /bin/ncd-mdns && echo 'avahi-set-host-name ncd-$mac' >> /bin/ncd-mdns && chmod +x /bin/ncd-mdns"
fi

if [ ! -f "/etc/systemd/system/ncd-avahi.service" ]; then
    sudo touch /etc/systemd/system/ncd-avahi.service
    sudo chmod 775 /etc/systemd/system/ncd-avahi.service
    sudo sh -c "echo '[Unit]' > /etc/systemd/system/ncd-avahi.service && echo 'Description=NCD Avahi Util' >> /etc/systemd/system/ncd-avahi.service && echo '' >> /etc/systemd/system/ncd-avahi.service && echo '[Service]' >> /etc/systemd/system/ncd-avahi.service && echo 'ExecStart=/bin/ncd-mdns' >> /etc/systemd/system/ncd-avahi.service && echo '' >> /etc/systemd/system/ncd-avahi.service && echo '[Install]' >> /etc/systemd/system/ncd-avahi.service && echo 'WantedBy=multi-user.target' >> /etc/systemd/system/ncd-avahi.service"
fi

sudo daemon-reload
sudo systemctl enable ncd-avahi
sudo systemctl start ncd-avahi
