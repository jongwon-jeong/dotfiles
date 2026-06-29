#!/usr/bin/env bash

# Keep dotfile deployment behavior centralized here.

start_logging() {
  local -r log_dir="${HOME}/tmp/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-setup-dotfiles.log"

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
}

show_script_info() {
  echo "INFO: basename: ${0##*/}"
  echo "INFO: dirname : $(dirname "${0}")"
  echo "INFO: pwd     : $(pwd)"
  echo ""
}

is_linux() {
  [[ "$(uname)" == "Linux" ]]
}

is_mac() {
  [[ "$(uname)" == "Darwin" ]]
}

refuse_root_execution() {
  if ((EUID == 0)); then
    echo "ERROR: Do not run setup_dotfiles.sh as root."
    echo "   Run it as your normal user so HOME points to the account that owns these dotfiles."
    exit 1
  fi
}

initialize_variables() {
  dotfiles_base="${HOME}/.dotfiles"
  backup_dir="${HOME}/.local/share/backups"
  mkdir -pv "${backup_dir}"
}

find_and_move_to_dotfiles_root() {
  dotfiles_root="$(cd "$(dirname "$0")/.." && pwd)" || {
    echo "ERROR: Unable to find dotfiles root from script location."
    return 1
  }

  echo "INFO: Dotfiles root: ${dotfiles_root}"
  cd "${dotfiles_root}" || {
    echo "ERROR: Unable to move to directory '${dotfiles_root}'."
    return 1
  }
}

create_dir() {
  mkdir -pv "${1}"
}

backup_if_exists() {
  local target_path="${1}"
  if [ -e "${target_path}" ] && [ ! -L "${target_path}" ]; then
    echo "INFO: Backing up existing file/directory: ${target_path}"
    mv -fv "${target_path}" "${backup_dir}/${target_path##*/}.$(date +"%Y%m%d_%H%M%S").bak"
  fi
}

create_symlink() {
  local source_path="${1}"
  local target_path="${2}"

  if [ ! -e "${source_path}" ]; then
    echo "ERROR: Source file/directory not found: ${source_path}"
    return 1
  fi

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    echo "DONE: Symlink already exists and is correct: ${target_path}"
    return 0
  fi

  backup_if_exists "${target_path}"

  if is_linux; then
    ln --force --symbolic --verbose "${source_path}" "${target_path}"
  elif is_mac; then
    ln -fsv "${source_path}" "${target_path}"
  fi
}

link_recursive() {
  local src_dir="${1}"
  local dest_dir="${2}"

  create_dir "${dest_dir}"

  shopt -s dotglob nullglob

  for item_path in "${src_dir}"/*; do
    local item_name="${item_path##*/}"
    local src_item="${src_dir}/${item_name}"
    local dest_item="${dest_dir}/${item_name}"

    if [[ "${item_name}" == ".DS_Store" ]]; then
      continue
    fi

    if [ -d "${src_item}" ]; then
      link_recursive "${src_item}" "${dest_item}"
    else
      create_symlink "${src_item}" "${dest_item}"
    fi
  done

  shopt -u dotglob nullglob
}

copy_files() {
  local srcs=("${@:1:$#-1}")
  local dest="${!#}"

  if is_linux; then
    cp --force --archive --verbose "${srcs[@]}" "${dest}"

  elif is_mac; then
    cp -RXv "${srcs[@]}" "${dest}"
  fi
}

backup_and_copy_dotfiles() {
  if [ "${dotfiles_root}" != "${dotfiles_base}" ]; then
    if [ -d "${dotfiles_base}" ]; then
      create_dir "${backup_dir}"
      mv -fv "${dotfiles_base}" "${backup_dir}/dotfiles_old_$(date +"%Y%m%d_%H%M%S")"
    fi

    if command -v rsync &>/dev/null; then
      rsync -av --exclude='.git' --exclude='.github' "${dotfiles_root}/" "${dotfiles_base}/"
    else
      create_dir "${dotfiles_base}"
      shopt -s dotglob
      for item in "${dotfiles_root}"/*; do
        local item_name="${item##*/}"
        if [[ "${item_name}" == "." || "${item_name}" == ".." || "${item_name}" == ".git" || "${item_name}" == ".github" ]]; then
          continue
        fi

        copy_files "${item}" "${dotfiles_base}"
      done
      shopt -u dotglob
    fi

    cd "${dotfiles_base}" || exit 1
  fi
}

symlink_dotfiles() {
  local repo_home_dir="${dotfiles_base}/home"
  if [ -d "${repo_home_dir}" ]; then
    link_recursive "${repo_home_dir}" "${HOME}"
  fi

  local repo_config_dir="${dotfiles_base}/config"
  if [ -d "${repo_config_dir}" ]; then
    create_dir "${HOME}/.config"

    shopt -s dotglob nullglob
    for item_path in "${repo_config_dir}"/*; do
      local item_name="${item_path##*/}"
      if [[ "${item_name}" == "system" ]]; then
        # System-owned config files are source material for bootstrap scripts.
        # They should be installed into /etc by the owning OS setup function,
        # not exposed as inert user config under ~/.config/system.
        echo "INFO: Skipping system config symlinks: ${item_path}"
        continue
      fi

      if [ -d "${item_path}" ]; then
        link_recursive "${item_path}" "${HOME}/.config/${item_name}"
      else
        create_symlink "${item_path}" "${HOME}/.config/${item_name}"
      fi
    done
    shopt -u dotglob nullglob
  fi
}

main() {
  start_logging
  refuse_root_execution
  show_script_info
  initialize_variables
  find_and_move_to_dotfiles_root

  echo ""
  echo "INFO: Setup dotfiles start"
  printf "%0.s-" {1..60}
  echo ""

  backup_and_copy_dotfiles
  symlink_dotfiles

  echo ""
  printf "%0.s-" {1..60}
  printf "\nDONE: Setup dotfiles done!\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
