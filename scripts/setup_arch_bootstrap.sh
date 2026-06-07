#!/usr/bin/env bash

# Bootstrap Arch Linux from a minimal/non-graphical install to a personal GNOME desktop.
# Keep desktop setup close to stock GNOME; add user workflow tooling only after the OS baseline works.

# Common helpers and environment detection {{{

start_logging() { # {{{
  local -r log_dir="${HOME}/tmp/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-setup-arch-bootstrap.log"

  if ! command -v tee >/dev/null 2>&1; then
    echo "ERROR: tee is required for logging." >&2
    exit 1
  fi

  if ! mkdir -p "${log_dir}"; then
    echo "ERROR: Could not create log directory: ${log_dir}" >&2
    exit 1
  fi

  if ! touch "${log_file}"; then
    echo "ERROR: Could not create log file: ${log_file}" >&2
    exit 1
  fi

  exec > >(tee -a "${log_file}") 2>&1

  echo "INFO: Log file: ${log_file}"
  echo ""
} # }}}

show_script_info() { # {{{
  echo "INFO: basename: ${0##*/}"
  echo "INFO: dirname : $(dirname "${0}")"
  echo "INFO: pwd     : $(pwd)"
  echo ""
} # }}}

find_and_move_to_dotfiles_root() { # {{{
  dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
    echo "ERROR: Unable to find dotfiles root from script location."
    return 1
  }

  echo "INFO: Dotfiles root: ${dotfiles_root}"
  cd "${dotfiles_root}" || {
    echo "ERROR: Unable to move to directory '${dotfiles_root}'."
    return 1
  }
} # }}}

is_arch() { # {{{
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "arch" ]]
  )
} # }}}

refuse_root_execution() { # {{{
  if ((EUID == 0)); then
    echo "ERROR: Do not run setup_arch_bootstrap.sh as root."
    echo "   Run it as your normal user; this script will use sudo when needed."
    exit 1
  fi
} # }}}

