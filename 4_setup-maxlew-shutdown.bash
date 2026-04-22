#!usr/bin/env bash
echo "maxlew ALL=(ALL) NOPASSWD: /bin/systemctl poweroff" | sudo tee /etc/sudoers.d/maxlew-poweroff
sudo chmod 440 /etc/sudoers.d/maxlew-poweroff