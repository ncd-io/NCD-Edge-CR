# Updating the NCD Enterprise Gateway to RobustOS Pro 2.4.1 or later

This guide covers the firmware update for the NCD Enterprise Gateway (Robustel EG5120) from RobustOS Pro 2.3.0 to 2.4.1 or later, including 2.5.0.

There is one change to make **before** you update. If the update has already been installed without it, use the [recovery steps](#recovery-if-the-update-was-installed-first) below.

## Why a change is needed

Firmware 2.4.1 and later limits firewall zone names to 10 characters. NCD gateways ship with a zone named `ETH0_CLIENT`, which is 11.

If the gateway is updated while the zone still has that name, the new firmware rejects it on first boot and resets the whole firewall to stock settings:

- The `ETH0_CLIENT` zone, its forwarding entry, and the rules that allow Node-RED (port 1880) and mDNS (port 5353) on ETH0 are removed.
- The firewall input policy changes from drop to accept. **Until this is fixed, the ETH0 port accepts all incoming connections.**
- The web interface keeps showing unsaved changes after every reboot.

Renaming the zone to `ETH0_CLNT` before the update avoids all of this.

## Standard update path

Do these steps on the current firmware, before installing the update.

### 1. Rename the firewall zone

1. Log in to the gateway's web interface in a browser.
2. Go to **Network > Firewall**.
3. Click the edit button next to `ETH0_CLIENT`.
4. In the dialog that opens, change the **Name** field to `ETH0_CLNT`.
5. Click **Submit** in the dialog.
6. Click the **Save and Apply** button in the header at the top of the page. It looks like a red checkbox.

### 2. Check the ETH0 link

Go to **Network > WAN**. The Ethernet line in the table should now show `ETH0_CLNT` in the **Firewall Zone** column.

### 3. Set the Wi-Fi client limit to 8

The new firmware allows at most 8 clients on the gateway's Wi-Fi access point.

1. Go to **Interface > Wifi**.
2. Click the **VAP Settings** tab.
3. Click the edit icon next to the VAP in the table. A dialog opens.
4. Scroll to the bottom and change **Max Associated Stations** to `8`.
5. Click **Submit**. The dialog closes.
6. Click the **Save and Apply** button in the header at the top of the page. It looks like a red checkbox.

Repeat these steps for every VAP in the table. The default configuration has only one.

### 4. Save the current settings as the new defaults

Do this only after the changes above are saved and applied and the WAN page shows the new zone name.

1. Go to **System > Profile**.
2. Under **Default Configuration**, click the **Save** button next to **Save Running Configuration as Default**.

This makes sure a later "restore to default" brings back the new zone name and Wi-Fi limit, not the old ones.

### 5. Install the firmware update

1. Download firmware version 2.5.0 for the EG5120 from Robustel: <https://support.robustel.com/portal/en/kb/articles/eg5120-firmware-download>
2. On the gateway, go to **System > App Center**.
3. Under **App Install**, upload the firmware file.
4. Click **Install**.
5. Reboot the gateway after the install finishes.

### 6. Check the result

After the reboot:

- **Network > Firewall** lists the `ETH0_CLNT` zone.
- **Network > WAN** still shows `ETH0_CLNT` in the **Firewall Zone** column of the Ethernet line.
- The web interface does not show unsaved changes after a reboot.

## Recovery if the update was installed first

Use this if the gateway was updated while the zone was still named `ETH0_CLIENT`.

### How to tell

- **Network > Firewall** no longer lists an ETH0 zone, only `external` and `internal`.
- The web interface shows unsaved changes that come back after every save and reboot.

In this state the ETH0 port accepts all incoming connections. Run the recovery as soon as you can.

### What you need

- The `fix-firewall-zone.sh` script. NCD provides this script on request.
- SSH access to the gateway with a user that can run `sudo`.

### Steps

1. Copy the script to the gateway. Replace `<user>` and `<gateway-ip>` with your own values:

   ```bash
   scp fix-firewall-zone.sh <user>@<gateway-ip>:~
   ```

2. Connect to the gateway:

   ```bash
   ssh <user>@<gateway-ip>
   ```

3. Run the script:

   ```bash
   sudo bash ./fix-firewall-zone.sh
   ```

   A successful run prints:

   ```
   Updating /app/config/default.xml
   Reloading the firewall section from /app/config/default.xml
   Enabling SSH access on the ETH0_CLNT zone (ETH0)
   Pointing WAN link 2 at ETH0_CLNT
   Saving and applying
   Done. The firewall is back to the NCD defaults with the zone named ETH0_CLNT.
   SSH access on ETH0 has been enabled. It can be turned off on the firewall page in the web interface.
   ```

4. Reboot the gateway and confirm the items under [Check the result](#6-check-the-result).

The script is safe to run more than once. If the firewall is already correct it prints `No changes made.` and exits.

### What the script changes

- **Default configuration:** renames the zone to `ETH0_CLNT` and sets the Wi-Fi client limit to 8. The previous file is kept as `/app/config/default.xml.bak-zone-fix`.
- **Firewall:** restores the NCD default firewall, with the zone named `ETH0_CLNT`.
- **ETH0 link:** points it at the `ETH0_CLNT` zone.
- **SSH:** turns on SSH access on the ETH0 zone. You can turn it off again under **Network > Firewall**.

No settings outside the firewall and the ETH0 link's zone are changed.

### After the recovery

The firewall is back to the NCD defaults. If you had made your own firewall changes, such as extra rules or ping access on a zone, make them again in the web interface.

## Support

If the script reports an error, or the firewall page does not look right after the reboot, contact NCD support with the script's output.
