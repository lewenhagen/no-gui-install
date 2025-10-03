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

echo "✅ 1. === Installation done. ==="


# === 2. Allow X to start without root ===
sudo sed -i 's/^allowed_users.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

echo "✅ 2. === X is allowed to start without root ==="


# === 3. Add user to groups ===
sudo usermod -aG video,audio,input $USER
echo "✅ 3. === $USER is added to correct groups ==="


# === 4. Enable autologin for $USER on TTY1 ===
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<'EOF' | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I $TERM
EOF
echo "✅ 4. === Autologin for tty1 is enabled for kiosk ==="


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
while true; do
  chromium-browser \
    --noerrdialogs \
    --disable-infobars \
    --start-fullscreen \
    --kiosk "http://localhost:3000"

  echo "⚠️ Chromium crashed or exited, restarting in 5s..." >&2
  sleep 5
done
EOF

echo "✅ 5.1 === .xinitrc is set up for user $USER ==="


chmod +x ~/.xinitrc
echo "✅ 5.2 === .xinitrc has the right permission now. ==="

# === 6. Autostart X for $USER ===
cat > ~/.bash_profile <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
fi
EOF

echo "✅ 6. === X is now on autostart for $USER ==="
echo "✅ Maxlew Videosystem browser setup complete."
