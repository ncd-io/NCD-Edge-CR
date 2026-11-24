#!/bin/bash

# Recovers the firewall on gateways that were updated to RobustOS Pro 2.4.1 or
# later while the ETH0 firewall zone was still named ETH0_CLIENT.
#
# Firmware 2.4.1+ limits firewall zone names to 10 characters. ETH0_CLIENT is 11,
# so on the first boot after the update the firmware rejects the zone and resets
# the whole firewall section to its stock settings: the zone, its forward and
# traffic rules are gone and the input policy becomes accept. The ETH0 WAN link
# keeps pointing at the old zone name.
#
# This script renames the zone to ETH0_CLNT in the default config, reloads the
# firewall section from that default config, points the WAN link at the new
# zone name, and enables SSH access on the zone. It is safe to run more than once.
#
# The firewall settings go back to the NCD defaults, except that SSH access on
# the ETH0 zone is turned on. Other changes made to the firewall after the
# gateway was shipped (ping access on a zone, added rules) must be made again in
# the web interface.
#
# Usage: sudo bash ./fix-firewall-zone.sh

OLD_ZONE="ETH0_CLIENT"
NEW_ZONE="ETH0_CLNT"
DEFAULT_XML="/app/config/default.xml"
IMPORT_XML="/tmp/fix-firewall-zone.xml"
MAX_ENTRIES=50

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root: sudo bash ./fix-firewall-zone.sh"
    exit 1
fi

if ! command -v uci >/dev/null 2>&1 || [ ! -f "$DEFAULT_XML" ]; then
    echo "uci or $DEFAULT_XML was not found. This script only runs on the gateway."
    exit 1
fi

# uci prints "fail" when a tag does not exist
uci_get() {
    local value
    value=$(uci get "$1" 2>/dev/null | head -n 1)
    if [ -z "$value" ] || [ "$value" = "fail" ]; then
        return 1
    fi
    echo "$value"
}

# Prints the index of the first entry of list $1 whose field $2 equals $3
find_entry() {
    local i
    for ((i = 1; i <= MAX_ENTRIES; i++)); do
        if [ "$(uci_get "$1[$i].$2")" = "$3" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# 1. Default config, so a later "restore to default" does not break the zone again
if grep -q -e "$OLD_ZONE" -e '<max_station_num>64</max_station_num>' "$DEFAULT_XML"; then
    echo "Updating $DEFAULT_XML"
    cp -p "$DEFAULT_XML" "$DEFAULT_XML.bak-zone-fix"
    sed -i -e "s/$OLD_ZONE/$NEW_ZONE/g" \
        -e 's#<max_station_num>64</max_station_num>#<max_station_num>8</max_station_num>#' "$DEFAULT_XML"
fi

# 2. Find the WAN link that uses the zone
link=$(find_entry wan_links.link firewall_zone "$OLD_ZONE") || link=$(find_entry wan_links.link firewall_zone "$NEW_ZONE")
if [ -z "$link" ]; then
    echo "No WAN link uses $OLD_ZONE or $NEW_ZONE. Nothing to recover."
    exit 0
fi

if [ "$(uci_get "wan_links.link[$link].firewall_zone")" = "$NEW_ZONE" ] && find_entry firewall.zone_list name "$NEW_ZONE" >/dev/null; then
    echo "Firewall zone $NEW_ZONE is already in place. No changes made."
    exit 0
fi

# 3. Reload the firewall section from the default config if the zone is missing
if ! find_entry firewall.zone_list name "$NEW_ZONE" >/dev/null; then
    if ! grep -q "<name>$NEW_ZONE</name>" "$DEFAULT_XML"; then
        echo "$DEFAULT_XML has no $NEW_ZONE zone. Cannot recover the firewall from it."
        exit 1
    fi
    echo "Reloading the firewall section from $DEFAULT_XML"
    {
        echo '<?xml version="1.0"?>'
        echo '<config_xml>'
        awk '/^  <firewall>$/,/^  <\/firewall>$/' "$DEFAULT_XML"
        echo '</config_xml>'
    } > "$IMPORT_XML"
    if ! uci import "$IMPORT_XML" >/dev/null 2>&1; then
        echo "Importing the firewall section failed"
        rm -f "$IMPORT_XML"
        exit 1
    fi
    rm -f "$IMPORT_XML"
fi

# 4. SSH access on the zone
# A zone that was just imported cannot be read back until it is committed, so
# fall back to its id in the default config
zone=$(find_entry firewall.zone_list name "$NEW_ZONE") ||
    zone=$(grep -B1 "<name>$NEW_ZONE</name>" "$DEFAULT_XML" | sed -n 's#.*<id>\([0-9]*\)</id>.*#\1#p' | head -n 1)
if [ -z "$zone" ]; then
    echo "Could not find the $NEW_ZONE zone entry"
    exit 1
fi
echo "Enabling SSH access on the $NEW_ZONE zone (ETH0)"
if ! uci set "firewall.zone_list[$zone].ssh_access" true >/dev/null 2>&1; then
    echo "Failed to enable SSH access on the zone"
    exit 1
fi

# 5. WAN link
echo "Pointing WAN link $link at $NEW_ZONE"
if ! uci set "wan_links.link[$link].firewall_zone" "$NEW_ZONE" >/dev/null 2>&1; then
    echo "Failed to set the WAN link firewall zone"
    exit 1
fi

echo "Saving and applying"
if ! uci commit >/dev/null 2>&1; then
    echo "uci commit failed"
    exit 1
fi

if [ "$(uci_get "wan_links.link[$link].firewall_zone")" = "$NEW_ZONE" ] && find_entry firewall.zone_list name "$NEW_ZONE" >/dev/null; then
    echo "Done. The firewall is back to the NCD defaults with the zone named $NEW_ZONE."
    echo "SSH access on ETH0 has been enabled. It can be turned off on the firewall page in the web interface."
else
    echo "The zone could not be verified after applying. Check the firewall page in the web interface."
    exit 1
fi
