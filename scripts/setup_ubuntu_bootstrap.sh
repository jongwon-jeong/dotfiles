#!/usr/bin/env bash

# Keep Ubuntu-specific machine bootstrap here; avoid adding unsupported distro setup without an explicit need.
#
# Layout:
# - Ubuntu package/system setup comes first.
# - Distro-neutral userland installers stay separate and run after their base dependencies.
# - Keep main's task order aligned with the section order, except for network policy,
#   which should run after download-heavy installers.

# Common helpers and environment detection {{{
# Shared predicates and logging used by both Ubuntu-specific and distro-neutral tasks.

show_script_info() { # {{{
  echo "INFO: basename: ${0##*/}"
  echo "INFO: dirname : $(dirname "${0}")"
  echo "INFO: pwd     : $(pwd)"
  echo ""
} # }}}

# Detection helpers {{{
is_wsl() {
  [[ -f /proc/version ]] && grep -qiE "microsoft|wsl" /proc/version
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "ubuntu" || "${ID_LIKE}" =~ "ubuntu" ]]
  )
}

is_nvidia_hardware_present() {
  lspci | grep -qi "nvidia"
}
# Detection helpers }}}
# Common helpers and environment detection }}}

# Ubuntu package and bootstrap foundation {{{
# Installs and repairs apt-managed system packages before any upstream installers run.

