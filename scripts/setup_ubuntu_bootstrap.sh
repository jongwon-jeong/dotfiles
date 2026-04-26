#!/usr/bin/env bash

show_script_info() { # {{{
  echo "basename: ${0##*/}"
  echo "dirname : $(dirname "${0}")"
  echo "pwd     : $(pwd)"
  echo ""
} # }}}

# Detect functions {{{
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

is_nvidia_driver_ready() {
  if lsmod | grep -qE "^nvidia"; then
    return 0
  elif dpkg -l | grep -qi "nvidia-driver"; then
    return 0
  fi
  return 1
}
# }}}

keep_sudo_alive() { # {{{
  sudo -v
  while true; do
    sudo -n true 2>/dev/null
    sleep 30
  done &

  readonly SUDO_KEEP_ALIVE_PID=$!
} # }}}

install_package() { # {{{
  update_cache_if_needed() {
    local -r stamp_file="/var/lib/apt/periodic/update-success-stamp"
    local last_update=0

    if [[ -f "${stamp_file}" ]]; then
      last_update=$(stat -c %Y "${stamp_file}" 2>/dev/null || echo 0)
    fi

    local now
    now=$(date +%s)
    local -r interval=$((86400 * 7))

    if ((now - last_update > interval)); then
      echo ""
      echo "🔄 Updating APT package cache..."

      if sudo apt-get update; then
        sudo mkdir -p "$(dirname "${stamp_file}")"
        sudo touch "${stamp_file}"
      else
        echo "⚠️ Failed to update APT cache. Proceeding anyway..."
      fi
    fi
  }

  local -r pkgs=("${@}")
  local valid_pkgs=()

  update_cache_if_needed

  local pkg
  for pkg in "${pkgs[@]}"; do
    if apt-cache show "${pkg}" >/dev/null 2>&1; then
      valid_pkgs+=("${pkg}")
    else
      echo "⚠️ Skipping: ${pkg} (Not found in repository)"
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
    echo "🔄 Recovering interrupted package configuration..."
    sudo dpkg --configure -a
    sudo apt-get -f install -y
  fi
} # }}}

install_basic_packages() { # {{{
  echo ""
  echo "🔄 Updating and upgrading APT packages before installing the base toolset..."
  sudo apt-get update -y && sudo apt-get upgrade -y

  echo ""
  echo "🔄 Installing base Ubuntu packages and desktop CLI dependencies..."
  install_package \
    sudo coreutils util-linux bash zsh tmux \
    git curl wget \
    language-pack-ko ibus-hangul \
    exfatprogs zip unzip 7zip-standalone \
    tree btop fzf bat eza fd-find git-delta ripgrep sd \
    ffmpeg jq mat2 \
    wl-clipboard xclip x11-apps \
    python3-full python3-pip python3-venv pipx \
    build-essential clang lldb clang-format clangd

  if ! is_wsl; then
    install_package \
      mpv alsa-utils alacritty snapd
  fi

  install_neovim() {
    # Add export PATH="$PATH:/opt/nvim-linux-x86_64/bin" to ~/.zshrc
    if command -v nvim &>/dev/null; then
      echo "✅ neovim is already installed"
      return 0
    fi

    local -r arch_type=$(uname -m)
    if [[ "${arch_type}" == "x86_64" ]]; then
      local -r download_dir="${HOME}/proj/tmp/packages"
      mkdir -pv "${download_dir}"
      echo ""
      echo "🔄 Downloading Neovim archive to ${download_dir}..."
      curl -fLo "${download_dir}/nvim-linux-x86_64.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      echo ""
      echo "🔄 Installing Neovim under /opt and linking /usr/local/bin/nvim..."
      sudo rm -rf /opt/nvim-linux-x86_64
      sudo tar -C /opt -xzf "${download_dir}/nvim-linux-x86_64.tar.gz"

      sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" /usr/local/bin/nvim
    else
      echo "❌ Unsupported Linux architecture: ${arch_type}"
      return 1
    fi
  }
  install_neovim

  install_zsh_plugins() {
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
        echo "🔄 Cloning ${name}..."
        git clone --depth 1 "${plugins[$name]}" "${target}"
      elif [[ -d "${target}/.git" ]]; then
        echo ""
        echo "🔄 Updating ${name}..."
        git -C "${target}" pull --ff-only
      else
        echo "⚠️ Skipping: ${name} (${target} exists but is not a git repository)"
      fi
    done
  }
  install_zsh_plugins

  :
} # }}}

