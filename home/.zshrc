# ~/.zshrc
# ----------------------------------------------------------
# Keep interactive zsh startup here; shared aliases/functions belong in ~/.config/shell/aliases.sh.
[[ -o interactive ]] || return

export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"
export PATH="${HOME}/.local/bin:${PATH}"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"
setopt NO_BEEP
bindkey -v

# Normalize common terminal editing keys across GNOME Terminal, Alacritty, tmux,
# and SSH sessions. In zsh vi mode, unbound escape sequences can leak into vi
# command widgets, so bind both insert and command keymaps explicitly.
zmodload -i zsh/terminfo 2>/dev/null || true
bind_terminal_key() {
  local key_sequence="${1}"
  local widget="${2}"
  local keymap

  [[ -n "${key_sequence}" ]] || return 0

  for keymap in emacs viins vicmd; do
    bindkey -M "${keymap}" "${key_sequence}" "${widget}" 2>/dev/null || true
  done
}

# Home -> beginning of line
for key_sequence in "${terminfo[khome]:-}" $'\e[H' $'\eOH' $'\e[1~' $'\e[7~'; do
  bind_terminal_key "${key_sequence}" beginning-of-line
done

# End -> end of line
for key_sequence in "${terminfo[kend]:-}" $'\e[F' $'\eOF' $'\e[4~' $'\e[8~'; do
  bind_terminal_key "${key_sequence}" end-of-line
done

# Page Up -> previous history entry matching the current input prefix
for key_sequence in "${terminfo[kpp]:-}" $'\e[5~'; do
  bind_terminal_key "${key_sequence}" history-beginning-search-backward
done

# Page Down -> next history entry matching the current input prefix
for key_sequence in "${terminfo[knp]:-}" $'\e[6~'; do
  bind_terminal_key "${key_sequence}" history-beginning-search-forward
done

# Ctrl+Left -> move backward by word
for key_sequence in $'\e[1;5D' $'\e[5D' $'\eOd'; do
  bind_terminal_key "${key_sequence}" backward-word
done

# Ctrl+Right -> move forward by word
for key_sequence in $'\e[1;5C' $'\e[5C' $'\eOc'; do
  bind_terminal_key "${key_sequence}" forward-word
done

# Delete -> delete character under cursor
for key_sequence in "${terminfo[kdch1]:-}" $'\e[3~'; do
  bind_terminal_key "${key_sequence}" delete-char
done

# Ctrl+Delete -> delete next word
for key_sequence in $'\e[3;5~'; do
  bind_terminal_key "${key_sequence}" kill-word
done

# Backspace -> delete previous character
for key_sequence in $'\C-h' $'\C-?'; do
  bind_terminal_key "${key_sequence}" backward-delete-char
done

# Ctrl+U -> delete from cursor to beginning of line
for key_sequence in $'\C-u'; do
  bind_terminal_key "${key_sequence}" backward-kill-line
done

# Ctrl+K -> delete from cursor to end of line
for key_sequence in $'\C-k'; do
  bind_terminal_key "${key_sequence}" kill-line
done

# Ctrl+L -> clear screen
for key_sequence in $'\C-l'; do
  bind_terminal_key "${key_sequence}" clear-screen
done

if [[ "$(uname)" = "Linux" ]]; then
  zshAutoDir=~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  zshHighDir=~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  [ -f ${zshAutoDir} ] && source ${zshAutoDir}
  fpath=(~/.zsh/zsh-completions/src ${fpath})

  autoload -Uz compinit
  if [ -f ~/.zcompdump ] && [ $(date +'%j') != $(date -r ~/.zcompdump +'%j') ]; then
    compinit
  else
    compinit -C
  fi

  [ -f ${zshHighDir} ] && source ${zshHighDir}
  fpath=(${HOME}/.local/bin ${fpath})
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'

elif [ "$(uname)" = "Darwin" ]; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

  if type brew &>/dev/null; then
    zshAutoDir="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    zshHighDir="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    [ -f ${zshAutoDir} ] && source ${zshAutoDir}
    [ -f ${zshHighDir} ] && source ${zshHighDir}
    FPATH=$(brew --prefix)/share/zsh-completions:${FPATH}
    autoload -Uz compinit
    compinit
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244,bold'
  fi
fi

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

setopt local_options nullglob
for config_file in "${HOME}/.config/shell"/*.sh "${HOME}/.config/zsh"/*.zsh; do
  if [ -f "${config_file}" ]; then
    source "${config_file}"
  fi
done

if [ -f "${HOME}/.zshrc.secret" ]; then
  source "${HOME}/.zshrc.secret"
fi

if [[ "${TERM_PROGRAM}" != "Apple_Terminal" ]] && \
  [[ "${TERM}" != "screen" ]] && \
  [[ "${TERM}" != "tmux" ]] && \
  [[ "${TERM}" != "linux" ]]; then
  export COLORTERM="truecolor"
fi

export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=1000
export SAVEHIST=${HISTSIZE}

export UNZIP="-O cp949"
export ZIPINFO="-O cp949"

setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

local_env_file="${HOME}/.local/bin/env"
[ -f "${local_env_file}" ] && . "${local_env_file}"
