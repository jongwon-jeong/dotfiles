#!/usr/bin/env bash

set -euo pipefail

# Ubuntu Safe Release Upgrade Helper
# Before using: back up important files and review:
#   /etc/update-manager/release-upgrades
#
# If you want to stay on LTS releases only, keep:
#   Prompt=lts
#
# If you want Ubuntu to offer the next regular non-LTS release, use:
#   Prompt=normal
#
# Check availability manually with:
#   do-release-upgrade -c
#
# IMPORTANT:
# - This helper intentionally leaves do-release-upgrade interactive.
# - If running over SSH, use tmux or a similarly persistent session.
# - Example:
#     tmux new -s upgrade
#     sudo ./scripts/ubuntu_upgrade.sh
#     # detach with Ctrl+b d
#     tmux attach -t upgrade

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "ubuntu" || "${ID_LIKE:-}" =~ "ubuntu" ]]
  )
}

require_ubuntu() {
  if ! is_ubuntu; then
    echo "❌ Error: Ubuntu release upgrades are only supported on Ubuntu-family systems."
    exit 1
  fi
}

warn_if_ssh() {
  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]]; then
    echo "⚠️ SSH session detected."
    echo "   Run release upgrades inside tmux or another persistent session."
    echo ""
  fi
}

confirm_release_upgrade() {
  echo ""
  echo "⚠️ The next step starts Ubuntu's interactive release upgrader."
  echo "   Make sure backups are current and long-running sessions are protected."
  read -rp "Continue with sudo do-release-upgrade? Type 'yes' to continue: " answer

  if [[ "${answer}" != "yes" ]]; then
    echo "✅ Release upgrade skipped."
    exit 0
  fi
}

print_system_state() {
  echo ""
  echo "1. Checking current Ubuntu version and disk state"
  lsb_release -a
  uname -r
  df -h
}

upgrade_current_release() {
  echo ""
  echo "2. Updating current release packages"
  sudo apt update -y

  echo ""
  echo "3. Upgrading installed packages"
  sudo apt full-upgrade -y

  echo ""
  echo "4. Removing unnecessary packages"
  sudo apt autoremove -y
  sudo apt clean
}

run_release_upgrade() {
  confirm_release_upgrade

  echo ""
  echo "5. Starting interactive release upgrade"
  sudo do-release-upgrade
}

post_upgrade_verification() {
  echo ""
  echo "6. Post-upgrade verification"
  lsb_release -a
  sudo apt update -y
  sudo apt full-upgrade -y
  sudo apt autoremove -y

  echo ""
  echo "✅ Upgrade helper complete. Reboot, then check services and desktop/session behavior."
}

main() {
  if (($# > 0)); then
    echo "❌ Error: ubuntu_upgrade.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  require_ubuntu
  warn_if_ssh
  print_system_state
  upgrade_current_release
  run_release_upgrade
  post_upgrade_verification
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
