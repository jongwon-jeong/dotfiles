Personal dotfiles and Arch Linux + Sway/Wayland bootstrap scripts.

## Arch Linux Install Notes

Initial live ISO commands:

Replace `<WIFI_DEVICE>` with the device name from `device list`, and replace
`<WIFI_NAME>` with the target Wi-Fi network name.

```sh
ping -c 3 archlinux.org

iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit

ping -c 3 archlinux.org
archinstall
```

Recommended `archinstall` choices for this bootstrap:

- Official references:
  - https://wiki.archlinux.org/title/Archinstall
  - https://archinstall.archlinux.page/installing/guided.html
  - https://man.archlinux.org/man/extra/archinstall/archinstall.1.en
- Goal: install a clean terminal/base Arch system, reboot, then run
  `scripts/setup_arch_bootstrap.sh` to install Sway, greetd, Fcitx5 Hangul input,
  user tools, and network policy.
- Menu names change across archinstall releases. Run `archinstall --dry-run`
  on the live ISO when you need the exact current menu/config keys.

Main menu:

- Archinstall language: English.
- Mirrors: choose nearby country mirrors.
- Locales:
  - Keyboard layout: us.
  - Locale language: en_US.UTF-8.
  - Locale encoding: UTF-8.
- Disk configuration:
  - Partition table: GPT on UEFI systems.
  - Use Best Effort default partitioning on the whole target disk for a fresh
    single-boot machine.
  - Use manual partitioning for dual-boot, preserving existing partitions, or
    non-default boot layouts.
  - Filesystem: ext4.
  - Mountpoints: let archinstall create the default EFI/root layout unless
    manual partitioning is required.
  - Separate `/home`: disabled. Keep home data in the single root filesystem.
  - LVM: disabled. This single-disk layout does not need independently resized
    logical volumes or pooled storage.
- Disk encryption: enable LUKS by default for the system and user-data
  partitions. Leave only the boot components required by the selected bootloader
  unencrypted.
  - Encryption password: use a strong passphrase that can be typed reliably on
    the selected keyboard layout.
- Bootloader: systemd-boot on UEFI. On BIOS systems, use GRUB or Limine.
- Unified kernel images: leave disabled unless UKI and Secure Boot are part of
  the explicit boot plan.
- Removable boot: disabled by default. Enable only for removable media or
  machines where NVRAM boot entries are unreliable.
- Swap: zram.
  - Compression algorithm: zstd if archinstall asks. It is a practical default
    for desktop use because it balances compression ratio and speed well.
- Hostname: pick a short lowercase machine name.
- Root password: leave unset. Use the normal user's password with sudo; the LUKS
  passphrase separately protects data at rest.
- User account: create a normal user and allow sudo/admin privileges.
- Profile: do not select a profile. This script owns desktop/bootstrap setup.
- Graphics/GPU driver: skip if no menu appears. This script installs Mesa for
  all desktops and the current Arch NVIDIA open-driver path when NVIDIA hardware
  is detected. Very old NVIDIA GPUs may need a legacy AUR driver.
- Audio: none. This script installs PipeWire explicitly.
- Kernels: linux.
- Network configuration: NetworkManager.
- Timezone: Asia/Seoul.
- NTP: enabled.
- Optional repositories: none by default. Enable multilib when Steam, Wine,
  Proton, or other 32-bit runtime support is needed. NVIDIA gaming setups also
  need multilib for lib32-nvidia-utils/lib32-vulkan-icd-loader.
- Package lookup/checking: enabled/default. Disable only when deliberately using
  packages that archinstall cannot validate.
- Additional packages: git.
- Additional services: none. This script enables desktop and network services
  after the base system is installed.
- Accessibility tools: disabled unless the installer session needs them.
- Parallel downloads: use the default or a small value such as 5.
- Custom commands: none.
- Save configuration: do not save by default. If reuse is intentional, encrypt
  the credentials file because it can contain the LUKS passphrase, and remove
  saved credentials after use.
- Install: review the summary carefully before confirming destructive disk
  operations.

## First Boot Wi-Fi

After rebooting into the installed system, make Wi-Fi work before running the
bootstrap script.

Do not rely on `which`; it may not be installed. Use `command -v` instead.

```sh
command -v nmcli
command -v iwctl
```

If `nmcli` exists, use NetworkManager:

```sh
sudo systemctl enable --now NetworkManager.service
nmcli radio wifi on
nmcli device status
nmcli device wifi rescan
nmcli device wifi list
nmcli device wifi connect <WIFI_NAME> --ask
ping -c 3 archlinux.org
```

If the Wi-Fi device is unavailable or blocked:

```sh
rfkill list
sudo rfkill unblock wifi
nmcli device status
```

If `nmcli` is missing but `iwctl` exists, use iwd for a temporary connection.
This is only a fallback; NetworkManager with its default backend does not need
iwd on the installed system.

```sh
sudo systemctl enable --now iwd.service
iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit
ping -c 3 archlinux.org
```

After a temporary iwd connection, install and enable NetworkManager:

```sh
sudo pacman -Syu networkmanager
sudo systemctl disable --now iwd.service
sudo systemctl enable --now NetworkManager.service
```

If both `nmcli` and `iwctl` are missing, boot the Arch ISO again, connect from
the live environment, chroot into the installed system, and install the missing
network tools:

```sh
iwctl
device list
station <WIFI_DEVICE> scan
station <WIFI_DEVICE> get-networks
station <WIFI_DEVICE> connect <WIFI_NAME>
exit
ping -c 3 archlinux.org

mount <ROOT_PARTITION> /mnt
arch-chroot /mnt
pacman -Syu networkmanager
systemctl enable NetworkManager.service
exit
umount -R /mnt
reboot
```

## WSL User Setup

Create a normal user and grant sudo access from the initial root shell. The
bootstrap installs Zsh and changes this account's login shell later.

```sh
pacman -Syu sudo vim
useradd -m -G wheel <USER_NAME>
passwd <USER_NAME>
EDITOR=vim visudo
```

In `visudo`, enable the wheel group:

```conf
%wheel ALL=(ALL:ALL) ALL
```

Change the WSL default user from Windows:

```powershell
<DISTRO_LAUNCHER>.exe config --default-user <USER_NAME>
```

If the distro does not provide that launcher command, set the default user in
`/etc/wsl.conf`:

```conf
[user]
default=<USER_NAME>
```

Then restart the distro from Windows:

```powershell
wsl --terminate <DISTRO_NAME>
```

## After Bootstrap

### Setup Logs and Backups

`scripts/setup_dotfiles.sh` and `scripts/setup_arch_bootstrap.sh` write timestamped logs under `~/tmp/logs`. When dotfiles are deployed from a checkout outside `~/.dotfiles`, deployment moves replaced files and the previous `~/.dotfiles` copy under `~/.local/share/backups/dotfiles-<timestamp>-<pid>/` before creating new symlinks.

These artifacts are not deleted automatically. Keep the relevant backup until the deployed shell, editor, and desktop configuration has been verified, then inspect old backups and logs before removing them manually. Logs can contain usernames, local paths, installed package details, and network or hardware state, so review them before sharing.

Codex CLI theme:

Run `/theme` in Codex and select `paper-custom-codex`. Codex persists the
selection in `~/.codex/config.toml` as:

```toml
[tui]
theme = "paper-custom-codex"
```

Optional desktop apps:

```sh
yay -S --needed visual-studio-code-bin
yay -S --needed jetbrains-toolbox
```

VS Code extensions:

```sh
code --install-extension vscodevim.vim
code --install-extension editorconfig.editorconfig
```
