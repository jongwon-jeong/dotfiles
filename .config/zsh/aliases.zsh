# ~/.config/zsh/aliases.zsh
# ----------------------------------------------------------
alias g='git'
alias ga='git add --verbose'
alias gb='git branch --verbose'
alias gc='git commit --verbose'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gf='git fetch --verbose'
alias gl='git pull --verbose'
alias gm='git merge --verbose'
alias gp='git push --verbose'
alias gr='git remote --verbose'
alias grb='git rebase --verbose'
alias gs='git status'
alias gst='git stash'
alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

alias gaa='git add --verbose --all'
alias gcm='git commit --verbose --message'
alias gca='git commit --verbose --all'
alias gcam='git commit --verbose --all --message'

alias gcob='git checkout -b'
alias gbr='git branch --verbose --remote'

alias gsta='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'

alias grba='git rebase --verbose --abort'
alias grbc='git rebase --verbose --continue'
alias grbi='git rebase --verbose --interactive'
alias grbo='git rebase --verbose --onto'
alias grbs='git rebase --verbose --skip'

alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

alias dt='mkdir -p ~/Desktop && cd ~/Desktop'
alias dc='mkdir -p ~/Documents && cd ~/Documents'
alias dl='mkdir -p ~/Downloads && cd ~/Downloads'
alias music='mkdir -p ~/Music && cd ~/Music'
alias vid='mkdir -p ~/Videos && cd ~/Videos'
alias pic='mkdir -p ~/Pictures && cd ~/Pictures'
alias p='mkdir -p ~/proj && cd ~/proj'

print256color () {
  for i in {0..255}; do printf "\e[38;5;${i}mcolour%-5s\e[0m" "$i"; if (( (i + 1) % 10 == 0 )); then printf "\n"; fi; done
}

alias c='clear'
alias h='history | tail -n 20'

histrm () {
  clear
  [ -f ~/.bash_history ] && rm -f ~/.bash_history
  [ -f ~/.zsh_history ] && rm -f ~/.zsh_history
  [ -d ~/.zsh_cache ] && rm -rf ~/.zsh_cache
  exec $SHELL
}

alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ll='ls -AFhlp'
alias ls='ls -AF --color=auto'

alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .1='cd ../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'

alias numFiles='echo $(ls -1 | wc -l)'

cd () { builtin cd "$@"; ls; }
mkcd () { mkdir -p "$1" && cd "$1"; }

ff () { find . -iname "*$@*" -not -path "./.git/*" ; }
ffs () { find . -iname "$@*" -not -path "./.git/*" ; }
ffe () { find . -iname "*$@" -not -path "./.git/*" ; }

alias fdf='fd --hidden -t f --glob "!.git/*" -i'
alias fdf_ext='fd --hidden -t f --glob "!.git/*" -i -e'
alias fdf_s='fd --hidden -t f --glob "!.git/*" -s'
alias fdd='fd --hidden -t d --glob "!.git/*" -i'
alias fdd_s='fd --hidden -t d --glob "!.git/*" -s'

alias grs='grep --recursive --line-number --color=always --ignore-case --exclude-dir=.git --fixed-strings'
alias grr='grep --recursive --line-number --color=always --ignore-case --exclude-dir=.git --extended-regexp'

alias rgs='rg --column --line-number --no-heading --smart-case --hidden --follow --glob "!.git/*" --color "always" --fixed-strings'
alias rgr='rg --column --line-number --no-heading --smart-case --hidden --follow --glob "!.git/*" --color "always" --regexp'

zipf () {
  for file in "$@"
  do
    zip -r "$file".zip "$file" ;
  done
}

djszip () {
  for file in "$@"
  do
    unzip -O cp949 "$file" -d "${file%%.zip}"
  done
}

if command -v 7zz &> /dev/null; then
  sevenZipCommand="7zz"

elif command -v 7z &> /dev/null; then
  sevenZipCommand="7z"
else
  sevenZipCommand=""
  return 1
fi

djs7z () {
  printf "%s" "Password: "
  read -s PASSWORD
  echo

  for file in "$@"
  do
    $sevenZipCommand x "$file" -p"$PASSWORD"
  done
}

clfz () {
  for file in "$@"
  do
    $sevenZipCommand a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on "$file".7z "$file"
  done
}

clfzp () {
  printf "%s" "Password: "
  read -s PASSWORD
  echo

  for file in "$@"
  do
    $sevenZipCommand a -t7z -m0=lzma2 -mx=0 -mfb=64 -md=32m -ms=on -mhe=on -p"$PASSWORD" "$file".7z "$file"
  done
}

clfzcp () {
  for file in "$@"
  do
    $sevenZipCommand a -t7z -m0=copy "$file".7z "$file"
  done
}

clfzpcp () {
  printf "%s" "Password: "
  read -s PASSWORD
  echo

  for file in "$@"
  do
    $sevenZipCommand a -t7z -m0=copy -mhe=on -p"$PASSWORD" "$file".7z "$file"
  done
}