target_user() { # {{{
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf "%s\n" "${SUDO_USER}"
    return 0
  fi

  if [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
    printf "%s\n" "${USER}"
    return 0
  fi

  return 1
} # }}}

target_home() { # {{{
  local user_name="${1:-}"
  if [[ -z "${user_name}" ]]; then
    user_name="$(target_user)" || return 1
  fi

  local home_dir=""
  home_dir="$(getent passwd "${user_name}" | cut -d: -f6)"
  if [[ -z "${home_dir}" ]]; then
    return 1
  fi

  printf "%s\n" "${home_dir}"
} # }}}

run_as_target_user() { # {{{
  local user_name=""
  user_name="$(target_user)" || return 1

  local current_user=""
  current_user="$(id -un 2>/dev/null || true)"
  if [[ "${current_user}" == "${user_name}" ]]; then
    "${@}"
    return
  fi

  if command -v sudo &>/dev/null; then
    sudo -H -u "${user_name}" "${@}"
  elif ((EUID == 0)) && command -v runuser &>/dev/null; then
    runuser -u "${user_name}" -- "${@}"
  else
    echo "WARN: Could not run command as ${user_name}."
    return 1
  fi
} # }}}

run_as_root() { # {{{
  if ((EUID == 0)); then
    "${@}"
    return
  fi

  sudo "${@}"
} # }}}

# Common helpers and environment detection }}}

# Arch Linux system packages {{{

install_package() { # {{{
  local -a valid_pkgs=()
  local pkg

  for pkg in "${@}"; do
    if pacman -Qq "${pkg}" >/dev/null 2>&1; then
      echo "DONE: Package already installed: ${pkg}"
      continue
    fi

    if pacman -Si "${pkg}" >/dev/null 2>&1; then
      valid_pkgs+=("${pkg}")
    else
      echo "WARN: Skipping: ${pkg} (Not found in configured pacman repositories)"
    fi
  done

  if [[ ${#valid_pkgs[@]} -eq 0 ]]; then
    return 0
  fi

  # Do not refresh package databases here. Arch-based systems do not support
  # partial upgrades, so the full system upgrade stays centralized in upgrade_packages.
  run_as_root pacman -S --needed --noconfirm -- "${valid_pkgs[@]}" && return 0

  echo "WARN: Package batch install failed. Retrying packages one by one..."

  local failed=false
  for pkg in "${valid_pkgs[@]}"; do
    if pacman -Qq "${pkg}" >/dev/null 2>&1; then
      echo "DONE: Package already installed: ${pkg}"
      continue
    fi

    echo ""
    echo "INFO: Installing package: ${pkg}"
    run_as_root pacman -S --needed --noconfirm -- "${pkg}" || {
      echo "WARN: Failed to install package: ${pkg}"
      failed=true
    }
  done

  [[ "${failed}" == "false" ]]
} # }}}

install_package_group() { # {{{
  local group_name
  for group_name in "${@}"; do
    if ! pacman -Sgq "${group_name}" >/dev/null 2>&1; then
      echo "WARN: Skipping package group: ${group_name} (Not found in configured pacman repositories)"
      continue
    fi

    echo ""
    echo "INFO: Installing package group: ${group_name}"
    local -a group_packages=()
    mapfile -t group_packages < <(pacman -Sgq "${group_name}" | sort -u)
    install_package "${group_packages[@]}"
  done
} # }}}

upgrade_packages() { # {{{
  echo ""
  echo "INFO: Upgrading Arch Linux packages..."
  run_as_root pacman -Syu --noconfirm || {
    echo "ERROR: pacman system upgrade encountered an issue."
    return 1
  }
} # }}}

handle_hardware_drivers() { # {{{
  if ! command -v lspci &>/dev/null; then
    echo "WARN: lspci is not installed. Skipping hardware driver setup."
    return 0
  fi

  local pci_devices=""
  pci_devices="$(lspci 2>/dev/null || true)"
  local gpu_devices=""
  gpu_devices="$(grep -Ei "vga|3d|display" <<<"${pci_devices}" || true)"

  # Match GPU vendors only on VGA/3D/Display controller lines. Other PCI
  # devices can contain vendor names that would otherwise trigger false positives.
  if grep -qiE "intel" <<<"${gpu_devices}"; then
    echo "INFO: Intel graphics detected. Installing Intel Vulkan driver..."
    install_package vulkan-intel
  fi

  if grep -qiE "advanced micro devices|amd/ati|ati technologies" <<<"${gpu_devices}"; then
    echo "INFO: AMD graphics detected. Installing AMD Vulkan driver..."
    install_package vulkan-radeon
  fi

  if ! grep -qi nvidia <<<"${gpu_devices}"; then
    echo "INFO: No NVIDIA hardware detected."
    return 0
  fi

  echo "INFO: NVIDIA hardware detected."

  # Prefer Arch's current NVIDIA open-driver path for this personal bootstrap.
  # This intentionally does not parse NVIDIA generations from lspci output:
  # modern RTX/Blackwell-style systems should be handled automatically, while
  # very old GPUs will fail visibly or need a legacy AUR driver chosen manually.
  # Install a matching module package for each stock kernel that is present;
  # otherwise use DKMS so custom kernels can build their own module.
  local installed_stock_nvidia_module=false
  if pacman -Qq linux >/dev/null 2>&1; then
    install_package nvidia-open
    installed_stock_nvidia_module=true
  fi

  if pacman -Qq linux-lts >/dev/null 2>&1; then
    install_package nvidia-open-lts
    installed_stock_nvidia_module=true
  fi

  if [[ "${installed_stock_nvidia_module}" == "false" ]]; then
    install_package nvidia-open-dkms
  fi

  install_package nvidia-utils

  # 32-bit Vulkan/OpenGL support is only available when multilib is enabled.
  # These packages are needed for Steam, Proton, Wine, and other 32-bit runtime
  # users. If install_package skips them, enable multilib in /etc/pacman.conf:
  #
  #   [multilib]
  #   Include = /etc/pacman.d/mirrorlist
  #
  # Then refresh package databases and rerun this script:
  #
  #   sudo pacman -Syu
  #
  # Keep this manual because enabling a repository is an OS-level policy choice.
  # install_package will skip these cleanly on systems that keep multilib off.
  install_package lib32-nvidia-utils lib32-vulkan-icd-loader

  # Rebuild initramfs after changing the GPU kernel module stack. Package hooks
  # usually cover this, but doing it here makes a nouveau -> nvidia-open bootstrap
  # transition explicit and easier to diagnose from the install log.
  # mkinitcpio may warn about optional firmware such as qat_6xxx. That module is
  # for Intel QuickAssist-style compression/encryption acceleration in server or
  # workstation-class hardware, not a normal personal desktop/laptop requirement.
  if command -v mkinitcpio &>/dev/null; then
    run_as_root mkinitcpio -P || {
      echo "WARN: Failed to rebuild initramfs after NVIDIA driver installation."
    }
  fi

  echo "INFO: Reboot after NVIDIA driver installation, then verify with nvidia-smi and vulkaninfo --summary."
} # }}}

install_base_packages() { # {{{
  echo ""
  echo "INFO: Installing Arch Linux packages..."

  # Base CLI and build packages that belong to the central package phase.
  # Required by follow-up user tool setup:
  # - install_zsh_plugins: git
  # - install_yay: base-devel, git
  # - install_mise_managed_tools: curl
  # - install_nerd_font: curl, unzip, fontconfig
  # VeraCrypt workflows need fuse2 for legacy FUSE integration and exfatprogs
  # for exFAT volumes.
  install_package \
    zsh tmux \
    git curl wget ca-certificates \
    openssl openssh fuse2 \
    zlib bzip2 readline sqlite libffi xz \
    exfatprogs zip unzip 7zip \
    tree mat2 fontconfig \
    wl-clipboard \
    base-devel clang lldb

  # Required by follow-up OS setup tasks. Keep the package installation here so
  # those tasks only configure state, enable services, or run user-level installers:
  # - handle_hardware_drivers: pciutils, mesa, mesa-utils, vulkan-icd-loader, vulkan-tools
  # - setup_locale: glibc
  # - set_default_shell_to_zsh: util-linux
  # - setup_ibus_hangul_gnome: xkeyboard-config
  # - setup_basic_firewall: firewalld
  # - setup_networkmanager_privacy: networkmanager
  # Storage wipe workflows need cryptsetup, gptfdisk, hdparm, and nvme-cli for
  # LUKS erase, partition cleanup, SATA secure erase, and NVMe sanitize/format.
  # Hardware-specific GPU drivers still stay in handle_hardware_drivers because
  # they should be installed only after detecting the actual GPU vendor/kernel.
  install_package \
    glibc util-linux \
    pciutils mesa mesa-utils vulkan-icd-loader vulkan-tools \
    cryptsetup gptfdisk hdparm nvme-cli \
    xkeyboard-config \
    networkmanager firewalld

  # Required by setup_gnome_desktop. That function only enables services and
  # sets the graphical boot target.
  install_package_group gnome
  install_package \
    gdm \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-settings-daemon \
    nautilus \
    gnome-keyring \
    gnome-tweaks \
    gnome-shell-extension-appindicator \
    power-profiles-daemon \
    switcheroo-control \
    bluez bluez-utils \
    cups system-config-printer bluez-cups \
    xdg-desktop-portal-gnome

  # Required by setup_ibus_hangul_gnome:
  # ibus, ibus-hangul, noto-fonts-cjk, glib2, dconf, dbus.
  # Audio/video packages stay here with the desktop package phase so providers
  # such as pipewire-jack are selected explicitly before ffmpeg/mpv pull them in.
  # Keep alsa-utils available for hardware mixer controls such as disabling HDA
  # Auto-Mute Mode; PipeWire does not own those codec-level switches.
  install_package \
    ibus ibus-hangul noto-fonts-cjk glib2 dconf dbus \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    alsa-utils \
    ffmpeg \
    gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    mpv alacritty firefox \
    veracrypt \
    xdg-utils \
    flatpak

  if command -v flatpak &>/dev/null; then
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
      echo "WARN: Failed to add Flathub remote."
    }
  fi
} # }}}

# Arch Linux system packages }}}

# Arch Linux desktop and system configuration {{{

setup_gnome_desktop() { # {{{
  echo ""
  echo "INFO: Enabling GNOME desktop services..."

  if ! pacman -Qq gdm >/dev/null 2>&1; then
    echo "ERROR: gdm is not installed. Skipping display manager changes."
    return 1
  fi

  if ! command -v systemctl &>/dev/null; then
    echo "WARN: systemctl is not available. Skipping GNOME display manager setup."
    return 0
  fi

  # Display managers own the same display-manager.service alias. Disable common
  # alternatives first so enabling GDM has a predictable owner after reboot.
  run_as_root systemctl disable sddm.service lightdm.service lxdm.service ly.service 2>/dev/null || true
  run_as_root systemctl enable --force gdm.service || {
    echo "WARN: Failed to enable gdm.service."
  }
  run_as_root systemctl enable --now power-profiles-daemon.service || {
    echo "WARN: Failed to enable power-profiles-daemon.service."
  }
  run_as_root systemctl enable --now switcheroo-control.service || {
    echo "WARN: Failed to enable switcheroo-control.service."
  }
  run_as_root systemctl enable --now bluetooth.service || {
    echo "WARN: Failed to enable bluetooth.service."
  }
  run_as_root systemctl enable --now cups.service || {
    echo "WARN: Failed to enable cups.service."
  }
  run_as_root systemctl set-default graphical.target || {
    echo "WARN: Failed to set graphical.target as the default boot target."
  }
} # }}}

setup_ibus_hangul_gnome() { # {{{
  echo ""
  echo "INFO: Configuring IBus Hangul for GNOME..."

  if ! command -v gsettings &>/dev/null; then
    echo "WARN: gsettings is not installed. Skipping GNOME input source setup."
    return 0
  fi

  local -r schema="org.gnome.desktop.input-sources"
  local -r sources_key="sources"
  local -r xkb_key="xkb-options"
  local -r hangul_source="('ibus', 'hangul')"
  local -r default_sources="[('xkb', 'us'), ${hangul_source}]"
  local -r hangul_option="'korean:ralt_hangul'"

  user_gsettings() {
    local command_text="${1}"
    if command -v dbus-run-session &>/dev/null; then
      run_as_target_user dbus-run-session -- bash -lc "${command_text}"
    else
      run_as_target_user bash -lc "${command_text}"
    fi
  }

  HNGL_Wayland() {
    # GNOME defaults to Wayland, and this path only changes user GNOME settings.
    # Use the X11 keycode patch only when the current session is explicitly X11.
    if [[ "${XDG_SESSION_TYPE:-}" == "x11" ]]; then
      return 0
    fi

    # 1. Get current XKB options
    local current_value
    current_value="$(user_gsettings "gsettings get ${schema} ${xkb_key}" 2>/dev/null || true)"

    # 2. Check if the option is already active
    if [[ "${current_value}" == *"${hangul_option}"* ]]; then
      echo "DONE: Right Alt is already mapped to Hangul (Wayland/X11)."
      return 0
    fi

    echo ""
    echo "INFO: Remapping Right Alt to Hangul for Wayland/X11..."

    # 3. Append the option safely
    if [[ "${current_value}" == "@as []" || "${current_value}" == "[]" || -z "${current_value}" ]]; then
      # If empty, set it directly
      user_gsettings "gsettings set ${schema} ${xkb_key} \"['korean:ralt_hangul']\"" || {
        echo "WARN: Failed to configure GNOME XKB options."
      }
    else
      # If not empty, append it (removing the closing bracket ']')
      # e.g., ['caps:escape'] -> ['caps:escape', 'korean:ralt_hangul']
      local new_value="${current_value%]}"
      new_value="${new_value}, ${hangul_option}]"
      user_gsettings "gsettings set ${schema} ${xkb_key} \"${new_value}\"" || {
        echo "WARN: Failed to append GNOME Hangul XKB option."
      }
    fi
  }

  HNGL_X11() {
    # The X11 fallback intentionally patches xkeyboard-config only when this
    # script is run from an active X11 session. A future switch from GNOME
    # Wayland to GNOME on Xorg needs this script to be run again, or the backup
    # and sed steps below to be applied manually.
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

    run_as_root bash <<SUDO_SCRIPT
  cp "${target_file}" "${target_file}.$(date +%Y%m%d-%H%M%S).bak"
  # 1. Comment out '<RALT> = 108;' and add '<HNGL> = 108;' right below it
  sed -i '/^[[:space:]]*<RALT>[[:space:]]*=[[:space:]]*108;/c\// <RALT> = 108;\n<HNGL> = 108;' "${target_file}"
  # 2. Comment out the existing '<HNGL> = 130;' line
  sed -i 's/^[[:space:]]*<HNGL>[[:space:]]*=[[:space:]]*130;/ \/\/ <HNGL> = 130;/g' "${target_file}"
SUDO_SCRIPT
  }

  local current_sources=""
  current_sources="$(user_gsettings "gsettings get ${schema} ${sources_key}" 2>/dev/null || true)"

  # Configure the GNOME input source list first so IBus Hangul is available in
  # the desktop UI. The Right Alt mapping is handled separately below because
  # Wayland and X11 need different mechanisms.
  if [[ "${current_sources}" == *"${hangul_source}"* ]]; then
    echo "DONE: GNOME IBus Hangul input source is already configured."
  elif [[ "${current_sources}" == "@a(ss) []" || "${current_sources}" == "[]" || -z "${current_sources}" ]]; then
    user_gsettings "gsettings set ${schema} ${sources_key} \"${default_sources}\"" || {
      echo "WARN: Failed to configure GNOME input sources."
    }
  else
    local new_sources="${current_sources%]}"
    new_sources="${new_sources}, ${hangul_source}]"
    user_gsettings "gsettings set ${schema} ${sources_key} \"${new_sources}\"" || {
      echo "WARN: Failed to append GNOME IBus Hangul input source."
    }
  fi

  HNGL_Wayland
  HNGL_X11

  # How to rollback
  # --------------------------------------------------------
  # **Wayland**
  # Step 1) Check current state
  # gsettings get org.gnome.desktop.input-sources xkb-options
  # Step 2)
  # gsettings set org.gnome.desktop.input-sources xkb-options "[]"
  # Step 3)
  # sudo reboot
  #
  # **X11**
  # Step 1) Check if backup files exist
  # ls /usr/share/X11/xkb/keycodes/evdev.*.bak
  # Step 2)
  # sudo cp /usr/share/X11/xkb/keycodes/evdev.<BACKUP_DATE>.bak /usr/share/X11/xkb/keycodes/evdev
  # Step 3)
  # sudo reboot
} # }}}

setup_locale() { # {{{
  if locale -a 2>/dev/null | grep -Fxq "en_US.utf8" && localectl status 2>/dev/null | grep -Eq '^System Locale: LANG=en_US\.UTF-8$'; then
    echo "DONE: System locale is already UTF-8."
    return 0
  fi

  echo ""
  echo "INFO: Configuring system locale to en_US.UTF-8..."

  if [[ -f /etc/locale.gen ]]; then
    if grep -Eq '^#?en_US\.UTF-8 UTF-8$' /etc/locale.gen; then
      run_as_root sed -i 's/^#\(en_US\.UTF-8 UTF-8\)$/\1/' /etc/locale.gen
    else
      echo "en_US.UTF-8 UTF-8" | run_as_root tee -a /etc/locale.gen >/dev/null
    fi
  else
    echo "WARN: /etc/locale.gen not found. locale-gen may not generate en_US.UTF-8."
  fi

  if command -v locale-gen &>/dev/null; then
    run_as_root locale-gen || {
      echo "WARN: Failed to generate locales."
    }
  else
    echo "WARN: locale-gen is not available. Skipping locale generation."
  fi

  run_as_root localectl set-locale LANG=en_US.UTF-8 || {
    echo "WARN: Failed to configure system locale."
  }
} # }}}

set_default_shell_to_zsh() { # {{{
  local -r zsh_path="$(command -v zsh)"
  if [[ -z "${zsh_path}" ]]; then
    echo "WARN: zsh is not installed or not in PATH."
    return 0
  fi

  if ! command -v chsh &>/dev/null; then
    echo "WARN: chsh is not available. Skipping default shell setup."
    return 0
  fi

  if [[ -f /etc/shells ]] && ! grep -Fxq "${zsh_path}" /etc/shells; then
    echo "WARN: ${zsh_path} is not listed in /etc/shells. Skipping default shell setup."
    return 0
  fi

  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "WARN: Could not identify a non-root target user. Skipping default shell setup."
    return 0
  }

  local current_shell=""
  current_shell="$(getent passwd "${target_user_name}" | cut -d: -f7)"
  if [[ -z "${current_shell}" ]]; then
    echo "WARN: Could not find login shell for ${target_user_name}. Skipping default shell setup."
    return 0
  fi

  if [[ "${current_shell}" == "${zsh_path}" ]]; then
    echo "DONE: Login shell for ${target_user_name} is already ${zsh_path}"
    return 0
  fi

  echo ""
  echo "INFO: Changing login shell for ${target_user_name} to ${zsh_path}..."
  run_as_root chsh -s "${zsh_path}" "${target_user_name}"
} # }}}

# Arch Linux desktop and system configuration }}}

# User tool setup {{{

create_default_directories() { # {{{
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping default directory setup."
    return 0
  }

  run_as_target_user mkdir -pv "${home_dir}/Downloads"
  run_as_target_user mkdir -pv "${home_dir}/Documents"
  run_as_target_user mkdir -pv "${home_dir}/tmp"

  _PROJECTS_HOME="${home_dir}/Projects"
  run_as_target_user mkdir -pv "${_PROJECTS_HOME}/work"
  run_as_target_user mkdir -pv "${_PROJECTS_HOME}/personal"
  run_as_target_user mkdir -pv "${_PROJECTS_HOME}/opensource"
  run_as_target_user mkdir -pv "${_PROJECTS_HOME}/playground"
  run_as_target_user mkdir -pv "${_PROJECTS_HOME}/experiments"
} # }}}

install_zsh_plugins() { # {{{
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping zsh plugin setup."
    return 0
  }

  local -r zsh_dir="${home_dir}/.zsh"
  run_as_target_user mkdir -p "${zsh_dir}"

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
      run_as_target_user git clone --depth 1 "${plugins[$name]}" "${target}" || {
        echo "WARN: Failed to clone zsh plugin: ${name}"
      }
    elif [[ -d "${target}/.git" ]]; then
      echo ""
      echo "INFO: Updating ${name}..."
      run_as_target_user git -C "${target}" pull --ff-only || {
        echo "WARN: Failed to update zsh plugin: ${name}"
      }
    else
      echo "WARN: Skipping: ${name} (${target} exists but is not a git repository)"
    fi
  done
} # }}}

