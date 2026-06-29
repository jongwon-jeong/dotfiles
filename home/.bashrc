# ~/.bashrc
# ----------------------------------------------------------
# Keep bash-specific interactive behavior here; shared aliases/functions belong in ~/.config/shell/aliases.sh.
[[ $- == *i* ]] || return

export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

export PATH="${HOME}/.local/bin:${PATH}"

if [[ $- == *i* ]]; then
  bind "set completion-ignore-case on"
  bind "set show-all-if-ambiguous on"
  bind "set colored-stats on"
fi

enable_shopt() {
  shopt -s "${1}" 2>/dev/null || true
}

enable_shopt nocaseglob
enable_shopt autocd
enable_shopt cdspell
enable_shopt checkwinsize
enable_shopt histappend

export IGNOREEOF=1
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=100
export HISTFILESIZE=100
export PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

if [ -f "${HOME}/.config/shell/aliases.sh" ]; then
  . "${HOME}/.config/shell/aliases.sh"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
else
  export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\W\[\e[m\]\$ "
fi
