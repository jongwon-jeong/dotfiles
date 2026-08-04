# ~/.config/shell/aliases.sh
# ----------------------------------------------------------
# Shared aliases and functions for interactive shells.
# This is not POSIX sh; do not source it from dash/sh.
# Keep this file source-compatible with both bash and zsh.
# Put zsh-only startup behavior in ~/.zshrc or a separate *.zsh file.

_join_by() {
  local delimiter="${1}"
  shift

  local first=true
  local item
  for item in "${@}"; do
    if [ "${first}" = true ]; then
      printf "%s" "${item}"
      first=false
    else
      printf "%s%s" "${delimiter}" "${item}"
    fi
  done
}

_is_remote_shell() {
  [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]
}

_absolute_path() {
  local target_path="${1}"

  if command -v realpath >/dev/null 2>&1; then
    command realpath -- "${target_path}"
    return
  fi

  local target_dir
  target_dir="$(dirname "${target_path}")" || return
  local target_name
  target_name="$(basename "${target_path}")" || return
  target_dir="$(cd "${target_dir}" && pwd -P)" || return
  printf "%s/%s\n" "${target_dir}" "${target_name}"
}

_copy_text_to_clipboard() {
  if _is_remote_shell; then
    echo "ERROR: Clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  if [[ "$(uname)" == "Darwin" ]] && command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy --trim-newline --type text/plain
  elif [[ "$(uname -a)" =~ "WSL" ]] && command -v clip.exe >/dev/null 2>&1; then
    clip.exe
  elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -in
  else
    echo "ERROR: No supported desktop clipboard command is available." >&2
    return 1
  fi
}

_path_to_uri() {
  local target_path="${1}"

  if ! command -v gio >/dev/null 2>&1; then
    echo "ERROR: gio is required to copy files as clipboard objects." >&2
    return 1
  fi

  LC_ALL=C gio info -- "${target_path}" 2>/dev/null | sed -n 's/^uri: //p'
}

_reset_shell_names() {
  local name
  for name in "${@}"; do
    unalias "${name}" 2>/dev/null || true
    unset -f "${name}" 2>/dev/null || true
  done
}

if command -v nvim >/dev/null 2>&1; then
  export VISUAL="nvim"
else
  export VISUAL="vim"
fi
export EDITOR="${VISUAL}"
export GIT_EDITOR="${VISUAL}"
export FCEDIT="${VISUAL}"
unalias v vi vim vimdiff 2>/dev/null || true
v() { command "${VISUAL}" "${@}"; }
vi() { command "${VISUAL}" "${@}"; }
vim() { command "${VISUAL}" "${@}"; }
vimdiff() { command "${VISUAL}" -d "${@}"; }