install_yay() { # {{{
  # yay is convenient for a personal Arch workstation, but AUR availability is
  # outside this repo's control. Failure here should not block the rest of setup.
  if run_as_target_user bash -lc "command -v yay >/dev/null 2>&1"; then
    echo "DONE: yay is already installed."
    return 0
  fi

  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping yay setup."
    return 0
  }

  local -r yay_dir="${home_dir}/tmp/packages/yay"
  run_as_target_user mkdir -pv "$(dirname "${yay_dir}")"

  if [[ ! -d "${yay_dir}" ]]; then
    echo ""
    echo "INFO: Cloning yay from AUR..."
    run_as_target_user git clone https://aur.archlinux.org/yay.git "${yay_dir}" || {
      echo "WARN: Failed to clone yay from AUR."
      return 0
    }
  elif [[ -d "${yay_dir}/.git" ]]; then
    echo ""
    echo "INFO: Updating yay AUR checkout..."
    run_as_target_user git -C "${yay_dir}" pull --ff-only || {
      echo "WARN: Failed to update yay AUR checkout."
      return 0
    }
  else
    echo "WARN: Skipping yay setup: ${yay_dir} exists but is not a git repository."
    return 0
  fi

  echo ""
  echo "INFO: Building and installing yay..."
  run_as_target_user bash -lc "cd \"${yay_dir}\" && makepkg --syncdeps --install --needed --noconfirm" || {
    echo "WARN: Failed to build or install yay."
  }
} # }}}

