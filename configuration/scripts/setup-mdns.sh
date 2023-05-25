#!/bin/bash

script_text='#!/bin/bash

bridge_nic="br_lan"
mac=$(ip addr show $bridge_nic | awk '\''/ether/ {print $2}'\'' | awk -F: '\''{print $(NF-1)$NF}'\'')

avahi-set-host-name ncd-$mac'

service_text='[Unit]
Description=NCD Avahi Util
After=network-online.target

[Service]
ExecStart=/bin/ncd-mdns

[Install]
WantedBy=multi-user.target'

ncd_mdns_path="/bin/ncd-mdns"
ncd_avahi_service_path="/etc/systemd/system/ncd-avahi.service"

# Create or overwrite /bin/ncd-mdns
sudo touch "$ncd_mdns_path"
echo "$script_text" | sudo tee "$ncd_mdns_path" > /dev/null
sudo chmod +x "$ncd_mdns_path"
echo "Script has been written to $ncd_mdns_path."

# Create or overwrite /etc/systemd/system/ncd-avahi.service
sudo touch "$ncd_avahi_service_path"
echo "$service_text" | sudo tee "$ncd_avahi_service_path" > /dev/null
echo "Service file has been written to $ncd_avahi_service_path."