setup_nvidia() { # {{{
  if ! is_nvidia_hardware_present; then
    return 0
  fi

  install_ubuntu_nvidia_drivers() {
    if ! lsmod | grep -qE "^nvidia"; then
      if command -v ubuntu-drivers &>/dev/null; then
        echo ""
        echo "🔄 Installing Canonical NVIDIA drivers..."
        sudo ubuntu-drivers install
      fi
    fi
  }

  enable_nvidia_kms() {
    local -r grub_file="/etc/default/grub"
    local -r kms_param="nvidia-drm.modeset=1"

    if ! grep -q "${kms_param}" "${grub_file}"; then
      echo ""
      echo "🔄 Configuring NVIDIA KMS..."
      sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)(\")/\1 ${kms_param}\2/" "${grub_file}"
      sudo update-grub
    fi
  }

  install_ubuntu_nvidia_drivers
  enable_nvidia_kms

  if ! command -v nvtop &>/dev/null; then
    install_package nvtop
  fi
} # }}}

make_default_directories() { # {{{
  mkdir -pv ~/Downloads
  mkdir -pv ~/Documents
  mkdir -pv ~/proj/personal
  mkdir -pv ~/proj/public
  mkdir -pv ~/proj/codeberg
  mkdir -pv ~/proj/work
  mkdir -pv ~/proj/tmp
} # }}}

make_RALT_to_HNGL() { # {{{
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
        echo "✅ Right Alt is already mapped to Hangul (Wayland/X11)."
        return 0
      fi

      echo ""
      echo "🔄 Remapping Right Alt to Hangul for Wayland/X11..."

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
      echo "⚠️ 'gsettings' not found. Skipping key remap."
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

install_node() { # {{{
  echo ""
  echo "🔄 Installing Node.js LTS from the NodeSource APT repository..."
  local -r setup_script="$(mktemp)"
  curl -fsSL "https://deb.nodesource.com/setup_lts.x" -o "${setup_script}"
  sudo -E bash "${setup_script}"
  rm -f "${setup_script}"
  sudo apt-get install -y nodejs

  local -r npm_prefix="${HOME}/.local"
  mkdir -p "${npm_prefix}/bin"
  npm config set prefix "${npm_prefix}"
  export npm_config_prefix="${npm_prefix}"
  export PATH="${npm_prefix}/bin:${PATH}"

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
  echo "🔄 Installing global JavaScript and TypeScript development tools with npm..."
  local package
  for package in "${npm_global_packages[@]}"; do
    if ! npm install -g "${package}"; then
      echo "⚠️ Failed to install npm package: ${package}"
    fi
  done
} # }}}

install_global_packages() { # {{{
  if ! command -v uv &>/dev/null; then
    echo ""
    echo "🔄 Installing uv from the upstream installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
  fi

  if command -v uv &>/dev/null; then
    echo ""
    echo "🔄 Installing Python runtime and uv-managed CLI tools..."
    uv python install
    uv tool install ruff
    uv tool install ty
    uv tool install pre-commit
    uv tool install "yt-dlp[default]" --with yt-dlp-ejs
  fi

  if ! command -v starship &>/dev/null; then
    echo ""
    echo "🔄 Installing Starship from the upstream installer..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
} # }}}

install_rust() { # {{{
  echo ""
  echo "🔄 Checking Rust build dependencies..."
  install_package pkg-config libssl-dev

  if ! command -v rustup &>/dev/null; then
    echo ""
    echo "🔄 Installing Rust toolchain with rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  . "${HOME}/.cargo/env"

  echo ""
  echo "🔄 Installing Rust components and cargo-managed developer tools..."
  rustup component add rust-analyzer rustfmt clippy

  install_cargo_bin() {
    local -r command_name="${1}"
    shift

    if ! command -v "${command_name}" &>/dev/null; then
      echo "Installing ${command_name} via cargo..."
      cargo install "${@}"
    else
      echo "✅ ${command_name} is already installed. Skipping..."
    fi
  }

  install_cargo_bin "cargo-watch" cargo-watch
  install_cargo_bin "cargo-install-update" cargo-update
  install_cargo_bin "stylua" stylua --features luajit
  # cargo install-update -a

} # }}}

install_nerd_font() { # {{{
  local -r font_name="JetBrainsMonoNLNerdFontMono"
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"
  local font_dir=""

  # Windows Font Directory = "/mnt/c/Windows/Fonts"
  case "$(uname)" in
  "Darwin") font_dir="${HOME}/Library/Fonts" ;;
  "Linux") font_dir="${HOME}/.local/share/fonts" ;;
  *)
    echo "⚠️ Unsupported OS"
    return 1
    ;;
  esac

  install_jetbrains_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "✅ ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo ""
    echo "🔄 Installing ${font_name} ${version}..."

    local -r temp_dir="${HOME}/proj/tmp/packages/nerd_fonts_setup"
    mkdir -pv "${temp_dir}"

    echo ""
    echo "🔄 Downloading font archive..."
    curl -fLo "${temp_dir}/JetBrainsMono.zip" "${download_url}" --retry 3

    echo ""
    echo "🔄 Extracting files..."
    unzip -o "${temp_dir}/JetBrainsMono.zip" -d "${temp_dir}"

    mkdir -pv "${font_dir}"

    find "${temp_dir}" -name "JetBrainsMonoNLNerdFontMono-*.ttf" -exec cp {} "${font_dir}/" \;

    if [ "$(uname)" = "Linux" ]; then
      echo ""
      echo "🔄 Updating font cache..."
      fc-cache -f "${font_dir}"
    fi

    # rm -rf "${temp_dir}"
    echo "✅ Font installation completed successfully!"
  }
  install_jetbrains_nerd_font
} # }}}