install_mise_managed_tools() { # {{{
  local mise_config="${dotfiles_root}/config/mise/config.toml"

  if [[ ! -f "${mise_config}" ]]; then
    echo "ERROR: mise config not found: ${mise_config}"
    return 1
  fi

  if ! run_as_target_user bash -lc "export PATH=\"\${HOME}/.local/bin:\${PATH}\"; command -v mise >/dev/null 2>&1"; then
    echo ""
    echo "INFO: Installing mise from the upstream installer..."
    run_as_target_user bash -lc 'curl https://mise.run | sh'
  fi

  if ! run_as_target_user bash -lc "export PATH=\"\${HOME}/.local/bin:\${PATH}\"; command -v mise >/dev/null 2>&1"; then
    echo "ERROR: mise is not available after installation."
    return 1
  fi

  echo ""
  echo "INFO: Installing mise-managed tools from ${mise_config}..."
  # Let HOME/PATH expand inside the target user's shell, not in this bootstrap shell.
  # shellcheck disable=SC2016
  run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    mise trust --yes "${1}" || true
    mise install --yes --cd "$(dirname "${1}")"
  ' bash "${mise_config}"
} # }}}

install_user_cli_tools() { # {{{
  local -r mise_config_dir="${dotfiles_root}/config/mise"

  # Let HOME/PATH expand inside the target user's shell, not in this bootstrap shell.
  # shellcheck disable=SC2016
  if ! run_as_target_user bash -lc 'export PATH="${HOME}/.local/bin:${PATH}"; command -v mise >/dev/null 2>&1'; then
    echo "WARN: mise is not installed. Skipping user CLI tool setup."
    return 0
  fi

  echo ""
  echo "INFO: Installing Rust development components..."
  # Use mise exec instead of shell activation so tools installed earlier in this
  # bootstrap are available immediately, before a fresh login shell exists.
  # shellcheck disable=SC2016
  run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    mise exec --cd "${1}" -- rustup component add rust-src rustfmt clippy
  ' bash "${mise_config_dir}" || {
    echo "WARN: Failed to install Rust development components."
  }

  echo ""
  echo "INFO: Installing Cargo-managed Rust CLI tools..."
  # shellcheck disable=SC2016
  run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    mise exec --cd "${1}" -- cargo-binstall --no-confirm cargo-watch
  ' bash "${mise_config_dir}" || {
    echo "WARN: Failed to install Cargo-managed Rust CLI tools."
  }

  echo ""
  echo "INFO: Installing uv-managed CLI tools..."
  # shellcheck disable=SC2016
  run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    mise exec --cd "${1}" -- uv tool install "yt-dlp[default,curl-cffi]"
  ' bash "${mise_config_dir}" || {
    echo "WARN: Failed to install yt-dlp[default,curl-cffi]."
  }
} # }}}

