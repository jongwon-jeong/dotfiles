Personal dotfiles and Arch Linux + GNOME bootstrap scripts.

## Arch Linux Install Notes

Initial live ISO commands:

Replace `<WIFI_DEVICE>` with the device name from `device list`, and replace
`<WIFI_NAME>` with the target Wi-Fi network name.

```sh
archinstall
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
  `scripts/setup_arch_bootstrap.sh` to install GNOME, GDM, Hangul input, user
  tools, and network policy.
- Menu names change across archinstall releases. Run `archinstall --dry-run`
  on the live ISO when you need the exact current menu/config keys.

Main menu:

- Archinstall language: English.
- Mirrors: choose nearby country mirrors, then refresh package databases.
- Locales:
  - Keyboard layout: us.
  - Locale language: en_US.UTF-8.
  - Locale encoding: UTF-8.
- Disk configuration:
  - Partition table: GPT on UEFI systems.
  - Use a whole target disk for a fresh single-boot machine.
  - Use manual partitioning for dual-boot, preserving existing partitions, or
    non-default boot layouts.
  - Disk layout: best-effort/default layout for a clean single-disk install.
  - Filesystem: ext4 for simple installs; btrfs only if snapshots/subvolumes are
    intentional.
  - Mountpoints: let archinstall create the default EFI/root layout unless
    manual partitioning is required.
  - Separate `/home`: disabled by default for a simple personal machine. Enable
    it only when preserving user data across OS reinstalls or applying a separate
    backup/quota policy is more important than simpler storage management.
  - LVM: disabled by default for a simple single-root personal machine. Enable it
    only when separate logical volumes, later resizing, or multi-disk volume
    management is intentionally needed.
  - LVM on LUKS: choose this if LVM is enabled. One encrypted container protects
    all logical volumes and usually needs one passphrase.
  - LUKS on LVM: avoid by default. Use only when different logical volumes need
    separate encryption keys, unlock policy, or unencrypted volumes beside
    encrypted ones.
- Disk encryption: enable LUKS by default. Skip only for disposable VMs or
  machines where encryption is intentionally handled elsewhere.
  - Encryption password: use a strong passphrase that can be typed reliably on
    the selected keyboard layout.
- Bootloader: systemd-boot on UEFI; GRUB only when BIOS or a GRUB-specific boot
  requirement exists.
- Unified kernel images: leave disabled unless UKI and Secure Boot are part of
  the explicit boot plan.
- Removable boot: disabled by default. Enable only for removable media or
  machines where NVRAM boot entries are unreliable.
- Swap: zram.
  - Compression algorithm: zstd if archinstall asks. It is a practical default
    for desktop use because it balances compression ratio and speed well.
  - Size/priority: keep archinstall defaults unless a measured memory-pressure
    issue appears later.
- Hostname: pick a short lowercase machine name.
- Root password: set one, even if daily admin uses sudo.
- User account: create a normal user and allow sudo/admin privileges.
- Profile: do not select a profile. This script owns desktop/bootstrap setup.
- Graphics/GPU driver: skip if no menu appears. This script installs Mesa for
  all desktops and the current Arch NVIDIA open-driver path when NVIDIA hardware
  is detected. Very old NVIDIA GPUs may need a legacy AUR driver.
- Audio: none. This script installs PipeWire explicitly.
- Kernels: linux.
- Network configuration: NetworkManager.
  - Backend: default. Use iwd only when you intentionally want iwd-managed Wi-Fi
    or need it to work around a specific wpa_supplicant issue.
- Firewall: firewalld by default. If UFW is already active/enabled because you
  explicitly chose it, this script applies the same conservative firewall policy.
- Timezone: Asia/Seoul.
- NTP: enabled.
- Optional repositories: none by default. Enable multilib when Steam, Wine,
  Proton, or other 32-bit runtime support is needed. NVIDIA gaming setups also
  need multilib for lib32-nvidia-utils/lib32-vulkan-icd-loader.
- Package lookup/checking: enabled/default. Disable only when deliberately using
  packages that archinstall cannot validate.
- Additional packages: git networkmanager.
- Additional services: none. This script enables desktop and network services
  after the base system is installed.
- Accessibility tools: disabled unless the installer session needs them.
- Parallel downloads: use the default or a small value such as 5.
- Custom commands: none.
- Save configuration: optional; useful when repeating the same install.
- Install: review the summary carefully before confirming destructive disk
  operations.

## First Boot Wi-Fi

After rebooting into the installed system, make Wi-Fi work before cloning this
repo or running the bootstrap script.

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