upgrade_packages() { # {{{
  echo ""
  echo "🔄 Upgrading system packages..."

  if sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"; then

    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
  else
    echo "⚠️ apt-get full-upgrade encountered an issue."
    return 1
  fi
} # }}}

setup_locale() { # {{{
  echo ""
  echo "🔄 Configuring system locale to en_US.UTF-8..."
  if command -v locale-gen &>/dev/null; then
    sudo locale-gen en_US.UTF-8
  else
    echo "⚠️ locale-gen not found. Skipping locale setup."
  fi
  sudo update-locale LANG=en_US.UTF-8
} # }}}

change_shell_to_zsh() { # {{{
  local -r zsh_path="$(command -v zsh)"
  if [ -n "${zsh_path}" ]; then
    local -r target_user="${SUDO_USER:-${USER}}"
    echo ""
    echo "🔄 Changing login shell for ${target_user} to ${zsh_path}..."
    sudo chsh -s "${zsh_path}" "${target_user}"
  else
    echo "⚠️ Zsh is not installed or not in PATH."
  fi
} # }}}

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
  echo "🔄 Applying basic desktop network privacy settings..."

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
  # - Review logs: sudo journalctl -k -g 'UFW'
  # - Follow logs live: sudo journalctl -k -f -g 'UFW'
  # - Disable UFW logging: sudo ufw logging off
  # - Disable UFW: sudo ufw disable
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw logging low
  echo "y" | sudo ufw enable
  sudo systemctl enable ufw.service >/dev/null 2>&1 || true

  # NetworkManager:
  # - This drop-in sets NetworkManager defaults. Existing profiles may still
  #   show ipv6.ip6-privacy=-1, which means "follow the default".
  # - Find values for <profile-name> and <ssid>:
  #     nmcli connection show
  #     nmcli -t -f active,ssid device wifi | rg '^yes:'
  # - Check a profile:
  #     nmcli connection show "<profile-name>" | rg 'connection.interface-name|ipv6.method|ipv6.ip6-privacy'
  # - Check effective IPv6 privacy:
  #     sysctl net.ipv6.conf.<wifi-interface>.use_tempaddr
  #     Expected: net.ipv6.conf.<wifi-interface>.use_tempaddr = 2
  # - Optional: pin privacy on one existing profile instead of using defaults:
  #     nmcli connection modify "<profile-name>" ipv6.ip6-privacy 2
  #     nmcli connection down "<profile-name>"
  #     nmcli connection up "<profile-name>"
  # - Optional: recreate a Wi-Fi profile:
  #     nmcli device wifi list
  #     nmcli connection delete "<profile-name>"
  #     Reconnect from GNOME Settings to avoid storing the Wi-Fi password in shell history.
  #     If not using the GUI:
  #       nmcli device wifi connect "<ssid>" password "<password>"
  #
  # Captive portal issue:
  # - Temporarily set wifi.cloned-mac-address=permanent.
  # - Reload NetworkManager: sudo systemctl reload NetworkManager.service
  # - Reconnect to that Wi-Fi network.
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/99-privacy.conf >/dev/null <<'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
# Random per-connection Wi-Fi MAC. Use "permanent" temporarily if a captive
# portal requires the hardware MAC to complete login.
wifi.cloned-mac-address=random
ipv6.ip6-privacy=2
EOF

  # Apply now if NetworkManager is running; otherwise it applies on next start.
  sudo systemctl reload NetworkManager.service 2>/dev/null || true
} # }}}

cleanup() { # {{{
  if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]] && kill -0 "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null; then
    kill "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null
  fi
} # }}}

main() { # {{{
  if (($# > 0)); then
    echo "❌ Error: setup_ubuntu_bootstrap.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  if is_ubuntu; then
    local -a tasks=(
      show_script_info
      keep_sudo_alive
    )

    tasks+=(
      install_basic_packages
      make_default_directories
    )

    tasks+=(
      install_node
      install_global_packages
      install_rust
      install_nerd_font
    )

    tasks+=(
      setup_nvidia
      make_RALT_to_HNGL
      upgrade_packages
      setup_locale
      change_shell_to_zsh
      setup_basic_network_privacy
    )
  else
    echo "❌ Error: Distro mismatch. Ubuntu only."
    exit 1
  fi

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      if ! "${task}"; then
        echo "❌ Task failed, continuing: ${task}"
        recover_package_state
      fi
      echo ""
      echo ""
      echo ""
    else
      echo "⚠️ Warning: Function '${task}' not found."
    fi
  done
} # }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap cleanup EXIT INT TERM ERR
  main "${@}"
fi
