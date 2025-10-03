set -e

# --- Variables ---
APP_DIR="$HOME/maxlew_videosystem"
APP_SCRIPT="index.js"
SERVICE_NAME="maxlew_videosystem"
NODE_BIN=$(which node)

echo "[INFO] Setting up Node.js app auto-start for $USER"

# --- 1. Check if Node.js is installed ---
if [ -z "$NODE_BIN" ]; then
    echo "[INFO] Node.js not found, installing Node.js 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    NODE_BIN=$(which node)
fi
echo "[OK] Node.js is installed: $NODE_BIN"

# --- 2. Ensure app directory exists ---
if [ ! -d "$APP_DIR" ]; then
    echo "[INFO] App directory $APP_DIR does not exist. Creating..."
    mkdir -p "$APP_DIR"
fi

# --- 3. Create a basic systemd service ---
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Node.js App: $SERVICE_NAME
After=network.target

[Service]
ExecStart=$NODE_BIN $APP_DIR/$APP_SCRIPT
WorkingDirectory=$APP_DIR
Restart=always
RestartSec=5
User=$USER
Environment=NODE_ENV=production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

echo "[OK] Systemd service created at $SERVICE_FILE"

# --- 4. Enable and start the service ---
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service

echo "[DONE] $SERVICE_NAME service enabled and started."
echo "Use 'systemctl status $SERVICE_NAME' to check logs."