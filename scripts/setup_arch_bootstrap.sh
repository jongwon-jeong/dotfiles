#!/usr/bin/env bash

# Bootstrap Arch Linux from a minimal/non-graphical install to a personal Sway desktop.
# Keep the OS baseline Arch-native and the graphical session Wayland-first.

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

is_wsl() { # {{{
  grep -qi microsoft /proc/version 2>/dev/null
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

replace_package_before_install() { # {{{
  local desired_pkg="${1:-}"
  shift || true

  if [[ -z "${desired_pkg}" ]]; then
    echo "WARN: replace_package_before_install requires a desired package."
    return 1
  fi

  if pacman -Qq "${desired_pkg}" >/dev/null 2>&1; then
    echo "DONE: Preferred package already installed: ${desired_pkg}"
    return 0
  fi

  local old_pkg
  for old_pkg in "${@}"; do
    if ! pacman -Qq "${old_pkg}" >/dev/null 2>&1; then
      continue
    fi

    echo ""
    echo "INFO: Replacing ${old_pkg} with ${desired_pkg}..."
    # pacman answers package conflict removal prompts with No under --noconfirm.
    # Remove only explicitly listed alternatives so provider choices stay local
    # to the caller instead of becoming broad automatic conflict resolution.
    run_as_root pacman -Rdd --noconfirm "${old_pkg}" || {
      echo "WARN: Failed to remove ${old_pkg} before installing ${desired_pkg}."
      return 1
    }
  done

  install_package "${desired_pkg}"
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
  if is_wsl; then
    return 0
  fi

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

  local failed=false
  install_required_packages() {
    local -a available_packages=()
    local pkg
    for pkg in "${@}"; do
      if pacman -Qq "${pkg}" >/dev/null 2>&1 || pacman -Si "${pkg}" >/dev/null 2>&1; then
        available_packages+=("${pkg}")
      else
        echo "ERROR: Required package not found in configured pacman repositories: ${pkg}"
        failed=true
      fi
    done

    if [[ ${#available_packages[@]} -gt 0 ]]; then
      install_package "${available_packages[@]}" || failed=true

      # Desktop requirements stay explicit even when another package pulled
      # them in first. This protects the Sway baseline during orphan cleanup.
      local -a installed_packages=()
      for pkg in "${available_packages[@]}"; do
        if pacman -Qq "${pkg}" >/dev/null 2>&1; then
          installed_packages+=("${pkg}")
        fi
      done

      if [[ ${#installed_packages[@]} -gt 0 ]]; then
        run_as_root pacman -D --asexplicit -- "${installed_packages[@]}" || {
          echo "ERROR: Failed to mark required packages as explicitly installed."
          failed=true
        }
      fi
    fi
  }

  install_required_package_groups() {
    local -a available_groups=()
    local group_name
    for group_name in "${@}"; do
      if pacman -Sgq "${group_name}" >/dev/null 2>&1; then
        available_groups+=("${group_name}")
      else
        echo "ERROR: Required package group not found in configured pacman repositories: ${group_name}"
        failed=true
      fi
    done

    if [[ ${#available_groups[@]} -gt 0 ]]; then
      install_package_group "${available_groups[@]}" || failed=true
    fi
  }

  # Portable CLI and development packages shared by Arch desktops and WSL.
  install_required_packages \
    zsh tmux \
    git curl wget ca-certificates \
    openssl openssh fuse2 \
    zlib bzip2 readline sqlite libffi xz \
    exfatprogs zip unzip 7zip \
    tree mat2 fontconfig \
    wl-clipboard \
    base-devel clang lldb \
    util-linux

  if is_wsl; then
    install_required_packages ffmpeg
    [[ "${failed}" == "false" ]]
    return
  fi

  # OS-owned hardware, storage, firmware, and network foundations.
  install_required_packages \
    glibc util-linux \
    pciutils mesa mesa-utils vulkan-icd-loader vulkan-tools \
    cryptsetup gptfdisk hdparm nvme-cli \
    fwupd \
    xkeyboard-config \
    networkmanager firewalld

  # Wayland compositor, login, portal, and compatibility boundary.
  install_required_packages \
    sway swaybg swayidle swaylock \
    greetd greetd-regreet cage \
    xorg-xwayland \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    xdg-utils xdg-user-dirs \
    qt5-wayland qt6-wayland

  # Desktop shell and hardware-adaptive conveniences. Battery and backlight
  # clients remain inert when their matching laptop hardware does not exist.
  install_required_packages \
    waybar swaync fuzzel swayosd \
    kanshi wdisplays \
    grim slurp cliphist wf-recorder \
    batsignal wlsunset \
    brightnessctl playerctl \
    network-manager-applet \
    bluez bluez-utils blueman \
    polkit lxqt-policykit \
    gnome-keyring libsecret \
    upower power-profiles-daemon switcheroo-control \
    udisks2 udiskie \
    cups system-config-printer bluez-cups \
    libnotify papirus-icon-theme

  # Fcitx modules cover native GTK/Qt Wayland clients and XWayland fallbacks.
  install_required_package_groups fcitx5-im
  install_required_packages fcitx5-hangul

  # Audio, media, and user-facing applications selected for this workstation.
  replace_package_before_install pipewire-jack jack2 || failed=true
  install_required_packages \
    noto-fonts-cjk noto-fonts-emoji glib2 dbus \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber gst-plugin-pipewire \
    alsa-utils pavucontrol \
    ffmpeg libheif poppler-data \
    gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    mpv alacritty thunar tumbler thunar-volman thunar-archive-plugin xarchiver gvfs \
    imv zathura zathura-pdf-mupdf \
    veracrypt \
    flatpak

  if command -v flatpak &>/dev/null; then
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
      echo "WARN: Failed to add Flathub remote."
    }
  fi

  [[ "${failed}" == "false" ]]
} # }}}

# Arch Linux system packages }}}

# Arch Linux desktop and system configuration {{{

deploy_dotfiles() { # {{{
  local -r setup_script="${dotfiles_root}/scripts/setup_dotfiles.sh"

  if [[ ! -x "${setup_script}" ]]; then
    echo "ERROR: Dotfile deployment script is missing or not executable: ${setup_script}"
    return 1
  fi

  echo ""
  echo "INFO: Deploying user configuration..."
  run_as_target_user "${setup_script}"
} # }}}

setup_sway_user_preferences() { # {{{
  if is_wsl; then
    return 0
  fi

  local target_user_home=""
  target_user_home="$(target_home)" || {
    echo "ERROR: Could not identify the target home for Sway preferences."
    return 1
  }

  local -r kanshi_local_config="${target_user_home}/.config/kanshi/local.conf"
  if [[ ! -e "${kanshi_local_config}" && ! -L "${kanshi_local_config}" ]]; then
    # Machine-specific output identities stay outside the shared deployment
    # source and must survive later dotfile and bootstrap runs.
    run_as_target_user install -Dm0644 /dev/null "${kanshi_local_config}" || {
      echo "ERROR: Could not create local Kanshi profile: ${kanshi_local_config}"
      return 1
    }
    echo "INFO: Created local Kanshi profile: ${kanshi_local_config}"
  fi

  echo ""
  echo "INFO: Applying GTK file chooser preferences..."

  if ! command -v gsettings &>/dev/null || ! command -v dbus-run-session &>/dev/null; then
    echo "ERROR: gsettings and dbus-run-session are required for GTK preferences."
    return 1
  fi

  local failed=false

  set_file_chooser_setting() {
    local -r schema="${1}"
    local -r key="${2}"
    local -r value="${3}"

    if ! run_as_target_user gsettings list-keys "${schema}" 2>/dev/null | grep -Fxq "${key}"; then
      echo "ERROR: Required GLib setting is unavailable: ${schema} ${key}"
      failed=true
      return
    fi

    run_as_target_user dbus-run-session -- gsettings set "${schema}" "${key}" "${value}" || {
      echo "ERROR: Failed to set GLib preference: ${schema} ${key}"
      failed=true
    }
  }

  local schema
  for schema in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
    set_file_chooser_setting "${schema}" clock-format 24h
    set_file_chooser_setting "${schema}" date-format with-time
    set_file_chooser_setting "${schema}" location-mode path-bar
    set_file_chooser_setting "${schema}" show-hidden false
    set_file_chooser_setting "${schema}" show-size-column true
    set_file_chooser_setting "${schema}" show-type-column true
    set_file_chooser_setting "${schema}" sort-column name
    set_file_chooser_setting "${schema}" sort-directories-first true
    set_file_chooser_setting "${schema}" sort-order ascending
    # Starting in the current directory avoids exposing a cross-application
    # recent-files view each time a file chooser opens.
    set_file_chooser_setting "${schema}" startup-mode cwd
  done
  set_file_chooser_setting org.gtk.gtk4.Settings.FileChooser view-type list

  setup_thunar_bookmarks() {
    local -r gtk_bookmarks="${target_user_home}/.config/gtk-3.0/bookmarks"
    local -a bookmark_specs=(
      "DOWNLOAD:Downloads"
      "DOCUMENTS:Documents"
      "PICTURES:Pictures"
      "MUSIC:Music"
      "VIDEOS:Videos"
      "PROJECTS:Projects"
    )
    local bookmark_spec xdg_name bookmark_label bookmark_dir bookmark_uri
    local bookmark_content=""

    for bookmark_spec in "${bookmark_specs[@]}"; do
      xdg_name="${bookmark_spec%%:*}"
      bookmark_label="${bookmark_spec#*:}"
      bookmark_dir="${target_user_home}/${bookmark_label}"
      if command -v xdg-user-dir >/dev/null 2>&1; then
        bookmark_dir="$(run_as_target_user xdg-user-dir "${xdg_name}" 2>/dev/null || true)"
      fi
      [[ -d "${bookmark_dir}" ]] || continue

      bookmark_uri=""
      if command -v gio >/dev/null 2>&1; then
        bookmark_uri="$(run_as_target_user env LC_ALL=C gio info "${bookmark_dir}" 2>/dev/null | sed -n 's/^uri: //p' | head -n 1)"
      fi
      if [[ -z "${bookmark_uri}" ]]; then
        bookmark_uri="file://${bookmark_dir}"
      fi
      printf -v bookmark_content '%s%s %s\n' "${bookmark_content}" "${bookmark_uri}" "${bookmark_label}"
    done

    run_as_target_user mkdir -p "$(dirname "${gtk_bookmarks}")" || {
      echo "ERROR: Could not create the GTK config directory."
      failed=true
      return
    }
    if ! printf '%s' "${bookmark_content}" | run_as_target_user tee "${gtk_bookmarks}" >/dev/null; then
      echo "ERROR: Could not write Thunar bookmarks: ${gtk_bookmarks}"
      failed=true
      return
    fi
    echo "INFO: Applied Thunar Places shortcuts: ${gtk_bookmarks}"
  }
  setup_thunar_bookmarks

  [[ "${failed}" == "false" ]]
} # }}}

setup_sway_desktop() { # {{{
  if is_wsl; then
    return 0
  fi

  echo ""
  echo "INFO: Configuring the Sway desktop session..."

  local -r greetd_config="${dotfiles_root}/config/system/greetd/config.toml"
  local -r regreet_config="${dotfiles_root}/config/system/greetd/regreet.toml"
  local -r regreet_style="${dotfiles_root}/config/system/greetd/regreet.css"
  local -r greetd_pam_config="${dotfiles_root}/config/system/pam.d/greetd"
  local -r sway_session_file="${dotfiles_root}/config/system/wayland-sessions/sway.desktop"
  local -r sway_launcher="${dotfiles_root}/config/system/sway/start-sway"
  local -r logind_config="${dotfiles_root}/config/system/systemd/logind.conf.d/60-sway-desktop.conf"
  local -r system_sound_config="${dotfiles_root}/config/system/modprobe.d/60-silent-system-sounds.conf"

  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "ERROR: Could not determine the target desktop user."
    return 1
  }

  local target_user_home=""
  target_user_home="$(target_home "${target_user_name}")" || {
    echo "ERROR: Could not determine the home directory for ${target_user_name}."
    return 1
  }

  local -r sway_config="${target_user_home}/.config/sway/config"
  local -r sway_user_unit_dir="${target_user_home}/.config/systemd/user"

  local source_file
  for source_file in "${greetd_config}" "${regreet_config}" "${regreet_style}" "${greetd_pam_config}" "${sway_session_file}" "${sway_launcher}" "${logind_config}" "${system_sound_config}"; do
    if [[ ! -f "${source_file}" ]]; then
      echo "ERROR: Required Sway system configuration is missing: ${source_file}"
      return 1
    fi
  done

  if ! command -v systemctl &>/dev/null; then
    echo "ERROR: systemctl is required for the maintained Sway desktop."
    return 1
  fi
  if ! command -v systemd-analyze &>/dev/null; then
    echo "ERROR: systemd-analyze is required to validate the Sway user session."
    return 1
  fi
  if ! command -v sway &>/dev/null; then
    echo "ERROR: sway is required to validate the deployed desktop configuration."
    return 1
  fi
  if [[ ! -f "${sway_config}" ]]; then
    echo "ERROR: Deployed Sway configuration is missing: ${sway_config}"
    return 1
  fi

  if ! bash -n "${sway_launcher}"; then
    echo "ERROR: Sway session launcher failed shell syntax validation."
    return 1
  fi

  local -a sway_check_command=(sway -C -c "${sway_config}")
  if [[ -d /sys/module/nvidia_drm || -d /sys/module/nvidia ]]; then
    sway_check_command=(sway --unsupported-gpu -C -c "${sway_config}")
  fi
  if ! run_as_target_user env \
    WLR_BACKENDS=headless \
    WLR_RENDERER=pixman \
    WLR_LIBINPUT_NO_DEVICES=1 \
    "${sway_check_command[@]}"; then
    echo "ERROR: Deployed Sway configuration failed validation."
    return 1
  fi

  local -a sway_user_units=()
  local unit_file
  for unit_file in "${sway_user_unit_dir}"/*.service "${sway_user_unit_dir}"/*.target "${sway_user_unit_dir}"/*.path "${sway_user_unit_dir}"/*.timer; do
    if [[ -f "${unit_file}" ]]; then
      sway_user_units+=("${unit_file}")
    fi
  done
  if ((${#sway_user_units[@]} == 0)); then
    echo "ERROR: Deployed Sway user units are missing: ${sway_user_unit_dir}"
    return 1
  fi
  if ! run_as_target_user systemd-analyze --user --man=no --generators=no verify "${sway_user_units[@]}"; then
    echo "ERROR: Deployed Sway user units failed validation."
    return 1
  fi

  local failed=false

  run_as_root install -Dm0644 "${greetd_config}" /etc/greetd/config.toml || {
    echo "ERROR: Failed to install the greetd configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${regreet_config}" /etc/greetd/regreet.toml || {
    echo "ERROR: Failed to install the ReGreet configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${regreet_style}" /etc/greetd/regreet.css || {
    echo "ERROR: Failed to install the ReGreet stylesheet."
    failed=true
  }
  run_as_root install -Dm0644 "${greetd_pam_config}" /etc/pam.d/greetd || {
    echo "ERROR: Failed to install the greetd PAM configuration."
    failed=true
  }
  run_as_root install -Dm0644 "${sway_session_file}" /usr/local/share/wayland-sessions/sway.desktop || {
    echo "ERROR: Failed to install the Sway session descriptor."
    failed=true
  }
  run_as_root install -Dm0755 "${sway_launcher}" /usr/local/bin/start-sway || {
    echo "ERROR: Failed to install the Sway session launcher."
    failed=true
  }
  run_as_root install -Dm0644 "${logind_config}" /etc/systemd/logind.conf.d/60-sway-desktop.conf || {
    echo "ERROR: Failed to install the systemd-logind desktop policy."
    failed=true
  }
  run_as_root install -Dm0644 "${system_sound_config}" /etc/modprobe.d/60-silent-system-sounds.conf || {
    echo "ERROR: Failed to install the silent system sound policy."
    failed=true
  }

  if [[ "${failed}" == "true" ]]; then
    return 1
  fi

  run_as_root systemctl set-default graphical.target || {
    echo "ERROR: Failed to set graphical.target as the default boot target."
    return 1
  }

  enable_desktop_service() {
    local unit_name
    for unit_name in "${@}"; do
      if ! systemctl list-unit-files "${unit_name}" >/dev/null 2>&1; then
        echo "WARN: Service unit is unavailable: ${unit_name}"
        continue
      fi

      run_as_root systemctl enable --now "${unit_name}" || {
        echo "WARN: Failed to enable desktop service: ${unit_name}"
      }
    done
  }

  enable_desktop_service \
    power-profiles-daemon.service \
    switcheroo-control.service \
    bluetooth.service \
    cups.service

  if command -v powerprofilesctl &>/dev/null; then
    run_as_root powerprofilesctl set balanced || {
      echo "WARN: Failed to select the balanced power profile."
    }
  fi

  # Display managers own the same display-manager.service alias. Switch it only
  # after required validation and installation have completed, and do not start
  # greetd inside the current graphical session.
  run_as_root systemctl enable --force greetd.service || {
    echo "ERROR: Failed to enable greetd.service."
    return 1
  }

  echo "DONE: Sway, greetd, and adaptive desktop services are configured."
} # }}}

setup_locale() { # {{{
  if is_wsl; then
    return 0
  fi

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

setup_date_and_time() { # {{{
  if is_wsl; then
    return 0
  fi

  if ! command -v timedatectl &>/dev/null; then
    echo "WARN: timedatectl is not available. Skipping date and time setup."
    return 0
  fi

  echo ""
  echo "INFO: Configuring automatic time and the Asia/Seoul time zone..."

  run_as_root timedatectl set-ntp true || {
    echo "WARN: Failed to enable automatic time synchronization."
  }

  run_as_root timedatectl set-timezone Asia/Seoul || {
    echo "WARN: Failed to set the system time zone to Asia/Seoul."
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
  local target_user_name=""
  target_user_name="$(target_user)" || {
    echo "WARN: Could not identify a non-root target user. Skipping default directory setup."
    return 0
  }

  local target_group=""
  target_group="$(id -gn "${target_user_name}" 2>/dev/null)" || {
    echo "WARN: Could not identify primary group for ${target_user_name}. Skipping default directory setup."
    return 0
  }

  local home_dir=""
  home_dir="$(target_home "${target_user_name}")" || {
    echo "WARN: Could not identify a non-root target home. Skipping default directory setup."
    return 0
  }

  create_user_dir() {
    local dir_path="${1}"
    run_as_root install -d -m 0755 -o "${target_user_name}" -g "${target_group}" "${dir_path}"
  }

  create_user_dir "${home_dir}/Downloads"
  create_user_dir "${home_dir}/Documents"
  create_user_dir "${home_dir}/Music"
  create_user_dir "${home_dir}/Pictures"
  create_user_dir "${home_dir}/Videos"
  create_user_dir "${home_dir}/tmp"

  _PROJECTS_HOME="${home_dir}/Projects"
  create_user_dir "${_PROJECTS_HOME}"
  create_user_dir "${_PROJECTS_HOME}/work"
  create_user_dir "${_PROJECTS_HOME}/personal"
  create_user_dir "${_PROJECTS_HOME}/opensource"
  create_user_dir "${_PROJECTS_HOME}/playground"
  create_user_dir "${_PROJECTS_HOME}/experiments"

  if command -v xdg-user-dirs-update &>/dev/null; then
    run_as_target_user xdg-user-dirs-update || {
      echo "WARN: Failed to register standard XDG user directories."
    }
  fi
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

install_aur_packages() { # {{{
  if is_wsl; then
    return 0
  fi

  # Keep only bootstrap-owned desktop dependencies here. Larger optional apps
  # stay as explicit post-bootstrap choices in README.md.
  if ! run_as_target_user bash -lc "command -v yay >/dev/null 2>&1"; then
    echo "WARN: yay is not installed. Skipping AUR package setup."
    return 0
  fi

  echo ""
  echo "INFO: Installing AUR packages..."

  local -a aur_packages=(
    google-chrome
  )

  local pkg
  for pkg in "${aur_packages[@]}"; do
    run_as_target_user yay -S --needed --noconfirm "${pkg}" || {
      echo "WARN: Failed to install AUR package: ${pkg}"
    }
  done
} # }}}

set_default_browser_to_google_chrome() { # {{{
  local -r desktop_file="google-chrome.desktop"

  if is_wsl; then
    return 0
  fi

  if ! run_as_target_user bash -lc "command -v google-chrome-stable >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1"; then
    echo "WARN: Google Chrome is not installed. Skipping default browser setup."
    return 0
  fi

  if ! command -v xdg-settings &>/dev/null; then
    echo "WARN: xdg-settings is not installed. Skipping default browser setup."
    return 0
  fi

  if [[ ! -f "/usr/share/applications/${desktop_file}" ]]; then
    echo "WARN: Google Chrome desktop file not found. Skipping default browser setup."
    return 0
  fi

  echo ""
  echo "INFO: Setting Google Chrome as the default browser..."
  run_as_target_user xdg-settings set default-web-browser "${desktop_file}" || {
    echo "WARN: Failed to set Google Chrome as the default browser."
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

_retry_mise_cli_install() { # {{{
  local -r display_name="${1:-}"
  local -r command_name="${2:-}"
  local -r tool_id="${3:-}"

  if [[ -z "${display_name}" || -z "${command_name}" || -z "${tool_id}" ]]; then
    echo "ERROR: _retry_mise_cli_install requires a display name, command, and mise tool ID."
    return 1
  fi

  # Let HOME/PATH expand inside the target user's shell, not in this bootstrap shell.
  # shellcheck disable=SC2016
  if run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    command -v "${1}" >/dev/null 2>&1
  ' bash "${command_name}"; then
    echo "DONE: ${display_name} is already installed."
    return 0
  fi

  echo ""
  echo "INFO: Retrying ${display_name} installation..."
  # shellcheck disable=SC2016
  if run_as_target_user bash -lc '
    export PATH="${HOME}/.local/bin:${PATH}"
    mise install --yes "${1}@latest"
  ' bash "${tool_id}"; then
    echo "DONE: ${display_name} installation completed."
    return 0
  fi

  echo "WARN: Failed to install ${display_name}."
  echo "INFO: Retry later: mise install ${tool_id}@latest"
  return 1
} # }}}

retry_mise_cli_installs() { # {{{
  # The main mise task installs every configured tool first. Retry only missing
  # GitHub-release CLIs because parallel resolution can hit unauthenticated API
  # rate limits without preventing the remaining tools from being installed.
  # shellcheck disable=SC2016
  if ! run_as_target_user bash -lc 'export PATH="${HOME}/.local/bin:${PATH}"; command -v mise >/dev/null 2>&1'; then
    echo "WARN: mise is not installed. Skipping CLI installation retries."
    return 0
  fi

  local failed=false
  _retry_mise_cli_install "Codex CLI" codex "aqua:openai/codex" || failed=true
  _retry_mise_cli_install \
    "Antigravity CLI (agy)" \
    agy \
    "aqua:google-antigravity/antigravity-cli" || failed=true
  _retry_mise_cli_install \
    "Claude Code" \
    claude \
    "aqua:anthropics/claude-code" || failed=true

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: One or more optional CLI installation retries failed."
  fi

  return 0
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

  local -r font_name="CommitMonoNerdFontMono"
  # Nerd Fonts release assets use versioned URLs, and the extraction below
  # relies on the reviewed archive layout. Reconsider this pin when updating
  # Nerd Fonts or when the CommitMono asset layout changes.
  local -r version="v3.4.0"
  local -r download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/CommitMono.zip"
  local home_dir=""
  home_dir="$(target_home)" || {
    echo "WARN: Could not identify a non-root target home. Skipping font setup."
    return 0
  }

  local -r font_dir="${home_dir}/.local/share/fonts"

  install_commit_mono_nerd_font() {
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
    run_as_target_user curl -fLo "${temp_dir}/CommitMono.zip" "${download_url}" --retry 3 || {
      echo "WARN: Failed to download ${font_name}."
      return 0
    }

    echo ""
    echo "INFO: Extracting files..."
    run_as_target_user unzip -o "${temp_dir}/CommitMono.zip" -d "${temp_dir}" || {
      echo "WARN: Failed to extract ${font_name} archive."
      return 0
    }

    run_as_target_user mkdir -pv "${font_dir}"

    run_as_target_user bash -lc "find \"${temp_dir}\" -name 'CommitMonoNerdFontMono-*.otf' -exec cp {} \"${font_dir}/\" \;" || {
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
  install_commit_mono_nerd_font
} # }}}

# User tool setup }}}

# Arch Linux network privacy {{{

setup_basic_firewall() { # {{{
  if is_wsl; then
    return 0
  fi

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

  # firewalld is the selected default for this Arch/NetworkManager setup. Prefer it
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
  if is_wsl; then
    return 0
  fi

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

  run_as_root install -Dm0644 "${nm_privacy_config}" /etc/NetworkManager/conf.d/99-privacy.conf || {
    echo "ERROR: Failed to install NetworkManager privacy config."
    return 1
  }

  # Apply now if NetworkManager is running; otherwise it applies on next start.
  if command -v systemctl &>/dev/null; then
    run_as_root systemctl reload NetworkManager.service 2>/dev/null || {
      echo "WARN: NetworkManager is not running; privacy settings will apply later."
    }
  fi
} # }}}

setup_basic_network_privacy() { # {{{
  if is_wsl; then
    return 0
  fi

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
  if is_wsl; then
    return 0
  fi

  echo ""
  echo "DONE: Bootstrap complete. Reboot to start greetd and select Sway."
  echo "INFO: If WARN lines appeared, review them before removing the previous desktop."
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
    setup_date_and_time
    set_default_shell_to_zsh
    create_default_directories
    deploy_dotfiles
    setup_sway_user_preferences
    setup_sway_desktop
    install_zsh_plugins
    install_yay
    install_aur_packages
    set_default_browser_to_google_chrome
    install_mise_managed_tools
    retry_mise_cli_installs
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
        if [[ "${task}" == "install_base_packages" ]]; then
          echo "ERROR: Required package installation failed. Stop before applying dependent configuration."
          exit 1
        fi
        if [[ "${task}" == "deploy_dotfiles" || "${task}" == "setup_sway_user_preferences" || "${task}" == "setup_sway_desktop" ]]; then
          echo "ERROR: Required Sway preferences or deployment failed. Stop before reporting a bootable desktop."
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