install_nerd_font() { # {{{
  # Windows Font Directory = "/mnt/c/Windows/Fonts"

  local -r font_name="JetBrainsMonoNLNerdFontMono"
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping font setup."
    return 0
  }

  local -r font_dir="${home_dir}/.local/share/fonts"

  install_jetbrains_nerd_font() {
    if find "${font_dir}" -name "*${font_name}*" | grep -q "."; then
      echo "DONE: ${font_name} is already installed. Skipping..."
      return 0
    fi

    echo ""
    echo "INFO: Installing ${font_name} ${version}..."

    local -r temp_dir="${home_dir}/tmp/packages/nerd_fonts_setup"
    run_as_target_user mkdir -pv "${temp_dir}"

    echo ""
    echo "INFO: Downloading font archive..."
    run_as_target_user curl -fLo "${temp_dir}/JetBrainsMono.zip" "${download_url}" --retry 3 || {
      echo "WARN: Failed to download ${font_name}."
      return 0
    }

    echo ""
    echo "INFO: Extracting files..."
    run_as_target_user unzip -o "${temp_dir}/JetBrainsMono.zip" -d "${temp_dir}" || {
      echo "WARN: Failed to extract ${font_name} archive."
      return 0
    }

    run_as_target_user mkdir -pv "${font_dir}"

    run_as_target_user bash -lc "find \"${temp_dir}\" -name 'JetBrainsMonoNLNerdFontMono-*.ttf' -exec cp {} \"${font_dir}/\" \;" || {
      echo "WARN: Failed to copy ${font_name} files."
      return 0
    }

    echo ""
    echo "INFO: Updating font cache..."
    run_as_target_user fc-cache -f "${font_dir}" || {
      echo "WARN: Failed to update font cache."
      return 0
    }

    echo "DONE: Font installation completed successfully!"
  }
  install_jetbrains_nerd_font
} # }}}

