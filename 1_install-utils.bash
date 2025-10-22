#!/bin/bash
#
# Run as user

VSUSER="$USER"

set -e

# Define Xorg config variables for the fix
XORG_CONFIG_FILE="/etc/X11/xorg.conf.d/99-vc4.conf"
XORG_CONFIG_DIR="/etc/X11/xorg.conf.d"
XORG_CONFIG_CONTENT='
Section "OutputClass"
    Identifier "vc4"
    MatchDriver "vc4"
    Driver "modesetting"
    Option "PrimaryGPU" "true"
EndSection
'

# === 1. Install required packages ===
sudo apt update
sudo apt install -y --no-install-recommends \
  xorg \
  curl \
  xserver-xorg-legacy \
  openbox \
  chromium \
  unclutter-xfixes \
  console-data \
  git \
  jq \
  nmap

echo "[OK] 1. === Installation of prereq. done. (xorg, xserver-xorg-legacy, openbox, chromium, unclutter-xfixes, console-data, git) ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 2. Allow X to start without root ===
# Use a semicolon to ensure the 'echo' happens even if 'sed' fails (e.g., file doesn't exist)
sudo sed -i 's/^allowed_users.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" | sudo tee -a /etc/X11/Xwrapper.config > /dev/null

echo "[OK] 2. === X is allowed to start without root ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 3. Add user to groups ===
sudo usermod -aG video,audio,input $VSUSER
echo "[OK] 3. === $VSUSER is added to correct groups ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 4. XORG FRAMEBUFFER FIX (for Raspberry Pi 5 / Bookworm) ===
sudo mkdir -p "$XORG_CONFIG_DIR"
echo "$XORG_CONFIG_CONTENT" | sudo tee "$XORG_CONFIG_FILE" > /dev/null

echo "[OK] 4. === Xorg framebuffer fix (99-vc4.conf) applied. ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 5. Enable autologin for $VSUSER on TTY1 ===
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $VSUSER --noclear %I $TERM
EOF
echo "[OK] 5. === Autologin for tty1 is enabled for kiosk ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 6. Setup .xinitrc ===
cat > ~/.xinitrc <<'EOF'
#!/bin/bash
xset -dpms
xset s off
xset s noblank

# Hide cursor
unclutter --timeout 0 --hide-on-touch &

# Start Openbox
export DISPLAY=:0
export XAUTHORITY=$HOME/.Xauthority


while ! xrandr | grep " connected"; do
  sleep 1
done

for output in $(xrandr | grep " connected" | cut -d" " -f1); do
  xrandr --output "$output" --mode 1920x1080 --rate 60
done

openbox-session &

# Wait for n seconds before boot this stuff

until curl -s http://localhost:3000 > /dev/null; do
  echo "Waiting for Maxlew server..."
  sleep 1
done

# Start Chromium in kiosk mode
while true; do
  chromium \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=TranslateUI \
    --disable-features=Translate \
    --disable-translate \
    --lang=sv \
    --no-first-run \
    --no-default-browser-check \
    --disable-popup-blocking \
    --incognito \
    --start-fullscreen \
    --user-data-dir=$HOME/.chromium-kiosk \
    --kiosk "http://localhost:3000/splashscreen"

  echo "[WARNING] Chromium crashed or exited, restarting in 5s..." >&2
  sleep 5
done
EOF

echo "[OK] 6.1 === .xinitrc is set up for user $VSUSER (including new translation flags) ==="


chmod +x ~/.xinitrc
echo "[OK] 6.2 === .xinitrc has the right permission now. ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 7. Autostart X for $VSUSER ===
cat > ~/.bash_profile <<'EOF'
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
fi
EOF

echo "[OK] 7. === X is now on autostart for $VSUSER ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

# === 8. Setup Chromium Kiosk Profile (Disables First-Run Popups) ===
mkdir -p "$HOME/.chromium-kiosk"
chmod 700 "$HOME/.chromium-kiosk"
touch "$HOME/.chromium-kiosk/First Run"

echo "[OK] 8. === Chromium kiosk profile setup: 'First Run' file created to suppress popups. ==="

# -----------------------------------------------------------------------------------------------------------------------------------------------------

echo "[DONE] Maxlew Videosystem browser setup complete. A reboot is required."