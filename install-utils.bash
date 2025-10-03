#!/bin/bash
#
# Run as user

VSUSER="$USER"

set -e

# === 1. Install required packages ===
sudo apt update
sudo apt install -y --no-install-recommends \
  xorg \
  xserver-xorg-legacy \
  openbox \
  chromium \
  unclutter-xfixes \
  console-data \
  git

echo "[OK] 1. === Installation of prereq. done. (xorg, xserver-xorg-legacy, openbox, chromium, unclutter-xfixes, console-data, git) ==="


# === 2. Allow X to start without root ===
sudo sed -i 's/^allowed_users.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

echo "[OK] 2. === X is allowed to start without root ==="


# === 3. Add user to groups ===
sudo usermod -aG video,audio,input $VSUSER
echo "[OK] 3. === $VSUSER is added to correct groups ==="


# === 4. Enable autologin for $VSUSER on TTY1 ===
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $VSUSER --noclear %I $TERM
EOF
echo "[OK] 4. === Autologin for tty1 is enabled for kiosk ==="


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

# Wait for n seconds before boot this stuff

until curl -s http://localhost:3000 > /dev/null; do
  echo "Waiting for Maxlew server..."
  sleep 2
done

# Start Chromium in kiosk mode
while true; do
  chromium \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=TranslateUI \
    --disable-translate \
    --lang=sv \
    --no-first-run \
    --no-default-browser-check \
    --disable-popup-blocking \
    --incognito \
    --start-fullscreen \
    --kiosk "http://localhost:3000/splashscreen"

  echo "[WARNING] Chromium crashed or exited, restarting in 5s..." >&2
  sleep 5
done
EOF

echo "[OK] 5.1 === .xinitrc is set up for user $VSUSER ==="


chmod +x ~/.xinitrc
echo "[OK] 5.2 === .xinitrc has the right permission now. ==="

# === 6. Autostart X for $VSUSER ===
cat > ~/.bash_profile <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
fi
EOF

echo "[OK] 6. === X is now on autostart for $VSUSER ==="
echo "[DONE] Maxlew Videosystem browser setup complete."