# User tool setup }}}

# Arch Linux network privacy {{{

setup_basic_firewall() { # {{{
  setup_firewalld_firewall() {
    echo ""
    echo "INFO: Configuring firewalld firewall..."

    # firewalld:
    # - Existing zones and rules are preserved; do not reset the firewall.
    # - Add allow rules manually for inbound SSH or dev servers.
    #   Examples:
    #     sudo firewall-cmd --permanent --add-service=ssh
    #     sudo firewall-cmd --permanent --add-port=8080/tcp
    #     sudo firewall-cmd --reload
    #
    # Commands:
    # - Review rules: sudo firewall-cmd --list-all
    # - Disable firewalld: sudo systemctl disable --now firewalld.service
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl enable --now firewalld.service || {
        echo "WARN: Failed to enable firewalld."
      }
    else
      echo "WARN: systemctl is not available. Skipping firewalld service setup."
      return 0
    fi

    if [[ -n "${SSH_CONNECTION:-}" ]]; then
      echo "INFO: SSH session detected. Ensuring inbound SSH remains allowed in firewalld..."
      run_as_root firewall-cmd --permanent --add-service=ssh || {
        echo "WARN: Failed to add an SSH allow rule in firewalld."
      }

      run_as_root firewall-cmd --reload || {
        echo "WARN: Failed to reload firewalld after adding SSH allow rule."
      }
    fi

    if command -v ufw &>/dev/null; then
      run_as_root systemctl disable --now ufw.service >/dev/null 2>&1 || true
    fi
  }

  setup_ufw_firewall() {
    echo ""
    echo "INFO: Configuring UFW firewall..."

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
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl disable --now firewalld.service >/dev/null 2>&1 || true
    fi

    if [[ -n "${SSH_CONNECTION:-}" ]]; then
      echo "INFO: SSH session detected. Ensuring inbound SSH remains allowed before enabling UFW..."
      run_as_root ufw allow OpenSSH || run_as_root ufw allow 22/tcp || {
        echo "WARN: Failed to add an SSH allow rule before enabling UFW."
      }
    fi

    run_as_root ufw default deny incoming
    run_as_root ufw default allow outgoing
    run_as_root ufw logging low
    echo "y" | run_as_root ufw enable || {
      echo "WARN: Failed to enable UFW."
    }
    if command -v systemctl &>/dev/null; then
      run_as_root systemctl enable ufw.service >/dev/null 2>&1 || true
    fi
  }

  ufw_is_selected() {
    command -v ufw &>/dev/null || return 1

    # Treat UFW as selected only when it is active/enabled. This keeps firewalld
    # as the default when UFW merely exists on the system but is not in use.
    if command -v systemctl &>/dev/null; then
      systemctl is-active --quiet ufw.service || systemctl is-enabled --quiet ufw.service
      return
    fi

    run_as_root ufw status 2>/dev/null | grep -qi "^Status: active"
  }

  # firewalld is the default for Arch GNOME/NetworkManager desktops. Prefer it
  # when installed, disable UFW if both exist, and install firewalld when no
  # firewall backend exists. Use UFW only when it is active/enabled and firewalld
  # is not installed.
  if pacman -Qq firewalld >/dev/null 2>&1; then
    echo "INFO: Selected firewall backend: firewalld (installed Arch default)."
    setup_firewalld_firewall
  elif ufw_is_selected; then
    echo "INFO: Selected firewall backend: UFW (active or enabled)."
    setup_ufw_firewall
  else
    echo "INFO: Selected firewall backend: firewalld (default)."
    setup_firewalld_firewall
  fi
} # }}}

