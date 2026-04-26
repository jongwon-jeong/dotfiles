#!/usr/bin/env bash

show_script_info() {
  echo "basename: ${0##*/}"
  echo "dirname : $(dirname "${0}")"
  echo "pwd     : $(pwd)"
  echo ""
}

go_to_base_dir() {
  base_dir="$(cd "$(dirname "${0}")" && pwd)"
  cd "${base_dir}" || exit 1
}

start_logging() {
  local -r log_dir="${HOME}/proj/tmp/logs"
  local -r log_file="${log_dir}/$(date +%Y%m%d-%H%M%S)-dotfiles-install.log"

  if ! command -v tee >/dev/null 2>&1; then
    echo "❌ Error: tee is required for logging." >&2
    exit 1
  fi

  if ! mkdir -p "${log_dir}"; then
    echo "❌ Error: Could not create log directory: ${log_dir}" >&2
    exit 1
  fi

  if ! touch "${log_file}"; then
    echo "❌ Error: Could not create log file: ${log_file}" >&2
    exit 1
  fi

  exec > >(tee -a "${log_file}") 2>&1

  echo "Log file: ${log_file}"
  echo ""
}

is_linux() {
  [[ "$(uname)" == "Linux" ]]
}

is_mac() {
  [[ "$(uname)" == "Darwin" ]]
}

is_ubuntu() {
  [[ -f /etc/os-release ]] || return 1
  (
    source /etc/os-release
    [[ "${ID}" == "ubuntu" || "${ID_LIKE}" =~ "ubuntu" ]]
  )
}

run_setup() {
  local setup_bootstrap_script=""
  local setup_dotfiles_script=""

  if is_linux; then
    if is_ubuntu; then
      setup_bootstrap_script="setup_ubuntu_bootstrap.sh"
    else
      echo "⚠️ Warning: Detected unsupported Linux distribution. Proceeding with caution."
    fi

    setup_dotfiles_script="setup_dotfiles.sh"

  elif is_mac; then
    echo "⚠️ Warning: macOS bootstrap is not maintained. Installing dotfiles only."
    setup_dotfiles_script="setup_dotfiles.sh"

  else
    echo "❌ Error: Unsupported operating system: $(uname)"
    exit 1
  fi

  for script_name in "${setup_bootstrap_script}" "${setup_dotfiles_script}"; do
    if [[ -n "${script_name}" ]]; then
      local found=false
      local search_paths=(
        "${base_dir}/${script_name}"
        "${base_dir}/scripts/${script_name}"
      )

      for target in "${search_paths[@]}"; do
        if [[ -f "${target}" ]]; then
          echo "🔄 Running setup script: ${script_name}"
          bash "${target}"
          found=true
          break
        fi
      done

      if [[ "${found}" == "false" ]]; then
        echo "❌ Error: Could not find '${script_name}'."
        echo "   Checked locations:"
        for path in "${search_paths[@]}"; do
          echo "   - ${path}"
        done
        exit 1
      fi
    fi
  done
}

show_reboot_notice() {
  echo ""
  echo "✅ Setup complete. A reboot is recommended."
  echo ""
  echo "Reboot commands:"
  echo "  Ubuntu/Linux: sudo reboot"
  echo "  WSL:          wsl.exe --shutdown"
  echo "  macOS:        sudo shutdown -r now"
}

main() {
  if (($# > 0)); then
    echo "❌ Error: install.sh does not accept options."
    echo "   Run without arguments: bash install.sh"
    exit 1
  fi

  start_logging
  show_script_info
  go_to_base_dir
  run_setup
  show_reboot_notice
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