_reset_shell_names cpath cfile ccont
cpath() {
  local -a target_paths=("${@}")
  if [[ ${#target_paths[@]} -eq 0 ]]; then
    target_paths=(.)
  fi

  local -a absolute_paths=()
  local target_path
  for target_path in "${target_paths[@]}"; do
    if [[ ! -e "${target_path}" && ! -L "${target_path}" ]]; then
      echo "ERROR: Path does not exist: ${target_path}" >&2
      return 1
    fi

    absolute_paths+=("$(_absolute_path "${target_path}")") || return
  done

  _join_by $'\n' "${absolute_paths[@]}" | _copy_text_to_clipboard
}

cfile() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: cfile <file-or-directory> [...]" >&2
    return 1
  fi

  if _is_remote_shell; then
    echo "ERROR: File clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  local -a file_uris=()
  local target_path
  local file_uri=""
  for target_path in "${@}"; do
    if [[ ! -e "${target_path}" && ! -L "${target_path}" ]]; then
      echo "ERROR: Path does not exist: ${target_path}" >&2
      return 1
    fi

    file_uri="$(_path_to_uri "${target_path}")" || return
    if [[ -z "${file_uri}" ]]; then
      echo "ERROR: Could not create a file URI for: ${target_path}" >&2
      return 1
    fi
    file_uris+=("${file_uri}")
  done

  local clipboard_data="copy"$'\n'
  clipboard_data+="$(_join_by $'\n' "${file_uris[@]}")"

  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    printf "%s" "${clipboard_data}" | wl-copy --type x-special/gnome-copied-files
  elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    printf "%s" "${clipboard_data}" |
      xclip -selection clipboard -in -target x-special/gnome-copied-files
  else
    echo "ERROR: cfile requires wl-copy on Wayland or xclip on X11." >&2
    return 1
  fi
}

ccont() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: ccont <file>" >&2
    return 1
  fi

  local target_file="${1}"
  if [[ ! -f "${target_file}" ]]; then
    echo "ERROR: File does not exist or is not a regular file: ${target_file}" >&2
    return 1
  fi

  if _is_remote_shell; then
    echo "ERROR: File content clipboard copy is disabled in remote shells." >&2
    return 1
  fi

  if [[ "$(uname)" == "Darwin" ]] && command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"${target_file}"
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy <"${target_file}"
  elif [[ "$(uname -a)" =~ "WSL" ]] && command -v clip.exe >/dev/null 2>&1; then
    local mime_type
    mime_type="$(file --brief --mime-type -- "${target_file}")" || return
    if [[ "${mime_type}" != text/* ]]; then
      echo "ERROR: ccont supports text files only through clip.exe: ${mime_type}" >&2
      return 1
    fi
    clip.exe <"${target_file}"
  elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    local mime_type
    mime_type="$(xdg-mime query filetype "${target_file}")" || return
    xclip -selection clipboard -in -target "${mime_type}" <"${target_file}"
  else
    echo "ERROR: No supported desktop clipboard command is available." >&2
    return 1
  fi
}

_tmux_auto_attach() {
  local session_name="${1}"
  if command -v tmux >/dev/null 2>&1 &&
    [ -n "${PS1}" ] && [ -z "${TMUX}" ] &&
    [[ ! "${TERM}" =~ screen ]] && [[ ! "${TERM}" =~ tmux ]] &&
    [[ ! "${TERM_PROGRAM}" =~ vscode ]]; then
    tmux -L main -f ~/.config/tmux/tmux.conf new-session -AD -s "${session_name}"
  fi
}
ajrtm() { _tmux_auto_attach "main"; }
ajrtm1() { _tmux_auto_attach "main1"; }
ajrtm2() { _tmux_auto_attach "main2"; }
ajrtm3() { _tmux_auto_attach "main3"; }
ajrtm4() { _tmux_auto_attach "main4"; }
ajrtm5() { _tmux_auto_attach "main5"; }

if [[ "$(uname)" = "Linux" ]]; then
  alias cp='cp -iv'
  alias cp1='cp --force --no-preserve=all --recursive --verbose'

  if command -v pacman >/dev/null 2>&1; then
    alias pacss='pacman -Ss' # Search repository packages.
    alias pacsi='pacman -Si' # Show repository package details.
    alias pacqi='pacman -Qi' # Show installed package details.

    if command -v yay >/dev/null 2>&1; then
      alias yayss='yay -Ss' # Search repository and AUR packages.
      alias yaysi='yay -Si' # Show repository or AUR package details.
      alias yayqi='yay -Qi' # Show installed package details.
    fi

    if ! _is_remote_shell; then
      bubo() {
        echo "INFO: Checking pacman updates..."
        if command -v checkupdates >/dev/null 2>&1; then
          checkupdates || true
        else
          pacman -Qu
        fi

        if command -v yay >/dev/null 2>&1; then
          echo ""
          echo "INFO: Checking AUR updates..."
          yay -Qua || true
        fi

        if command -v flatpak >/dev/null 2>&1 && ! [[ "$(uname -a)" =~ "WSL" ]]; then
          echo ""
          echo "INFO: Checking Flatpak updates..."
          flatpak remote-ls --updates || true
        fi
      }

      bubc() {
        # Keep Arch updates as a full-system transaction. AUR and Flatpak updates
        # run after pacman so repo packages, kernels, and desktop libraries settle first.
        sudo pacman -Syu || return

        if command -v yay >/dev/null 2>&1; then
          yay -Sua --devel || return
        fi

        if command -v flatpak >/dev/null 2>&1 && ! [[ "$(uname -a)" =~ "WSL" ]]; then
          flatpak update -y || return
        fi
      }

      bubu() {
        bubo && bubc
      }
    fi

    pacq() {
      # List installed packages, or filter the installed package list by name.
      if [ "${#}" -eq 0 ]; then
        pacman -Q
      elif command -v rg >/dev/null 2>&1; then
        pacman -Q | rg --ignore-case --fixed-strings "${*}"
      else
        pacman -Q | grep -i --fixed-strings "${*}"
      fi
    }
  elif command -v apt >/dev/null 2>&1 && command -v apt-cache >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
    alias aptss='apt-cache search' # Search repository packages.
    alias aptsi='apt-cache show'   # Show repository package details.
    alias aptqi='dpkg-query -s'    # Show installed package details.

    if ! _is_remote_shell; then
      alias bubo='sudo apt update && apt list --upgradable'

      bubc() {
        sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean || return

        if command -v snap >/dev/null 2>&1 && ! [[ "$(uname -a)" =~ "WSL" ]]; then
          sudo snap refresh
        fi
      }

      alias bubu='bubo && bubc'
    fi

    aptq() {
      # List installed packages, or filter the installed package list by name.
      if [ "${#}" -eq 0 ]; then
        dpkg-query -W -f='${binary:Package}\t${Version}\n'
      elif command -v rg >/dev/null 2>&1; then
        dpkg-query -W -f='${binary:Package}\t${Version}\n' | rg --ignore-case --fixed-strings "${*}"
      else
        dpkg-query -W -f='${binary:Package}\t${Version}\n' | grep -i --fixed-strings "${*}"
      fi
    }
  fi

  _reset_shell_names f
  if _is_remote_shell; then
    function f { echo "WARN: File opener is disabled in remote shells." >&2; }
  elif [[ "$(uname -a)" =~ "WSL" ]]; then
    alias f='explorer.exe'
  else
    alias f='xdg-open'
  fi

elif [ "$(uname)" = "Darwin" ]; then
  alias cp='cp -iv'
  alias cp1='cp -RXfv'

  _reset_shell_names f
  if _is_remote_shell; then
    function f { echo "WARN: File opener is disabled in remote shells." >&2; }
  else
    alias f='open -a Finder'
    alias bubo='brew update && brew outdated'
    alias bubc='brew upgrade && brew cleanup'
    alias bubu='bubo && bubc'
  fi
fi

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --stat'
alias gdc='git diff --cached'
alias gdcs='git diff --cached --stat'

alias ga='git add --verbose'
alias gaa='git add --verbose --all'
alias gc='git commit --verbose'
alias gcm='git commit --verbose --message'
alias gca='git commit --verbose --all'

alias gb='git branch --verbose'
alias gsw='git switch'
alias gswc='git switch -c'
alias gco='git checkout'
alias gcob='git checkout -b'

alias grs='git restore'
alias grss='git restore --staged'

alias gf='git fetch --verbose'
alias gl='git pull --verbose'
alias gp='git push --verbose'
alias gr='git remote --verbose'

alias gm='git merge --verbose'
alias grb='git rebase --verbose'
alias gcp='git cherry-pick'
alias gst='git stash'
alias gstp='git stash pop'

alias gdt='git difftool'
alias gdts='git difftool --staged'
alias gmt='git mergetool'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbs='git rebase --skip'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(green)(%ar)%C(reset) %C(black)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glp="git log --pretty=format:'%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(black)%s%C(reset) %C(dim white)%an%C(reset)' --date=short"
alias ggrep="git log --all --grep" # Search commit messages

alias ggs="gg -n 10"
alias glps="glp -n 10"

alias tmls='tmux ls'
alias tmat='tmux attach -t'
alias tmdt='tmux detach'
alias tmkl='tmux kill-session'

alias zshrc='test -f ~/.zshrc && vim ~/.zshrc || echo "WARN: File does not exist."'
alias alish='test -f ~/.config/shell/aliases.sh && vim ~/.config/shell/aliases.sh || echo "WARN: File does not exist."'
alias dotfiles='test -d ~/.dotfiles && cd ~/.dotfiles || echo "WARN: Directory does not exist."'
alias xzsh='exec zsh -l'

reload_config() {
  local failed=false

  echo "INFO: Reloading active configurations..."

  # A degraded user manager is still reachable and must receive unit reloads.
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    echo "INFO: Reloading systemd user daemon..."
    if ! systemctl --user daemon-reload; then
      echo "ERROR: Failed to reload the systemd user daemon."
      failed=true
    fi
  fi

  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    echo "INFO: Reloading Sway compositor..."
    if ! swaymsg reload; then
      echo "ERROR: Failed to reload the Sway compositor."
      failed=true
    fi
  fi

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    echo "INFO: Reloading Tmux configuration..."
    if ! tmux source-file "${HOME}/.config/tmux/tmux.conf"; then
      echo "ERROR: Failed to reload the Tmux configuration."
      failed=true
    fi
  fi

  if [[ -f "${HOME}/.config/shell/aliases.sh" ]]; then
    echo "INFO: Sourcing shell aliases..."
    # shellcheck disable=SC1090
    if ! source "${HOME}/.config/shell/aliases.sh"; then
      echo "ERROR: Failed to source the shell aliases."
      failed=true
    fi
  else
    echo "ERROR: Shell aliases file does not exist: ${HOME}/.config/shell/aliases.sh"
    failed=true
  fi

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Reload completed with errors."
    return 1
  fi

  echo "DONE: Reload completed."
}
alias flfhem='reload_config'

sunset() {
  local -r action="${1:-status}"

  if (($# > 1)); then
    echo "ERROR: Usage: sunset {on|off|status}" >&2
    return 2
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    echo "ERROR: systemctl is required to control night color." >&2
    return 1
  fi

  if ! command systemctl --user show-environment >/dev/null 2>&1; then
    echo "ERROR: The systemd user manager is unavailable." >&2
    return 1
  fi

  # Keep this session-scoped; persistent enablement remains an explicit systemd decision.
  case "${action}" in
    on)
      echo "INFO: Starting night color..."
      if ! command systemctl --user start wlsunset.service; then
        echo "ERROR: Failed to start night color." >&2
        return 1
      fi
      echo "DONE: Night color started."
      ;;
    off)
      echo "INFO: Stopping night color..."
      if ! command systemctl --user stop wlsunset.service; then
        echo "ERROR: Failed to stop night color." >&2
        return 1
      fi
      echo "DONE: Night color stopped."
      ;;
    status)
      local state=""
      if ! state="$(command systemctl --user show wlsunset.service --property=ActiveState --value 2>/dev/null)"; then
        echo "ERROR: Failed to read the night color state." >&2
        return 1
      fi

      case "${state}" in
        active) echo "INFO: Night color is active." ;;
        inactive) echo "INFO: Night color is inactive." ;;
        failed)
          echo "WARN: Night color is in a failed state." >&2
          return 1
          ;;
        *) echo "INFO: Night color state: ${state}." ;;
      esac
      ;;
    *)
      echo "ERROR: Usage: sunset {on|off|status}" >&2
      return 2
      ;;
  esac
}

alias c='clear'
alias h='history | tail -n 20'

alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ll='ls -AFhlp'
alias ls='ls -AF --color=auto'
alias mat21='mat2 --inplace --verbose'
alias d='date "+%Y-%m-%d (%a) %H:%M:%S %Z"'
alias numFiles='echo $(ls -1 | wc -l)'
alias dl='cd ~/Downloads'
alias dc='cd ~/Documents'
alias tmp='cd ~/tmp'
alias vc='v ~/.dotfiles/config/nvim/init.lua'
alias vd='vimdiff'

_PROJECTS_HOME="${HOME}/Projects"
alias vdc='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.dotfiles/config/nvim/init.lua config/nvim/init.lua'
alias vdz='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.zshrc home/.zshrc'
alias vda='cd ${_PROJECTS_HOME}/personal/dotfiles/ && vimdiff ~/.dotfiles/config/shell/aliases.sh config/shell/aliases.sh'
alias p='cd ${_PROJECTS_HOME}'
alias per='cd ${_PROJECTS_HOME}/personal'
alias wk='cd ${_PROJECTS_HOME}/work'

if ! _is_remote_shell; then
  cd() {
    builtin cd "${@}" || return
    ls -A
  }
fi

mkcd() { command mkdir -p "${1}" && cd "${1}" || return; }
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .1='cd ../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'

firmware_update() {
  if ! command -v fwupdmgr >/dev/null 2>&1; then
    echo "ERROR: fwupdmgr is not installed."
    return 1
  fi

  # Firmware deployment can require AC power and a reboot, so keep it separate
  # from routine package and user-tool upgrades.
  echo "INFO: Refreshing firmware metadata..."
  command fwupdmgr refresh || return

  echo ""
  echo "INFO: Installing available firmware updates..."
  command fwupdmgr update
}
alias fwup='firmware_update'

_clear_shell_history() {
  if [[ -z "${HOME:-}" || "${HOME}" != /* ]]; then
    echo "WARN: Refusing to clear shell history with an invalid home path."
    return 1
  fi

  local expected_history_file=""
  if [[ -n "${BASH_VERSION:-}" ]]; then
    expected_history_file="${HOME}/.bash_history"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    expected_history_file="${HOME}/.zsh_history"
  else
    echo "WARN: Shell history cleanup supports only Bash and Zsh."
    return 1
  fi

  if [[ -n "${HISTFILE:-}" && "${HISTFILE}" != "${expected_history_file}" ]]; then
    echo "WARN: Refusing to remove a custom shell history file: ${HISTFILE}"
    return 1
  fi

  local history_file
  for history_file in "${HOME}/.bash_history" "${HOME}/.zsh_history"; do
    if [[ -L "${history_file}" ]]; then
      echo "WARN: Refusing to remove a symlinked shell history file: ${history_file}"
      return 1
    fi
  done

  for history_file in "${HOME}/.bash_history" "${HOME}/.zsh_history"; do
    command rm -f -- "${history_file}" || return
  done

  if [[ -n "${BASH_VERSION:-}" ]]; then
    builtin history -c || return
    HISTFILE="${expected_history_file}"
    builtin history -w "${HISTFILE}" || return
  else
    local previous_histsize="${HISTSIZE:-1000}"
    local previous_savehist="${SAVEHIST:-${previous_histsize}}"

    # Zsh has no history-clear builtin. Switch to a new empty history context so
    # the current session cannot write the old in-memory list back on exit.
    builtin fc -p || return
    HISTFILE="${expected_history_file}"
    HISTSIZE="${previous_histsize}"
    SAVEHIST="${previous_savehist}"
    builtin fc -W "${HISTFILE}" || return
  fi
}

_clear_cliphist_history() {
  if ! command -v cliphist >/dev/null 2>&1; then
    return 0
  fi

  local failed=false
  local -r legacy_db="${HOME}/.cache/cliphist/db"
  if [[ -L "${legacy_db}" ]]; then
    echo "WARN: Refusing to clear a symlinked legacy clipboard database: ${legacy_db}"
    failed=true
  elif [[ -e "${legacy_db}" && (! -f "${legacy_db}" || ! -O "${legacy_db}") ]]; then
    echo "WARN: Refusing to clear an unexpected legacy clipboard database: ${legacy_db}"
    failed=true
  elif [[ -e "${legacy_db}" ]]; then
    if ! command chmod 600 "${legacy_db}" ||
      ! command cliphist -db-path "${legacy_db}" wipe; then
      echo "WARN: Failed to clear the legacy clipboard history."
      failed=true
    fi
  fi

  if [[ -n "${XDG_RUNTIME_DIR:-}" && "${XDG_RUNTIME_DIR}" == /* ]]; then
    local -r session_db="${XDG_RUNTIME_DIR}/cliphist.db"
    if [[ -L "${session_db}" ]]; then
      echo "WARN: Refusing to clear a symlinked session clipboard database: ${session_db}"
      failed=true
    elif [[ -e "${session_db}" && (! -f "${session_db}" || ! -O "${session_db}") ]]; then
      echo "WARN: Refusing to clear an unexpected session clipboard database: ${session_db}"
      failed=true
    elif [[ -e "${session_db}" ]]; then
      if ! command chmod 600 "${session_db}" ||
        ! command cliphist -db-path "${session_db}" wipe; then
        echo "WARN: Failed to clear the session clipboard history."
        failed=true
      fi
    fi
  fi

  [[ "${failed}" == "false" ]]
}

privacy_cleanup() {
  if [[ -z "${HOME:-}" || "${HOME}" != /* ]]; then
    echo "ERROR: Privacy cleanup requires an absolute home path."
    return 1
  fi

  local -r retention_period=1day
  local -r retention_label="1 day"
  local -r retention_minutes=1440
  local -r recent_file="${HOME}/.local/share/recently-used.xbel"
  local -r thumbnail_dir="${HOME}/.cache/thumbnails"
  local -r setup_log_dir="${HOME}/tmp/logs"
  local setup_log_count=0
  local standard_trash_count=0

  if [[ -d "${setup_log_dir}" && ! -L "${setup_log_dir}" ]]; then
    setup_log_count="$(
      command find "${setup_log_dir}" -xdev -type f \
        \( -name '*-setup-dotfiles.log' -o -name '*-setup-arch-bootstrap.log' \) \
        -mmin "+${retention_minutes}" -print 2>/dev/null | awk 'END { print NR + 0 }'
    )"
  fi

  echo "INFO: Privacy cleanup targets:"
  echo "  - Clipboard history"
  echo "  - Bash and Zsh command history"
  echo "  - GTK recent-file metadata"
  if command -v gio >/dev/null 2>&1; then
    standard_trash_count="$(command gio trash --list 2>/dev/null | awk 'END { print NR + 0 }')"
  fi
  echo "  - Standard desktop trash: ${standard_trash_count} item(s)"
  if [[ -d "${HOME}/.trash" && ! -L "${HOME}/.trash" ]]; then
    command du -sh -- "${HOME}/.trash" 2>/dev/null || true
  else
    echo "  - Custom ~/.trash: not present"
  fi
  if [[ -d "${thumbnail_dir}" && ! -L "${thumbnail_dir}" ]]; then
    command du -sh -- "${thumbnail_dir}" 2>/dev/null || true
  else
    echo "  - Thumbnail cache: not present"
  fi
  echo "  - Setup logs older than ${retention_label}: ${setup_log_count} file(s)"

  if [[ -f /etc/arch-release ]]; then
    if [[ -x /usr/bin/journalctl ]]; then
      /usr/bin/journalctl --disk-usage 2>/dev/null || true
    fi
    if [[ -d /var/cache/pacman/pkg ]]; then
      command du -sh -- /var/cache/pacman/pkg 2>/dev/null || true
    fi
    echo "  - Arch package cache: keep the latest 3 versions"
  fi

  echo -n "WARN: Permanently clean these privacy records and caches? (y/n): "
  local answer=""
  read -r answer
  if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
    echo "INFO: Operation canceled."
    return 0
  fi

  local failed=false

  if ! _clear_cliphist_history; then
    echo "WARN: Failed to clear clipboard history."
    failed=true
  fi

  if ! _clear_shell_history; then
    echo "WARN: Failed to clear shell command history."
    failed=true
  fi

  if command -v gio >/dev/null 2>&1; then
    if ! command gio trash --empty; then
      echo "WARN: Failed to empty the standard desktop trash."
      failed=true
    fi
  else
    echo "WARN: gio is unavailable; the standard desktop trash was not emptied."
    failed=true
  fi

  if ! _empty_custom_trash; then
    echo "WARN: Failed to empty the custom ~/.trash directory."
    failed=true
  fi

  if ! command rm -f -- "${recent_file}"; then
    echo "WARN: Failed to remove GTK recent-file metadata."
    failed=true
  fi

  if [[ -L "${thumbnail_dir}" ]]; then
    echo "WARN: Refusing to clean a symlinked thumbnail directory: ${thumbnail_dir}"
    failed=true
  elif [[ -d "${thumbnail_dir}" ]] && ! command find "${thumbnail_dir}" -xdev -depth -mindepth 1 -delete; then
    echo "WARN: Failed to clear the thumbnail cache."
    failed=true
  fi

  if [[ -L "${setup_log_dir}" ]]; then
    echo "WARN: Refusing to clean a symlinked setup log directory: ${setup_log_dir}"
    failed=true
  elif [[ -d "${setup_log_dir}" ]] && ! command find "${setup_log_dir}" -xdev -type f \
    \( -name '*-setup-dotfiles.log' -o -name '*-setup-arch-bootstrap.log' \) \
    -mmin "+${retention_minutes}" -delete; then
    echo "WARN: Failed to remove setup logs older than ${retention_label}."
    failed=true
  fi

  # Root-owned cleanup uses fixed Arch paths so aliases or user-installed
  # wrappers cannot cross the privilege boundary.
  if [[ -f /etc/arch-release ]]; then
    if [[ ! -x /usr/bin/sudo ]]; then
      echo "WARN: sudo is required to clean system journals and the Pacman cache."
      failed=true
    else
      if [[ -x /usr/bin/journalctl ]]; then
        /usr/bin/sudo /usr/bin/journalctl --rotate --vacuum-time="${retention_period}" || {
          echo "WARN: Failed to remove system journal entries older than ${retention_label}."
          failed=true
        }
      fi

      if [[ -x /usr/bin/paccache ]]; then
        /usr/bin/sudo /usr/bin/paccache -r -k 3 || {
          echo "WARN: Failed to prune the Arch package cache."
          failed=true
        }
      else
        echo "WARN: paccache is unavailable; install pacman-contrib."
        failed=true
      fi
    fi
  fi

  if [[ "${failed}" == "true" ]]; then
    echo "WARN: Privacy cleanup completed with errors."
    return 1
  fi

  echo "WARN: Other open shells can write their in-memory history again when they exit."
  echo "DONE: Privacy cleanup completed."
}
alias pclean='privacy_cleanup'

uv_update_all_tools() {
  uv tool upgrade --all 2>/dev/null || {
    local tools
    tools=$(uv tool list | awk '{print $1}')
    if [[ -n "${tools}" ]]; then
      echo "${tools}" | xargs -I {} uv tool install {} --upgrade
    else
      echo "INFO: No uv tools installed."
    fi
  }
}

cargo_binstall_update_tools() {
  if command -v cargo-binstall >/dev/null 2>&1; then
    cargo-binstall --no-confirm cargo-watch || {
      echo "WARN: Failed to update Cargo-managed Rust CLI tools."
    }
  else
    echo "WARN: cargo-binstall is not installed."
  fi
}

upgrade_all_managers() {
  if command -v mise >/dev/null 2>&1; then
    echo "INFO: Updating mise-managed tools..."
    mise upgrade --yes
    mise self-update --yes || true
    mise prune --yes
  fi

  command -v cargo-binstall >/dev/null 2>&1 && cargo_binstall_update_tools
  command -v uv >/dev/null 2>&1 && uv_update_all_tools
}
if typeset -f upgrade_all_managers >/dev/null; then
  alias upall='upgrade_all_managers'
fi

precommit_update_hooks() {
  if ! command -v pre-commit >/dev/null 2>&1; then
    echo "ERROR: pre-commit is not installed."
    return 1
  fi

  if [ ! -f .pre-commit-config.yaml ]; then
    echo "ERROR: .pre-commit-config.yaml not found in current directory."
    return 1
  fi

  pre-commit autoupdate || return
  pre-commit run --all-files || return
  git diff --stat
}
alias pcup='precommit_update_hooks'

_common_excludes=(
  .git node_modules dist build .next .cache .turbo .vite coverage target __pycache__ .venv
  .DS_Store Thumbs.db .idea .vscode .gradle
)

# Keep CLI file colors aligned with the light Paper palette. Defaults from fd/eza/ls
# can look fluorescent on the warm background, especially when tools emit bright ANSI colors.
if [[ "$(uname)" = "Darwin" ]]; then
  export CLICOLOR=1
  export LSCOLORS="gxfxcxdxbxegedabagacad"
else
  export LS_COLORS="di=01;34:ln=36:ex=32:ow=01;34:tw=01;34:*.sh=31:*.zsh=36:*.bash=31:*.rs=33:*.c=34:*.h=36:*.cc=34:*.cpp=34:*.java=31:*.json=36:*.toml=33:*.yaml=33:*.yml=33:*.zip=31:*.7z=31:*.tar=31:*.gz=31"
fi

if command -v eza >/dev/null; then
  _eza_exclude="$(_join_by '|' "${_common_excludes[@]}")"
  xmfl() { command eza --tree --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmfl1() { command eza --tree --level 1 --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmfl2() { command eza --tree --level 2 --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmfl3() { command eza --tree --level 3 --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmflsrc() { command eza --tree src --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmfld() { command eza --tree --only-dirs --all --ignore-glob="${_eza_exclude}" "${@}"; }
  xmfll() {
    local level="${1:-2}"
    command eza --tree --level "${level}" --all --ignore-glob="${_eza_exclude}" "${@:2}"
  }
fi

if command -v tree >/dev/null; then
  _tree_exclude="$(_join_by '|' "${_common_excludes[@]}")"
  tree() { command tree -a -I "${_tree_exclude}" "${@}"; }
  tree1() { command tree -L 1 -a -I "${_tree_exclude}" "${@}"; }
  tree2() { command tree -L 2 -a -I "${_tree_exclude}" "${@}"; }
  tree3() { command tree -L 3 -a -I "${_tree_exclude}" "${@}"; }
  treesrc() { command tree src -a -I "${_tree_exclude}" "${@}"; }
  treed() { command tree -d -a -I "${_tree_exclude}" "${@}"; }
  treel() {
    local level="${1:-2}"
    command tree -L "${level}" -a -I "${_tree_exclude}" "${@:2}"
  }
fi

if command -v fd >/dev/null 2>&1; then
  _FD_CMD="fd"
elif command -v fdfind >/dev/null 2>&1; then
  _FD_CMD="fdfind"
else
  _FD_CMD=""
fi

if [ -n "${_FD_CMD}" ]; then
  _reset_shell_names ff ffs ffe ff-s ffs-s ffe-s fdf fdf-ext fdf-s fdd fdd-s

  _fd_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _fd_exclude_args+=("-E" "${_exclude}"); done

  ff() { "${_FD_CMD}" --color=always -i --hidden "${_fd_exclude_args[@]}" "${@}"; }
  ffs() { "${_FD_CMD}" --color=always -i --hidden "${_fd_exclude_args[@]}" "^${*}"; }
  ffe() { "${_FD_CMD}" --color=always -i --hidden "${_fd_exclude_args[@]}" "${*}$"; }
  ff-s() { "${_FD_CMD}" --color=always -s --hidden "${_fd_exclude_args[@]}" "${@}"; }
  ffs-s() { "${_FD_CMD}" --color=always -s --hidden "${_fd_exclude_args[@]}" "^${*}"; }
  ffe-s() { "${_FD_CMD}" --color=always -s --hidden "${_fd_exclude_args[@]}" "${*}$"; }

  fdf() { "${_FD_CMD}" --color=always -i --hidden -t f "${_fd_exclude_args[@]}" "${@}"; }
  function fdf-ext { "${_FD_CMD}" --color=always -i --hidden -t f "${_fd_exclude_args[@]}" -e "${@}"; }
  fdf-s() { "${_FD_CMD}" --color=always -s --hidden -t f "${_fd_exclude_args[@]}" "${@}"; }
  fdd() { "${_FD_CMD}" --color=always -i --hidden -t d "${_fd_exclude_args[@]}" "${@}"; }
  fdd-s() { "${_FD_CMD}" --color=always -s --hidden -t d "${_fd_exclude_args[@]}" "${@}"; }
else
  _reset_shell_names ff ffs ffe ff-s ffs-s ffe-s fdf fdf-ext fdf-s fdd fdd-s

  _find_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _find_exclude_args+=("-not" "-path" "*/${_exclude}/*"); done

  ff() { find . -iname "*${*}*" "${_find_exclude_args[@]}"; }
  ffs() { find . -iname "${*}*" "${_find_exclude_args[@]}"; }
  ffe() { find . -iname "*${*}" "${_find_exclude_args[@]}"; }
  ff-s() { find . -name "*${*}*" "${_find_exclude_args[@]}"; }
  ffs-s() { find . -name "${*}*" "${_find_exclude_args[@]}"; }
  ffe-s() { find . -name "*${*}" "${_find_exclude_args[@]}"; }

  function fdf { find . -type f -iname "*${1}*" "${_find_exclude_args[@]}"; }
  function fdf-ext { echo 'ERROR: fd not installed. Use: find . -name "*.ext"'; }
  function fdd { find . -type d -iname "*${1}*" "${_find_exclude_args[@]}"; }
fi

if command -v rg >/dev/null 2>&1; then
  _rg_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _rg_exclude_args+=("-g" "!${_exclude}/*"); done

  rgp() { rg --column --line-number --no-heading --smart-case --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --fixed-strings "${@}"; }
  rgp-s() { rg --column --line-number --no-heading --case-sensitive --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --fixed-strings "${@}"; }
  rgr() { rg --column --line-number --no-heading --smart-case --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --regexp "${@}"; }
  rgr-s() { rg --column --line-number --no-heading --case-sensitive --hidden --follow "${_rg_exclude_args[@]}" --color 'always' --regexp "${@}"; }
else
  _grep_exclude_args=()
  for _exclude in "${_common_excludes[@]}"; do _grep_exclude_args+=("--exclude-dir=${_exclude}"); done

  rgp() { grep --recursive --line-number --color=always --ignore-case "${_grep_exclude_args[@]}" --fixed-strings "${@}"; }
  rgp-s() { grep --recursive --line-number --color=always "${_grep_exclude_args[@]}" --fixed-strings "${@}"; }
  rgr() { grep --recursive --line-number --color=always --ignore-case "${_grep_exclude_args[@]}" --extended-regexp "${@}"; }
  rgr-s() { grep --recursive --line-number --color=always "${_grep_exclude_args[@]}" --extended-regexp "${@}"; }
fi

if command -v eza >/dev/null 2>&1; then
  _EZA_CMD="eza"
else
  _EZA_CMD=""
fi

unalias ls lsa lt ll 2>/dev/null || true
if [ -n "${_EZA_CMD}" ]; then
  ls() { "${_EZA_CMD}" -F --group-directories-first --color=auto "${@}"; }
  lsa() { "${_EZA_CMD}" -abghilmuF --group-directories-first --git --time-style=long-iso --icons --header "${@}"; }
  lt() { "${_EZA_CMD}" -T --all --icons --ignore-glob="${_eza_exclude}" "${@}"; }
  alias ll="ls -hal --git"
else
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    alias ls='ls -AFG'
    alias ll='ls -AFGhlp'
    alias lsa='ls -alFG'
  else
    alias ls='ls -AF --color=auto'
    alias ll='ls -AFhlp --color=auto'
    alias lsa='ls -al --color=auto'
  fi
fi

fde() {
  if [ -z "${_FD_CMD}" ] || [ -z "${_EZA_CMD}" ]; then
    echo "ERROR: fde requires fd and eza."
    return 1
  fi

  local target="${1:-.}"
  "${_FD_CMD}" . "${target}" -X "${_EZA_CMD}" -ld --icons --git
}

if command -v batcat >/dev/null; then
  alias bat="batcat --theme ansi"
elif command -v bat &>/dev/null; then
  alias bat="bat --theme ansi"
fi

del() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: Please specify a file or directory to delete."
    return 1
  fi

  local trash_base="$HOME/.trash"
  local time_stamp
  time_stamp=$(date +%Y%m%d_%H%M%S)
  local dest="$trash_base/$time_stamp"

  command mkdir -p "$dest"
  command mv -iv "$@" "$dest"
}

_empty_custom_trash() {
  if [[ -z "${HOME:-}" || "${HOME}" != /* ]]; then
    echo "WARN: Refusing to empty custom trash with an invalid home path."
    return 1
  fi

  local -r trash_base="${HOME}/.trash"
  if [[ -L "${trash_base}" ]]; then
    echo "WARN: Refusing to empty a symlinked custom trash directory: ${trash_base}"
    return 1
  fi
  if [[ -e "${trash_base}" && ! -d "${trash_base}" ]]; then
    echo "WARN: Refusing to replace a non-directory custom trash path: ${trash_base}"
    return 1
  fi

  command mkdir -p -- "${trash_base}" || return
  command find "${trash_base}" -xdev -depth -mindepth 1 -delete
}

empty-trash() {
  echo -n "WARN: Empty the trash permanently? (y/n): "
  local answer=""
  read -r answer

  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    if _empty_custom_trash; then
      echo "DONE: All files in custom trash have been permanently deleted."
    else
      echo "ERROR: Failed to empty custom trash."
      return 1
    fi
  else
    echo "INFO: Operation canceled."
  fi
}

zipf() {
  for file in "${@}"; do
    zip -r "${file}".zip "${file}"
  done
}

djszip() {
  for file in "${@}"; do
    unzip -O cp949 "${file}" -d "${file%%.zip}"
  done
}

if command -v 7zz &>/dev/null; then
  _seven_zip_command="7zz"

elif command -v 7z &>/dev/null; then
  _seven_zip_command="7z"
else
  _seven_zip_command=""
fi

if [ -n "${_seven_zip_command}" ]; then
  djs7z() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" x "${file}" -p"${password}"
    done
  }

  clfz() {
    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on "${file}".7z "${file}"
    done
  }

  clfzp() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on -mhe=on -p"${password}" "${file}".7z "${file}"
    done
  }

  clfzcp() {
    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=copy "${file}".7z "${file}"
    done
  }

  clfzpcp() {
    local password
    printf "%s" "Password: "
    read -rs password
    echo

    for file in "${@}"; do
      "${_seven_zip_command}" a -t7z -m0=copy -mhe=on -p"${password}" "${file}".7z "${file}"
    done
  }
fi

dirdiff() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: dirdiff <directory1> <directory2> [diff_options]"
    return 1
  fi
  local dir1="${1}"
  shift
  local dir2="${1}"
  shift

  local args=("${_common_excludes[@]/#/--exclude=}")

  diff --brief --recursive "${args[@]}" "${dir1}" "${dir2}" "${@}"
}

_single_file_run_path() {
  case "${1}" in
    */*) printf "%s\n" "${1}" ;;
    *) printf "./%s\n" "${1}" ;;
  esac
}

_run_with_optional_input() {
  local src="${1}"
  shift

  local input="${src%.*}.in"
  if [ -f "${input}" ]; then
    "${@}" <"${input}"
  else
    "${@}"
  fi
}

# Single-file source runners for quick experiments.
# Project builds should use the project's build tool instead.
crun() {
  local src="${1}"
  if [ -z "${src}" ]; then
    echo "Usage: crun <file.c>"
    return 1
  fi

  local exe="${src%.*}"
  local run_exe
  run_exe="$(_single_file_run_path "${exe}")"

  rm -f -- "${exe}"
  cc -std=c17 \
    -g -O2 \
    -Wall -Wextra -Wshadow -Wformat=2 \
    -Wconversion -Wsign-conversion -Werror -pedantic \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "${src}" -o "${exe}" -lm || return

  _run_with_optional_input "${src}" "${run_exe}"
  local exit_status="${?}"
  rm -f -- "${exe}"
  return "${exit_status}"
}

cpprun() {
  local src="${1}"
  if [ -z "${src}" ]; then
    echo "Usage: cpprun <file.cc|file.cpp|file.cxx>"
    return 1
  fi

  local exe="${src%.*}"
  local run_exe
  run_exe="$(_single_file_run_path "${exe}")"

  rm -f -- "${exe}"
  c++ -std=c++23 \
    -g -O2 \
    -Wall -Wextra -Wshadow -Wformat=2 \
    -Wconversion -Wsign-conversion -Werror -pedantic \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "${src}" -o "${exe}" || return

  _run_with_optional_input "${src}" "${run_exe}"
  local exit_status="${?}"
  rm -f -- "${exe}"
  return "${exit_status}"
}

pyrun() {
  local src="${1}"
  if [ -z "${src}" ]; then
    echo "Usage: pyrun <file.py>"
    return 1
  fi

  _run_with_optional_input "${src}" python3 -u "${src}"
}

javarun() {
  local src="${1}"
  if [ -z "${src}" ]; then
    echo "Usage: javarun <file.java>"
    return 1
  fi

  local src_dir
  src_dir="$(dirname "${src}")"

  local class_name
  class_name="$(basename "${src}" .java)"

  find "${src_dir}" -maxdepth 1 -type f \( -name "${class_name}.class" -o -name "${class_name}"'$'"*.class" \) -delete
  javac "${src}" || return

  _run_with_optional_input "${src}" java -cp "${src_dir}" "${class_name}"
  local exit_status="${?}"
  find "${src_dir}" -maxdepth 1 -type f \( -name "${class_name}.class" -o -name "${class_name}"'$'"*.class" \) -delete
  return "${exit_status}"
}

rustrun() {
  local src="${1}"
  if [ -z "${src}" ]; then
    echo "Usage: rustrun <file.rs>"
    return 1
  fi

  local exe="${src%.*}"
  local run_exe
  run_exe="$(_single_file_run_path "${exe}")"

  rm -f -- "${exe}"
  rustc -C debuginfo=2 -C opt-level=2 "${src}" -o "${exe}" || return

  _run_with_optional_input "${src}" "${run_exe}"
  local exit_status="${?}"
  rm -f -- "${exe}"
  return "${exit_status}"
}

sshload() {
  if [[ "${#}" -eq 0 ]]; then
    echo "Usage: sshload <private-key> [...]"
    return 1
  fi

  if ! command -v ssh-add >/dev/null 2>&1; then
    echo "ERROR: ssh-add is unavailable."
    return 1
  fi

  local agent_status=0
  command ssh-add -l >/dev/null 2>&1 || agent_status="${?}"

  # ssh-add returns 2 only when it cannot contact an authentication agent.
  if [[ "${agent_status}" -eq 2 ]]; then
    if ! command -v ssh-agent >/dev/null 2>&1; then
      echo "ERROR: ssh-agent is unavailable."
      return 1
    fi

    unset SSH_AUTH_SOCK SSH_AGENT_PID
    eval "$(command ssh-agent -s -t 8h)" || return
    echo "INFO: Started new SSH agent (PID: ${SSH_AGENT_PID})."
  fi

  local success_count=0
  local failure_count=0
  local key

  for key in "${@}"; do
    if [[ -f "${key}" ]]; then
      if command ssh-add -t 8h "${key}"; then
        echo "DONE: Key '${key}' added successfully."
        ((success_count++))
      else
        echo "ERROR: Failed to add key '${key}'. Check passphrase or permissions."
        ((failure_count++))
      fi
    else
      echo "ERROR: Key file '${key}' does not exist."
      ((failure_count++))
    fi
  done

  echo ""
  echo "INFO: Currently loaded SSH keys:"
  command ssh-add -l
  echo ""
  echo "INFO: Summary: ${success_count} keys added successfully, ${failure_count} failures."
  [[ "${failure_count}" -eq 0 ]]
}

sshkill() {
  if [[ -n "${SSH_AGENT_PID:-}" ]] && kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
    eval "$(command ssh-agent -k)"
    echo "DONE: Stopped the current SSH agent."
    return
  fi

  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    command ssh-add -D || return
    echo "DONE: Removed all identities from the current SSH agent."
    return
  fi

  echo "INFO: No SSH agent is available."
}

keep_awake() {
  if [[ "${#}" -eq 0 ]]; then
    echo "Usage: keep_awake <command> [arguments...]"
    return 1
  fi

  if command -v systemd-inhibit >/dev/null 2>&1; then
    command systemd-inhibit \
      --what=sleep \
      --mode=block \
      --why="User-invoked long-running task" \
      "${@}"
    return
  fi

  if command -v caffeinate >/dev/null 2>&1; then
    command caffeinate "${@}"
    return
  fi

  echo "ERROR: No supported sleep inhibitor is available."
  return 1
}

if command -v fzf &>/dev/null; then
  _preview_cmd=""
  if command -v bat &>/dev/null; then
    _preview_cmd="bat --theme ansi"
  elif command -v batcat &>/dev/null; then
    _preview_cmd="batcat --theme ansi"
  else
    _preview_cmd="cat"
  fi

  export FZF_DEFAULT_OPTS="--height 95% --layout=reverse --border --inline-info \
    --preview '${_preview_cmd} --style=numbers --color=always --line-range :500 {}' \
    --preview-window 'right:65%,border-left,follow,cycle,sharp' \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'alt-j:down,alt-k:up' \
    --color='fg:#000000,bg:#f2eede,fg+:#000000,bg+:#b7c9dc,hl:#2f5f8f,hl+:#2f5f8f,info:#303030,prompt:#2f5f8f,pointer:#2f5f8f,marker:#2f5f8f,header:#303030,border:#b8ad94'"

  if [ -n "${_FD_CMD}" ]; then
    export FZF_DEFAULT_COMMAND="${_FD_CMD} --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
  fi

  _list_fzf_dirs() {
    if [ -n "${_FD_CMD}" ]; then
      "${_FD_CMD}" --type d --hidden --follow --exclude .git
    else
      find . -path '*/.*' -prune -o -type d -print
    fi
  }

  if [[ $- == *i* ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      if [ -n "${ZSH_VERSION:-}" ]; then
        source <(fzf --zsh)
      elif [ -n "${BASH_VERSION:-}" ]; then
        source <(fzf --bash)
      fi
    else
      if [ -n "${ZSH_VERSION:-}" ] && [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
      elif [ -n "${BASH_VERSION:-}" ] && [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
        [ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
      elif [ -n "${ZSH_VERSION:-}" ] && [ -f ~/.fzf.zsh ]; then
        source ~/.fzf.zsh
      elif [ -n "${BASH_VERSION:-}" ] && [ -f ~/.fzf.bash ]; then
        source ~/.fzf.bash
      fi
    fi
  fi

  fe() {
    local file
    file=$(fzf --query="${1}" --select-1 --exit-0)
    [ -n "${file}" ] && ${EDITOR:-vim} "${file}"
  }

  fcd() {
    local dir
    dir=$(_list_fzf_dirs | fzf --preview 'tree -C {} | head -100' --preview-window 'right:50%')
    [ -n "${dir}" ] && cd "${dir}" || return
  }

  fgb() {
    local branch
    local target_branch
    branch=$(git branch --all | grep -v 'HEAD' | fzf --header "[Git Branches]" --preview-window 'hidden')
    target_branch=$(echo "${branch}" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    [ -n "${target_branch}" ] && git checkout "${target_branch}"
  }

  fkill() {
    local pid
    pid=$(ps -u "${USER}" -o pid,stat,comm | fzf --header '[Kill Process]' --height 50% --preview-window 'hidden' | awk '{print $1}')
    [ -n "${pid}" ] && echo "${pid}" | xargs kill -9
  }

  fhist() {
    local command_line
    command_line=$(history | fzf --height 95% --layout=reverse --tiebreak=index | sed 's/^[ ]*[0-9]*[ ]*//')
    if [ -n "${ZSH_VERSION:-}" ]; then
      print -z "${command_line}"
    else
      printf "%s\n" "${command_line}"
    fi
  }
fi