setup_networkmanager_privacy() { # {{{
  if ! command -v nmcli &>/dev/null; then
    if ! command -v systemctl &>/dev/null || ! systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
      echo "WARN: NetworkManager is not installed. Skipping NetworkManager privacy settings."
      return 0
    fi
  fi

  if command -v systemctl &>/dev/null; then
    run_as_root systemctl enable --now NetworkManager.service || {
      echo "WARN: Failed to enable NetworkManager."
    }
  fi

  local nm_privacy_config="${dotfiles_root}/config/system/NetworkManager/conf.d/99-privacy.conf"

  if [[ ! -f "${nm_privacy_config}" ]]; then
    echo "WARN: NetworkManager privacy config not found: ${nm_privacy_config}"
    return 0
  fi

  run_as_root install -Dm0644 "${nm_privacy_config}" /etc/NetworkManager/conf.d/99-privacy.conf

  # Apply now if NetworkManager is running; otherwise it applies on next start.
  if command -v systemctl &>/dev/null; then
    run_as_root systemctl reload NetworkManager.service 2>/dev/null || {
      echo "WARN: NetworkManager is not running; privacy settings will apply later."
    }
  fi
} # }}}

setup_basic_network_privacy() { # {{{
  # Goal:
  # - Provide conservative desktop/laptop defaults for everyday Arch Linux use.
  # - Block unsolicited inbound traffic with one firewall backend.
  # - Enable Wi-Fi MAC randomization and IPv6 privacy addresses.
  #
  # Non-goals:
  # - Do not implement aggressive network hardening.
  # - Do not change DNS, systemd-resolved, routing, VPN behavior, or existing
  #   firewall rules beyond the selected backend's default policy.
  # - Do not run "ufw reset" or "firewall-cmd --complete-reload" style resets.
  echo ""
  echo "INFO: Applying basic desktop network privacy settings..."

  setup_basic_firewall
  setup_networkmanager_privacy
} # }}}