alias tmls='tmux ls'
alias tmat='tmux attach -t'
alias tmdt='tmux detach'
alias tmkl='tmux kill-session'

vimrc () {
  if [ -f ~/.vimrc ]; then
    vim ~/.vimrc

  elif [ -f ~/.vim/vimrc ]; then
    vim ~/.vim/vimrc
  else
    echo "File does not exist."
  fi
}

nvimrc () {
  if [ -f ~/.config/nvim/init.lua ];then
    vim ~/.config/nvim/init.lua

  elif [ -f ~/.config/nvim/init.vim ]; then
    vim ~/.config/nvim/init.vim
  else
    echo "File does not exist."
  fi
}

alias zshrc='test -f ~/.zshrc && vim ~/.zshrc || echo "File does not exist."'
alias alish='test -f ~/.config/zsh/aliases.zsh && vim ~/.config/zsh/aliases.zsh || echo "File does not exist."'
alias dotfiles='test -d ~/.dotfiles && cd ~/.dotfiles || echo "Directory does not exist."'
alias zsh='exec zsh'

dirdiff () {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: dirdiff <directory1> <directory2> [diff_options]"
    return 1
  fi
  DIR1=$(printf '%q' "$1"); shift
  DIR2=$(printf '%q' "$1"); shift
  diff --brief --recursive ${DIR1} ${DIR2} "$@"
}

updatectags () {
  local find_excludes="-path './.git' -prune -o -path './node_modules' -prune -o -path './build' -prune"
  local ctags_excludes="--exclude=.git --exclude=node_modules --exclude=build"
  local ctags_opts="--append=no --fields=+iaS --extras=+q --python-kinds=-i --languages=python"

  if ! command -v ctags >/dev/null 2>&1; then
    return 1
  fi

  local exts=("$@")
  local find_cmd

  if [ ${#exts[@]} -eq 0 ]; then
    find_cmd="find . ${find_excludes} -o -type f -print"
  else
    local find_expr=""
    for ext in "${exts[@]}"; do
      [ -n "$find_expr" ] && find_expr+=" -o "
      find_expr+="-name '*.${ext}'"
    done
    find_cmd="find . ${find_excludes} -o -type f \( ${find_expr} \) -print"
  fi

  local pipeline_cmd="${find_cmd} | ctags ${ctags_excludes} ${ctags_opts} -L -"

  eval "${pipeline_cmd}"

  if command -v entr >/dev/null 2>&1; then
    local file_list
    file_list=$(eval "${find_cmd}")

    if [ -n "$file_list" ]; then
      printf "%s\n" "$file_list" | entr -c /bin/zsh -c "${pipeline_cmd}"
    fi
  fi
}

if command -v trash-list >/dev/null 2>&1; then
  # alias rm=rm_alert
  rm_alert() {
    echo "This is not the command you are looking for."
    echo ""
    echo "https://github.com/andreafrancia/trash-cli"
    echo ""
    echo "Original trash-cli commands:"
    echo "trash-put           trash files and directories."
    echo "trash-empty         empty the trashcan(s)."
    echo "trash-list          list trashed files."
    echo "trash-restore       restore a trashed file."
    echo "trash-rm            remove individual files from the trashcan."
    echo ""
    echo "Customized commands:"
    echo "trash               trash-put -fv"
    echo "trash-clean         trash-empty --all-users --verbose --dry-run  # 실제 삭제 전 미리보기"
    echo "trash-empty         trash-empty --all-users -fv  # 실제로 삭제"
    echo "trash-list          trash-list --all-users"
    echo "trash-mv            trash-restore --sort date"
    echo "trash-rm            trash-rm -fv"
    echo "trash-dir           cd ~/.local/share/Trash/ && ls"
    echo ""
    echo "Where the trashed files go?"
    echo "~/.local/share/Trash/"
    echo ""
    false
  }
  alias trash='trash-put -fv'
  alias trash-clean='trash-empty --all-users --verbose --dry-run' # 실제 삭제 전 미리보기
  alias trash-empty='trash-empty --all-users -fv' # 실제로 삭제
  alias trash-list='trash-list --all-users'
  alias trash-mv='trash-restore --sort date'
  alias trash-rm='trash-rm -fv'
  alias trash-dir='cd ~/.local/share/Trash/ && ls'
  alias trash-help=rm_alert
fi

if [[ "$(uname)" = "Linux" ]]; then
  alias cp='cp --no-preserve=all --verbose --recursive'

  if [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
    alias as="apt-cache search"

    alias bubo='sudo apt update && apt list --upgradable'
    alias bubc='sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean'
    alias bubu='bubo && bubc'
  fi

  if [[ "$(uname -a)" =~ "WSL" ]]; then
    alias f='explorer.exe'
  else
    alias f='xdg-open'
  fi

elif [ "$(uname)" = "Darwin" ];then
  alias cp='cp -RXiv'
  alias f='open -a Finder'

  alias bubo='brew update && brew outdated'
  alias bubc='brew upgrade && brew cleanup'
  alias bubu='bubo && bubc'
fi
