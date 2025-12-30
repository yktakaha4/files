#!/usr/bin/env bash

set -euo pipefail

IP_ADDRESS="${1:-192.168.56.10}"
CURRENT_DATE=$(date +%Y%m%d-%H%M%S)

cat <<EOF
This script will perform the following actions:
1. Install and configure OpenSSH Server.
2. Configure network interfaces using netplan with the following settings:
   - Interface enp0s8: DHCP enabled, static IP ${IP_ADDRESS}/24
3. Enable and start the SSH service.

Manual is here: https://zenn.dev/link/comments/c1c9ae026cdece
EOF

echo "--- Updating package lists ---"
sudo apt update

echo "--- Installing OpenSSH Server ---"
sudo apt install -y openssh-server

echo "--- Configuring SSH to allow password authentication ---"
sudo cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-${CURRENT_DATE}
sudo sed -Ei '/PasswordAuthentication[[:space:]]+(no|yes)/c\PasswordAuthentication yes' /etc/ssh/sshd_config
diff -u /etc/ssh/sshd_config.bak-${CURRENT_DATE} /etc/ssh/sshd_config || true

echo "--- Enabling and starting SSH service ---"
sudo systemctl enable ssh
sudo systemctl restart ssh

echo "--- Configuring network interfaces with netplan ---"
sudo tee /etc/netplan/90-vbox.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: true
      addresses:
      - ${IP_ADDRESS}/24
    enp0s9:
      dhcp4: yes
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
sudo chmod 0600 /etc/netplan/90-vbox.yaml

echo "--- Applying netplan configuration ---"
sudo netplan apply

echo "--- Setup complete ---"

cat <<EOF
# Add the following to your ~/.ssh/config file on the host machine:

Host vbox
    User $(whoami)
    HostName ${IP_ADDRESS}
EOF
