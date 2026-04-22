# set -e



# # --- Variables ---
# APP_DIR="$HOME/maxlew_videosystem"
# APP_SCRIPT="index.js"
# SERVICE_NAME="maxlew_videosystem"
# NODE_BIN=$(which node)

# echo "[INFO] Setting up Node.js app auto-start for $USER"



# # --- 1. Check if Node.js is installed ---
# if [ -z "$NODE_BIN" ]; then
#     echo "[INFO] Node.js not found, installing Node.js 22.x..."
#     curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
#     sudo apt install -y nodejs
#     NODE_BIN=$(which node)
# fi
# echo "[OK] Node.js is installed: $NODE_BIN"



# # --- 2. Ensure app directory exists ---
# if [ ! -d "$APP_DIR" ]; then
#     echo "[INFO] App directory $APP_DIR does not exist. Creating..."
# fi



# # --- 3. Create a basic systemd service ---
# SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
# sudo bash -c "cat > $SERVICE_FILE" <<EOF
# [Unit]
# Description=Node.js App: $SERVICE_NAME
# After=network.target

# [Service]
# ExecStart=$NODE_BIN $APP_DIR/$APP_SCRIPT
# WorkingDirectory=$APP_DIR
# Environment=DISPLAY=:0
# Environment=XAUTHORITY=/home/$USER/.Xauthority
# Restart=always
# RestartSec=5
# User=$USER
# Environment=NODE_ENV=production
# StandardOutput=syslog
# StandardError=syslog
# SyslogIdentifier=$SERVICE_NAME

# [Install]
# WantedBy=multi-user.target
# EOF

# echo "[OK] Systemd service created at $SERVICE_FILE"


# CONFIG_FILE="/etc/X11/xorg.conf.d/99-vc4.conf"
# CONFIG_DIR="/etc/X11/xorg.conf.d"
# CONFIG_CONTENT='
# Section "OutputClass"
#     Identifier "vc4"
#     MatchDriver "vc4"
#     Driver "modesetting"
#     Option "PrimaryGPU" "true"
# EndSection
# '

# echo "Starting Xorg configuration fix..."

# # 1. Create the configuration directory if it doesn't exist
# if [ ! -d "$CONFIG_DIR" ]; then
#     echo "Creating directory: $CONFIG_DIR"
#     sudo mkdir -p "$CONFIG_DIR"
# else
#     echo "Directory already exists: $CONFIG_DIR"
# fi

# # 2. Write the configuration content to the file
# echo "Writing configuration to $CONFIG_FILE"
# echo "$CONFIG_CONTENT" | sudo tee "$CONFIG_FILE" > /dev/null

# echo "[DONE] $CONFIG_FILE created."


# # --- 4. Enable and start the service ---
# sudo systemctl daemon-reload
# sudo systemctl enable $SERVICE_NAME.service
# sudo systemctl start $SERVICE_NAME.service

# echo "[DONE] $SERVICE_NAME service enabled and started."
# echo "----------------------- Rebooting -----------------------"

# read -r -p "Reboot now? [Y/n] " choice
    
# # Default to 'Y' if the user just presses Enter
# if [[ "$choice" =~ ^[Yy]$ || -z "$choice" ]]; then
#     echo "Rebooting system now..."
#     sudo reboot
# else
#     echo "Please remember to reboot manually to apply the Xorg fix and test the system."
# fi
#!/bin/bash
#
# Maxlew Videosystem — Node.js Service Setup
# Run as user (not root): bash 3_service_setup.sh

set -e

# --- Variables ---
APP_DIR="$HOME/maxlew_videosystem"
APP_SCRIPT="index.js"
SERVICE_NAME="maxlew_videosystem"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "[INFO] Setting up Node.js app auto-start for $USER"

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# --- 1. Resolve Node.js binary ---
# nvm installs node into ~/.nvm, so 'which node' may return nothing in a
# non-interactive shell. Source nvm first to ensure node is on PATH.
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  source "$HOME/.nvm/nvm.sh"
fi

NODE_BIN=$(which node 2>/dev/null || true)

if [ -z "$NODE_BIN" ]; then
  echo "[INFO] Node.js not found, installing Node.js 22.x via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs
  NODE_BIN=$(which node)
fi

echo "[OK] 1. === Node.js is installed: $NODE_BIN ($(node --version)) ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# --- 2. Ensure app directory exists ---
if [ ! -d "$APP_DIR" ]; then
  echo "[ERROR] App directory $APP_DIR does not exist."
  echo "        Run script 1 first to clone the repo, then re-run this script."
  exit 1
fi
echo "[OK] 2. === App directory found: $APP_DIR ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# --- 3. Warn if .env is missing ---
if [ ! -f "$APP_DIR/.env" ]; then
  echo "[WARNING] No .env file found at $APP_DIR/.env"
  echo "          The app may not start correctly without it."
  echo "          Copy your .env file there before rebooting."
fi

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# --- 4. Create systemd service ---
# Note: NODE_BIN is resolved to the full absolute path here so systemd
# (which does not source nvm) can find it without PATH manipulation.
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
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

echo "[OK] 4. === Systemd service created at $SERVICE_FILE ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# --- 5. Enable and start the service ---
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME.service"
sudo systemctl start "$SERVICE_NAME.service"

echo "[OK] 5. === $SERVICE_NAME service enabled and started ==="

# Verify it actually started
sleep 2
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
  echo "[OK]    Service is running."
else
  echo "[WARNING] Service does not appear to be running."
  echo "          Check logs with: journalctl -u $SERVICE_NAME -f"
fi

# -----------------------------------------------------------------------------------------------------------------------------------------------------

echo ""
echo "[DONE] $SERVICE_NAME setup complete."
echo ""
echo "  Useful commands:"
echo "  sudo systemctl status $SERVICE_NAME    — check status"
echo "  sudo systemctl restart $SERVICE_NAME   — restart app"
echo "  journalctl -u $SERVICE_NAME -f         — live logs"
echo ""
echo "----------------------- Rebooting -----------------------"

read -r -p "Reboot now? [Y/n] " choice

if [[ "$choice" =~ ^[Yy]$ || -z "$choice" ]]; then
  echo "Rebooting system now..."
  sudo reboot
else
  echo "Remember to reboot manually: sudo reboot"
fi