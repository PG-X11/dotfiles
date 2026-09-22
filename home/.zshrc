# Fastfetch
fastfetch --config ~/.config/fastfetch/presets/custom
alias fastfetch='fastfetch --config ~/.config/fastfetch/presets/custom'

# Starship
eval "$(starship init zsh)"

# Path & Colors
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

# Completions
autoload -Uz compinit
# Cache completion dump to speed up terminal load time
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Keybindings
bindkey -r "^[[1;5D"
bindkey -r "^[[1;5C"
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Environment
export EDITOR=kate
export TERMINAL=kitty
export NVIDIA_DRIVER_CAPABILITIES=all
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export GOPATH="$HOME/.local/share/go"
export PATH="$PATH:$GOPATH/bin"
export MOZ_ENABLE_WAYLAND=1

# Aliases
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

# Plugins
# Moved plugins to the end so interactive features load after shell setup
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