# Arch Linux network privacy }}}

# Completion notice {{{

show_reboot_notice() { # {{{
  echo ""
  echo "DONE: Bootstrap complete. A reboot is recommended."
  echo "INFO: If WARN lines appeared, reboot or start a fresh login shell, then rerun this script."
  echo ""
  echo "Reboot command:"
  echo "  sudo reboot"
} # }}}

# Completion notice }}}

# Main {{{

main() { # {{{
  start_logging

  if (($# > 0)); then
    echo "ERROR: setup_arch_bootstrap.sh does not accept options."
    echo "   Run without arguments."
    exit 1
  fi

  if ! is_arch; then
    echo "ERROR: Distro mismatch. Arch Linux only."
    exit 1
  fi

  refuse_root_execution
  find_and_move_to_dotfiles_root

  local -a tasks=(
    show_script_info
    upgrade_packages
    install_base_packages
    handle_hardware_drivers
    setup_locale
    setup_gnome_desktop
    setup_ibus_hangul_gnome
    set_default_shell_to_zsh
    create_default_directories
    install_zsh_plugins
    install_yay
    install_mise_managed_tools
    install_user_cli_tools
    install_nerd_font
    setup_basic_network_privacy
  )

  local task
  for task in "${tasks[@]}"; do
    if declare -f "${task}" >/dev/null; then
      echo "============================================================"
      echo "${task}"
      echo "============================================================"
      if ! "${task}"; then
        if [[ "${task}" == "upgrade_packages" ]]; then
          echo "ERROR: System upgrade failed. Stop before installing additional packages."
          exit 1
        fi
        echo "ERROR: Task failed, continuing: ${task}"
      fi
      echo ""
      echo ""
      echo ""
    else
      echo "WARN: Function '${task}' not found."
    fi
  done

  show_reboot_notice
} # }}}

# Main }}}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
