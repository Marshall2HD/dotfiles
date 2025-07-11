export PATH="$PATH:$HOME/.local/bin"
#export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# Nvim as Sudo Editor:
export VISUAL="hx"
export EDITOR="hx"
export SUDO_EDITOR="hx"

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

if [[ "$OSTYPE" != darwin* ]]; then
  eval "$(podman completion zsh)"
fi

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias ~~='!!'
alias pod-pull='sudo podman images --format '{{.Repository}}:{{.Tag}}' | xargs -L1 sudo podman pull'

# Shell integrations
eval "$(fzf --zsh)"

eval "$(zoxide init --cmd cd zsh)"
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#Homebrew stuff
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Initializes oh-my-posh except on apple terminal
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then

  eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/opt/homebrew/bin:$PATH"

#Device Specific Extras
[[ -f "$HOME/.zshrc_extras" ]] && source "$HOME/.zshrc_extras"


##Uses 1Password SSH Agent on MacOS otherwise normal config
if [[ "$OSTYPE" == darwin* ]]; then
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig.1password"
else
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
fi

#Nix something
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# stops nix from crying about shit
if typeset -f command_not_found_handler >/dev/null; then
  unset -f command_not_found_handler
fi

nrs() {
  sudo nixos-rebuild switch --flake .#nyx-0 "$@"
}
eval "$(/Users/marsh/.local/bin/mise activate zsh)"
eval "$(~/.local/bin/mise activate zsh)"
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/agent.sock"

#Automatically start tmux if not already in a session
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
  exec tmux new-session -A -s default
fi