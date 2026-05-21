#!/bin/bash

# Exit on error, undefined vars, and pipe failures; ensure traps fire in functions/subshells
set -Eeuo pipefail

# Static install path and owner for NCD edge gateways
NR_USER="ncdio"
NR_GROUP="ncdio"
NR_DIR="/home/ncdio/.node-red"

# Error handler for support
failure_handler() {
    local ec=$?
    local line=$1
    local cmd=$2
    echo -e "\n\033[0;31m##########################################################"
    echo "ERROR on line ${line} (exit ${ec}): ${cmd}"
    echo "The update failed."
    echo "Please COPY the entire terminal output and send it to us at https://ncd.io/contact-us/:"
    echo -e "##########################################################\033[0m\n"
}
trap 'failure_handler "$LINENO" "$BASH_COMMAND"' ERR

# Preflight: verify required tools are installed
for cmd in n npm pm2 sudo; do
    command -v "$cmd" >/dev/null || { echo "ERROR: required command '$cmd' not found in PATH"; exit 1; }
done

# Preflight: verify the target user exists so user-space ops don't silently misfire
id -u "$NR_USER" >/dev/null 2>&1 || { echo "ERROR: user '$NR_USER' does not exist"; exit 1; }

echo "Starting Gateway Update as invoker: $(whoami) (user-space ops will run as ${NR_USER})"

# 1. System Updates (Require sudo)
echo "Updating Node.js to v22..."
sudo n 22
sudo n prune
hash -r

echo "Updating Node-RED binary..."
sudo npm install -g node-red

# 2. Local Rebuild (Always run as ncdio so node_modules and npm cache stay user-owned,
#    even if this script was invoked via `sudo ./update-...sh`.)
if [ -d "$NR_DIR" ]; then
    # Pre-rebuild ownership repair: clear any root-owned files left by prior misuse
    # (e.g., `sudo npm install` run inside ~/.node-red) so the rebuild as ncdio won't EACCES.
    echo "Pre-rebuild: repairing ownership on ${NR_DIR} and ~/.npm cache..."
    sudo chown -R "${NR_USER}:${NR_GROUP}" "$NR_DIR"
    sudo chown -R "${NR_USER}:${NR_GROUP}" "/home/${NR_USER}/.npm" 2>/dev/null || true

    echo "Rebuilding modules in $NR_DIR as ${NR_USER}..."
    # install -> rebuild -> install pattern:
    #   1) ensure the tree matches package-lock (handles any new deps),
    #   2) force native modules to recompile against the new Node ABI,
    #   3) verification pass; on a healthy tree this is a fast no-op.
    sudo -u "$NR_USER" -H bash -lc "
        set -Eeuo pipefail
        cd '$NR_DIR'
        npm install
        npm rebuild
        npm install
        npm cache clean --force
    "

    # Post-rebuild safety net: sweep up any odd ownership introduced by postinstall scripts.
    echo "Post-rebuild: ensuring ownership of $NR_DIR is ${NR_USER}:${NR_GROUP}..."
    sudo chown -R "${NR_USER}:${NR_GROUP}" "$NR_DIR"
else
    echo "Warning: $NR_DIR not found. Skipping local rebuild."
fi

# 3. Restart PM2 (Run as ncdio so we talk to ncdio's PM2 daemon, not root's)
echo "Restarting Node-RED via ${NR_USER}'s PM2..."
if sudo -u "$NR_USER" -H pm2 describe node-red >/dev/null 2>&1; then
    sudo -u "$NR_USER" -H pm2 restart node-red
else
    echo "Warning: pm2 process 'node-red' not found for ${NR_USER}; restarting all pm2 processes"
    sudo -u "$NR_USER" -H pm2 restart all
fi

# 4. Verify
echo "Verifying versions..."
npm -v
node-red --version
sudo -u "$NR_USER" -H pm2 status

echo -e "\nUpdate Complete!"
