#==========================
# FASTFETCH
# =========================
fastfetch --config ~/.config/fastfetch/presets/custom
alias fastfetch='fastfetch --config ~/.config/fastfetch/presets/custom'

# =========================
# STARSHIP PROMPT
# =========================

eval "$(starship init zsh)"
# =========================
# BASIC
# =========================

export PATH="$HOME/.local/bin:$PATH"
autoload -Uz colors && colors

# History
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT



# =========================
# PLUGINS
# =========================

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =========================
# ALIASES
# =========================

alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias cls='clear'

alias ..='cd ..'
alias ...='cd ../..'

alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias c='clear'
alias yay='paru'
alias unusedpkg='sudo pacman -Qdtq | sudo pacman -Rns -'
alias aurchk='cat ~/Desktop/Other/AUR-Malware/list.txt | grep'
alias pctui="pkexec pctui"

# =========================
# ENVIRONMENT
# =========================

export EDITOR=kate
export TERMINAL=kitty
export NVIDIA_DRIVER_CAPABILITIES=all
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
# for golang
# Move Go's workspace out of the home
export GOPATH="$HOME/.local/share/go"
export PATH="$PATH:$GOPATH/bin"
export MOZ_ENABLE_WAYLAND=1
# =========================
# COMPLETIONS
# =========================

autoload -Uz compinit
compinit

# Force explicit matching using the full escape string syntax
bindkey -r "^[[1;5D"
bindkey -r "^[[1;5C"
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

