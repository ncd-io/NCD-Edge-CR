#!/bin/bash

# Exit immediately if a command fails
set -e

# Error handling function
failure_handler() {
    echo -e "\n\033[0;31m##########################################################"
    echo "❌ ERROR: The update failed at the last command."
    echo "Please COPY the entire output of this terminal window"
    echo "and email it to: support@ncd.io"
    echo -e "##########################################################\033[0m\n"
}

trap 'failure_handler' ERR

echo "🚀 Starting Gateway Update & Cleanup..."

# 1. Update Node.js to v20 (LTS)
echo "📦 Updating Node.js..."
sudo n 20
hash -r

# 2. PRUNE - Remove old cached versions to save disk space
echo "🧹 Pruning old Node.js versions..."
sudo n prune

# 3. Update npm and clean its cache
echo " Updating npm..."
sudo npm install -g npm@latest
sudo npm cache clean -f

# 4. Update Node-RED
echo "🕸️ Updating Node-RED..."
sudo npm install -g --unsafe-perm node-red

# 5. Handle Native Modules & Rebuild
NR_DIR="$HOME/.node-red"
if [ -d "$NR_DIR" ]; then
    echo "🏗️  Rebuilding native modules in $NR_DIR..."
    cd "$NR_DIR"
    rm -rf node_modules package-lock.json
    npm install --unsafe-perm
    # Final cleanup of the local npm cache
    npm cache clean --force
fi

# 6. Restart Services
echo "🔄 Restarting PM2..."
pm2 restart node-red

echo -e "\n✅ Update and Cleanup Complete!"
echo "Node: $(node -v)"
echo "Free Space: $(df -h / | awk 'NR==2 {print $4}')"