install_package() { # {{{
  local -r pkgs=("${@}")
  local valid_pkgs=()

  local pkg
  for pkg in "${pkgs[@]}"; do
    if apt-cache show "${pkg}" >/dev/null 2>&1; then
      valid_pkgs+=("${pkg}")
    else
      echo "WARN: Skipping: ${pkg} (Not found in repository)"
    fi
  done

  if [[ ${#valid_pkgs[@]} -gt 0 ]]; then
    sudo \
      DEBIAN_FRONTEND=noninteractive \
      apt-get install \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      -o Acquire::Queue-Mode=access \
      -o Acquire::Retries=5 \
      --ignore-missing \
      --fix-missing \
      --no-install-recommends \
      --yes \
      "${valid_pkgs[@]}"
  fi
} # }}}

recover_package_state() { # {{{
  if dpkg --audit | grep -q .; then
    echo ""
    echo "INFO: Recovering interrupted package configuration..."
    sudo dpkg --configure -a
    sudo apt-get -f install -y
  fi
} # }}}

upgrade_packages() { # {{{
  echo ""
  echo "INFO: Updating APT package cache and upgrading system packages..."

  sudo apt-get update -y

  if sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"; then

    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
  else
    echo "WARN: apt-get full-upgrade encountered an issue."
    return 1
  fi
} # }}}

install_ubuntu_foundation_packages() { # {{{
  if ! is_wsl && command -v ubuntu-drivers &>/dev/null; then
    echo ""
    echo "INFO: Installing Ubuntu recommended additional drivers..."
    sudo ubuntu-drivers install
  fi

  echo ""
  echo "INFO: Installing base Ubuntu packages and desktop CLI dependencies..."
  install_package \
    zsh tmux \
    git curl wget \
    libwxgtk-gl3.2-1t64 \
    ibus-hangul \
    exfatprogs zip unzip 7zip-standalone \
    tree btop fzf bat eza fd-find git-delta ripgrep sd \
    ffmpeg jq mat2 \
    wl-clipboard xclip x11-apps \
    python3-full python3-pip python3-venv pipx \
    build-essential gdb \
    flatpak

  if ! is_wsl; then
    install_package \
      mpv alacritty

    if is_nvidia_hardware_present; then
      install_package nvtop
    fi

    if command -v flatpak &>/dev/null; then
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
  fi

  :
} # }}}

install_neovim() { # {{{
  # Add export PATH="$PATH:/opt/nvim-linux-x86_64/bin" to ~/.zshrc
  if command -v nvim &>/dev/null; then
    echo "DONE: neovim is already installed"
    return 0
  fi

  local -r arch_type=$(uname -m)
  if [[ "${arch_type}" == "x86_64" ]]; then
    local -r download_dir="${HOME}/proj/tmp/packages"
    mkdir -pv "${download_dir}"
    echo ""
    echo "INFO: Downloading Neovim archive to ${download_dir}..."
    curl -fLo "${download_dir}/nvim-linux-x86_64.tar.gz" \
      https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    echo ""
    echo "INFO: Installing Neovim under /opt and linking /usr/local/bin/nvim..."
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf "${download_dir}/nvim-linux-x86_64.tar.gz"

    sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" /usr/local/bin/nvim
  else
    echo "ERROR: Unsupported Linux architecture: ${arch_type}"
    return 1
  fi
} # }}}
# Ubuntu package and bootstrap foundation }}}

# Ubuntu desktop and system configuration {{{
# Applies Ubuntu desktop/system policy after the required packages are present.

map_right_alt_to_hangul() { # {{{
  if is_wsl; then
    return 0
  fi

  HNGL_X11() {
    if [[ "${XDG_SESSION_TYPE:-}" != "x11" ]]; then
      return 0
    fi

    local -r target_file="/usr/share/X11/xkb/keycodes/evdev"

    if ! [ -f "${target_file}" ]; then
      return 0
    fi
    if grep -q "^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*108;" "${target_file}"; then
      return 0
    fi

    sudo bash <<SUDO_SCRIPT
  cp "${target_file}" "${target_file}.$(date +%Y%m%d-%H%M%S).bak"
  # 1. Comment out '<RALT> = 108;' and add '<HNGL> = 108;' right below it
  sed -i '/^[[:space:]]*<RALT>[[:space:]]*=[[:space:]]*108;/c\// <RALT> = 108;\n<HNGL> = 108;' "${target_file}"
  # 2. Comment out the existing '<HNGL> = 130;' line
  sed -i 's/^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*130;/ \/\/ <HNGL> = 130;/g' "${target_file}"
SUDO_SCRIPT
  }

  HNGL_Wayland() {
    if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
      return 0
    fi

    if command -v gsettings &>/dev/null; then
      local -r schema="org.gnome.desktop.input-sources"
      local -r key="xkb-options"
      local -r option="'korean:ralt_hangul'"

      # 1. Get current XKB options
      local current_value
      current_value=$(gsettings get "${schema}" "${key}")

      # 2. Check if the option is already active
      if [[ "${current_value}" == *"${option}"* ]]; then
        echo "DONE: Right Alt is already mapped to Hangul (Wayland/X11)."
        return 0
      fi

      echo ""
      echo "INFO: Remapping Right Alt to Hangul for Wayland/X11..."

      # 3. Append the option safely
      if [[ "${current_value}" == "@as []" ]] || [[ "${current_value}" == "[]" ]]; then
        # If empty, set it directly
        gsettings set "${schema}" "${key}" "['korean:ralt_hangul']"
      else
        # If not empty, append it (removing the closing bracket ']')
        # e.g., ['caps:escape'] -> ['caps:escape', 'korean:ralt_hangul']
        local new_value="${current_value%]}"
        new_value="${new_value}, ${option}]"
        gsettings set "${schema}" "${key}" "${new_value}"
      fi
    else
      echo "WARN: 'gsettings' not found. Skipping key remap."
    fi
  }

  HNGL_X11
  HNGL_Wayland

  # How to rollback
  # --------------------------------------------------------
  # **X11**
  # Step 1) Check if backup files exist
  # ls /usr/share/X11/xkb/keycodes/evdev.*.bak
  # Step 2)
  # sudo cp /usr/share/X11/xkb/keycodes/evdev.{**backup-date**}.bak /usr/share/X11/xkb/keycodes/evdev
  # Step 3)
  # sudo reboot
  #
  # **Wayland**
  # Step 1) Check current state
  # gsettings get org.gnome.desktop.input-sources xkb-options
  # Step 2)
  # gsettings set org.gnome.desktop.input-sources xkb-options "[]"
  # Step 3)
  # sudo reboot
} # }}}

setup_locale() { # {{{
  echo ""
  echo "INFO: Configuring system locale to en_US.UTF-8..."
  if command -v locale-gen &>/dev/null; then
    sudo locale-gen en_US.UTF-8
  else
    echo "WARN: locale-gen not found. Skipping locale setup."
  fi
  sudo update-locale LANG=en_US.UTF-8
} # }}}

set_default_shell_to_zsh() { # {{{
  local -r zsh_path="$(command -v zsh)"
  if [ -n "${zsh_path}" ]; then
    local -r target_user="${SUDO_USER:-${USER}}"
    echo ""
    echo "INFO: Changing login shell for ${target_user} to ${zsh_path}..."
    sudo chsh -s "${zsh_path}" "${target_user}"
  else
    echo "WARN: Zsh is not installed or not in PATH."
  fi
} # }}}
# Ubuntu desktop and system configuration }}}

# Distro-neutral userland setup {{{
# Installs user-owned tools that are not inherently tied to apt, after their base dependencies exist.

create_default_directories() { # {{{
  mkdir -pv ~/Downloads
  mkdir -pv ~/Documents
  mkdir -pv ~/proj/personal
  mkdir -pv ~/proj/public
  mkdir -pv ~/proj/work
  mkdir -pv ~/proj/tmp
} # }}}

install_zsh_plugins() { # {{{
  local -r zsh_dir="${HOME}/.zsh"
  mkdir -p "${zsh_dir}"

  local -rA plugins=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  )

  local name
  for name in "${!plugins[@]}"; do
    local target="${zsh_dir}/${name}"
    if [[ ! -d "${target}" ]]; then
      echo ""
      echo "INFO: Cloning ${name}..."
      git clone --depth 1 "${plugins[$name]}" "${target}"
    elif [[ -d "${target}/.git" ]]; then
      echo ""
      echo "INFO: Updating ${name}..."
      git -C "${target}" pull --ff-only
    else
      echo "WARN: Skipping: ${name} (${target} exists but is not a git repository)"
    fi
  done
} # }}}

install_node() { # {{{
  echo ""
  echo "INFO: Installing Node.js..."

  export NVM_DIR="${HOME}/.nvm"
  export PROFILE="/dev/null"

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  # shellcheck source=/dev/null
  . "${NVM_DIR}/nvm.sh" || return 1

  nvm install node
  nvm alias default node

  local -a npm_global_packages=(
    @biomejs/biome
    prettier
    tsx
    typescript
    typescript-language-server
    @openai/codex
    tree-sitter-cli
  )

  echo ""
  echo "INFO: Installing npm packages..."
  local package
  for package in "${npm_global_packages[@]}"; do
    if ! npm install -g "${package}"; then
      echo "WARN: Failed to install npm package: ${package}"
    fi
  done
} # }}}

install_user_cli_tools() { # {{{
  if ! command -v uv &>/dev/null; then
    echo ""
    echo "INFO: Installing uv from the upstream installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
  fi

  if command -v uv &>/dev/null; then
    echo ""
    echo "INFO: Installing Python runtime and uv-managed CLI tools..."
    uv python install
    uv tool install ruff
    uv tool install ty
    uv tool install pre-commit
    uv tool install "yt-dlp[default,curl-cffi]"
  fi

  if ! command -v starship &>/dev/null; then
    echo ""
    echo "INFO: Installing Starship from the upstream installer..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
} # }}}

install_nerd_font() { # {{{
  local -r font_name="JetBrainsMonoNLNerdFontMono"
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"
  # Windows Font Directory = "/mnt/c/Windows/Fonts"
  local -r font_dir="${HOME}/.local/share/fonts"

  install_jetbrains_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "DONE: ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo ""
    echo "INFO: Installing ${font_name} ${version}..."

    local -r temp_dir="${HOME}/proj/tmp/packages/nerd_fonts_setup"
    mkdir -pv "${temp_dir}"

    echo ""
    echo "INFO: Downloading font archive..."
    curl -fLo "${temp_dir}/JetBrainsMono.zip" "${download_url}" --retry 3

    echo ""
    echo "INFO: Extracting files..."
    unzip -o "${temp_dir}/JetBrainsMono.zip" -d "${temp_dir}"

    mkdir -pv "${font_dir}"

    find "${temp_dir}" -name "JetBrainsMonoNLNerdFontMono-*.ttf" -exec cp {} "${font_dir}/" \;

    echo ""
    echo "INFO: Updating font cache..."
    fc-cache -f "${font_dir}"

    # rm -rf "${temp_dir}"
    echo "DONE: Font installation completed successfully!"
  }
  install_jetbrains_nerd_font
} # }}}
# Distro-neutral userland setup }}}

# Ubuntu network policy {{{
# Runs after download-heavy installers so first-boot setup is less likely to lose network access.

setup_basic_network_privacy() { # {{{
  if is_wsl; then
    # WSL does not own the real Wi-Fi adapter or host firewall.
    return 0
  fi

  # Goal:
  # - Provide conservative desktop/laptop defaults for everyday Ubuntu use.
  # - Block unsolicited inbound traffic with UFW.
  # - Enable Wi-Fi MAC randomization and IPv6 privacy addresses.
  #
  # Non-goals:
  # - Do not implement aggressive network hardening.
  # - Do not change DNS, systemd-resolved, mDNS, LLMNR, routing, or VPN behavior.
  # - Do not reset existing UFW rules.
  echo ""
  echo "INFO: Applying basic desktop network privacy settings..."

  install_package ufw
  # UFW:
  # - Existing UFW rules are preserved; do not run "ufw reset".
  # - Add allow rules manually for inbound SSH or dev servers.
  #   Examples:
  #     sudo ufw allow 22/tcp     # SSH
  #     sudo ufw allow 8080/tcp   # HTTP server
  #
  # Commands:
  # - Review rules: sudo ufw status verbose
  # - Disable UFW logging: sudo ufw logging off
  # - Disable UFW: sudo ufw disable
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw logging low
  echo "y" | sudo ufw enable
  sudo systemctl enable ufw.service >/dev/null 2>&1 || true

  # Captive portal issue:
  # - Temporarily set wifi.cloned-mac-address=permanent.
  # - Reload NetworkManager: sudo systemctl reload NetworkManager.service
  # - Reconnect to that Wi-Fi network.
  # - Restore wifi.cloned-mac-address=random after login if possible.
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/99-privacy.conf >/dev/null <<'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
# Random per-connection Wi-Fi MAC. Use "permanent" temporarily if a captive
# portal requires the hardware MAC to complete login.
wifi.cloned-mac-address=random
ipv6.ip6-privacy=2
# Use "permanent" only when a wired network requires a fixed MAC.
ethernet.cloned-mac-address=random
# Use "yes" only when that connection needs switch discovery, LAN host lookup,
# or local service discovery.
lldp=no
llmnr=no
mdns=no
EOF

  # Apply now if NetworkManager is running; otherwise it applies on next start.
  sudo systemctl reload NetworkManager.service 2>/dev/null || true
} # }}}
# Ubuntu network policy }}}

# Main {{{
main() {
  if (($# > 0)); then
    echo "ERROR: setup_ubuntu_bootstrap.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  if is_ubuntu; then
    local -a tasks=(
      show_script_info
    )

    tasks+=(
      upgrade_packages
      install_ubuntu_foundation_packages
      install_neovim
    )

    tasks+=(
      map_right_alt_to_hangul
      setup_locale
      set_default_shell_to_zsh
    )

    tasks+=(
      create_default_directories
      install_zsh_plugins
      install_node
      install_user_cli_tools
      install_nerd_font
    )

    tasks+=(
      setup_basic_network_privacy
    )
  else
    echo "ERROR: Distro mismatch. Ubuntu only."
    exit 1
  fi

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      if ! "${task}"; then
        echo "ERROR: Task failed, continuing: ${task}"
        recover_package_state
      fi
      echo ""
      echo ""
      echo ""
    else
      echo "WARN: Function '${task}' not found."
    fi
  done
}
# Main }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
