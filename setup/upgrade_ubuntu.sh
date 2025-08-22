#!/bin/bash
# Ubuntu Safe Release Upgrade Script (Server Non-Interactive)
# Before using: make sure to backup important files

# lsb_release -a
# sudo vi /etc/update-manager/release-upgrades
# and change 'Prompt=lts' to 'Prompt=normal'
# Run with: chmod +x upgrade_ubuntu.sh && sudo ./upgrade_ubuntu.sh

# IMPORTANT: If running over SSH, consider using tmux or nohup
# Example with nohup: nohup ./upgrade_ubuntu.sh > upgrade.log 2>&1 &
# Example with tmux:
# tmux new -s upgrade
# sudo ./upgrade_ubuntu.sh
# (You can detach with Ctrl+b d and reattach later with tmux attach -t upgrade)

set -e # Exit immediately if a command exits with a non-zero status

echo "1. Checking current Ubuntu version"
lsb_release -a
uname -r
df -h

echo "2. Updating package lists"
sudo DEBIAN_FRONTEND=noninteractive apt update -y || true

echo "3. Upgrading installed packages (non-interactive)"
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y || true

echo "4. Removing unnecessary packages (non-interactive)"
sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y || true
sudo apt clean || true

echo "5. Starting release upgrade (non-interactive)"
sudo DEBIAN_FRONTEND=noninteractive do-release-upgrade -f DistUpgradeViewNonInteractive | tee ~/upgrade.log || true

echo "6. Post-upgrade verification"
lsb_release -a
sudo DEBIAN_FRONTEND=noninteractive apt update -y || true
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y || true
sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y || true

echo "Upgrade complete! Please reboot the system and check that all services are running properly."
