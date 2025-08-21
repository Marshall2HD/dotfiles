# --- PATHs & Editors ---
export PATH="$HOME/.local/bin:$PATH"
export VISUAL="hx"
export EDITOR="hx"
export SUDO_EDITOR="hx"

# macOS Homebrew env
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  export PATH="/opt/homebrew/bin:$PATH"
fi

# --- PATH de-dupe (idempotent) ---
path_dedup() { typeset -U path; }
path_dedup

# --- History (fast, big, sane) ---
HISTSIZE=100000
SAVEHIST=$HISTSIZE
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
mkdir -p "${HISTFILE:h}"
setopt appendhistory sharehistory extended_history hist_ignore_space \
       hist_ignore_all_dups hist_save_no_dups hist_find_no_dups \
       hist_reduce_blanks inc_append_history
setopt correct auto_cd autopushd pushdignoredups pipefail
unsetopt beep

# --- Keybindings ---
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# --- Zinit bootstrap ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# Plugins (turbo quiet)
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# OMZ snippets
zinit ice wait lucid
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
# (skipping OMZP::command-not-found on purpose)

# Completions (safe cached)
autoload -Uz compinit; zmodload zsh/complist
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${ZSH_COMPDUMP:h}"
compinit -d "$ZSH_COMPDUMP" -C

# Podman completion (Linux only)
if [[ "$OSTYPE" != darwin* ]] && command -v podman >/dev/null 2>&1; then
  eval "$(podman completion zsh)"
fi

zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# --- Aliases (SMART) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
else
  alias ls='ls --color=auto'
fi

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
else
  alias vim='vi'
fi

alias c='clear'  # always safe

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
else
  alias cat='cat'
fi

# --- Bootstrap installers (GitHub) ---
_bootstrap_dir="$HOME/.local/bootstrap"
mkdir -p "$_bootstrap_dir" "$HOME/.local/bin"

# FZF from GitHub (clone) if missing
if ! command -v fzf >/dev/null 2>&1; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$_bootstrap_dir/fzf"
  "$_bootstrap_dir/fzf/install" --key-bindings --completion --no-bash --no-fish --no-update-rc
  # fzf puts binaries under ~/.fzf/bin
  export PATH="$HOME/.fzf/bin:$PATH"
fi

# zoxide from GitHub install script if missing
if ! command -v zoxide >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- -b "$HOME/.local/bin"
fi

# Helix editor (hx) from GitHub releases if missing
if ! command -v hx >/dev/null 2>&1; then
  _os=""
  _arch="$(uname -m)"
  if [[ "$OSTYPE" == darwin* ]]; then
    _os="apple-darwin"
    [[ "$_arch" == "arm64" || "$_arch" == "aarch64" ]] && _arch="aarch64" || _arch="x86_64"
  else
    _os="linux"
    [[ "$_arch" == "arm64" || "$_arch" == "aarch64" ]] && _arch="aarch64" || _arch="x86_64"
  fi
  _api="https://api.github.com/repos/helix-editor/helix/releases/latest"
  _tag="$(curl -fsSL "$_api" | grep -oE '"tag_name":\s*"[^"]+' | sed 's/.*"//')"
  _asset_pattern="${_arch}-${_os}\.tar\.xz"
  _url="$(curl -fsSL "$_api" | grep -oE '"browser_download_url":\s*"[^"]+' | sed 's/.*"//' | grep "$_asset_pattern" | head -n1)"
  _tmp="$(mktemp -d)"
  curl -fsSL "$_url" -o "$_tmp/helix.tar.xz"
  tar -xJf "$_tmp/helix.tar.xz" -C "$_tmp"
  _hx_dir="$(find "$_tmp" -maxdepth 1 -type d -name 'helix-*' | head -n1)"
  install -m 0755 "$_hx_dir/hx" "$HOME/.local/bin/hx"
  mkdir -p "$HOME/.local/share/helix"
  rsync -a "$_hx_dir/runtime/" "$HOME/.local/share/helix/runtime/"
  export HELIX_RUNTIME="$HOME/.local/share/helix/runtime"
  rm -rf "$_tmp"
fi

# --- fzf & zoxide shell hooks (only if present) ---
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"

# --- oh-my-posh with remote config URL ---
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && command -v oh-my-posh >/dev/null 2>&1; then
  OMP_DIR="$HOME/.config/ohmyposh"; mkdir -p "$OMP_DIR"
  OMP_CONF="$OMP_DIR/remote.toml"
  OMP_URL="https://files.catbox.moe/g70ur6.toml"
  if [[ ! -f "$OMP_CONF" ]]; then
    curl -fsSL "$OMP_URL" -o "$OMP_CONF"
  fi
  eval "$(oh-my-posh init zsh --config "$OMP_CONF")"
fi

# --- Git config: 1Password on macOS ---
if [[ "$OSTYPE" == darwin* ]]; then
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig.1password"
else
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
fi

# --- Nix env (if present) ---
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# kill stray command-not-found handlers
if typeset -f command_not_found_handler >/dev/null; then
  unset -f command_not_found_handler
fi

# mise (guarded)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Device-specific extras
[[ -f "$HOME/.zshrc_extras" ]] && source "$HOME/.zshrc_extras"

# Final PATH clean
path_dedup