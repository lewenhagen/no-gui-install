#!/bin/bash
#
# Run as user

set -e

# === 1. Install required packages ===
sudo apt update
sudo apt install -y --no-install-recommends \
  xorg \
  xserver-xorg-legacy \
  openbox \
  chromium \
  unclutter-xfixes \
  console-data 

# === 2. Allow X to start without root ===
sudo sed -i 's/^allowed_users.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

# === 3. Add user to groups ===
sudo usermod -aG video,audio,input $USER

# === 4. Enable autologin for kiosk on TTY1 ===
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I $TERM
EOF

# === 5. Setup .xinitrc ===
cat > ~/.xinitrc <<'EOF'
#!/bin/bash
xset -dpms
xset s off
xset s noblank

# Hide cursor
unclutter --timeout 0 --hide-on-touch &

# Start Openbox
openbox-session &

# Start Chromium in kiosk mode
chromium \
  --noerrdialogs \
  --disable-infobars \
  --start-fullscreen \
  --kiosk "localhost:3000"
EOF

chmod +x ~/.xinitrc

# === 6. Autostart X for $USER ===
cat > ~/.bash_profile <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
fi
EOF

echo "✅ Maxlew browser setup complete."
