#!/bin/bash

# Exit on error
set -e

# Error handler for support
failure_handler() {
    echo -e "\n\033[0;31m##########################################################"
    echo "❌ ERROR: The update failed."
    echo "Please COPY the entire terminal output and send it to us at https://ncd.io/contact-us/:"
    echo -e "##########################################################\033[0m\n"
}
trap 'failure_handler' ERR

echo "🚀 Starting Gateway Update as user: $(whoami)"

# 1. System Updates (Require sudo)
echo "📦 Updating Node.js to v20..."
sudo n 20
sudo n prune
hash -r

echo "🛠️ Updating npm and Node-RED binaries..."
sudo npm install -g npm@latest
sudo npm install -g --unsafe-perm node-red
sudo npm cache clean -f

# 2. Local Rebuild (Run as current user - no sudo)
NR_DIR="$HOME/.node-red"
if [ -d "$NR_DIR" ]; then
    echo "🏗️  Rebuilding modules in $NR_DIR..."
    cd "$NR_DIR"
    # Remove old artifacts to force a clean node-gyp rebuild
    rm -rf node_modules package-lock.json
    npm install --unsafe-perm
    npm cache clean --force
else
    echo "⚠️  Warning: $NR_DIR not found. Skipping local rebuild."
fi

# 3. Restart PM2 (Run as current user - no sudo)
echo "🔄 Restarting Node-RED..."
# We try ID 1 first since you confirmed that's the Node-RED ID
pm2 restart node-red

echo -e "\n✅ Update Complete!"
node -v
npm -v