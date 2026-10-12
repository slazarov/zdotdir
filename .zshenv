#!/bin/zsh
#
# .zshenv - Zsh environment file, loaded always.
#

# NOTE: .zshenv needs to live at ~/.zshenv, not in $ZDOTDIR!

# Set ZDOTDIR if you want to re-home Zsh.
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Fish-like dirs
: ${__zsh_config_dir:=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}
: ${__zsh_user_data_dir:=${XDG_DATA_HOME:-$HOME/.local/share}/zsh}
: ${__zsh_cache_dir:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh}

# There are some OMZ plugins with different alias
ZSH_CACHE_DIR=$__zsh_cache_dir

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

# Directories that go before everything else in $path. Zephyr's environment
# plugin rebuilds $path as ($prepath homebrew /usr/local $path) and reuses this.
typeset -ga prepath=(
  $HOME/{,s}bin(N)
  $HOME/.local/{,s}bin(N)
  $HOME/.cargo/bin(N)
  /home/linuxbrew/.linuxbrew/{,s}bin(N)
)

# Set the list of directories that zsh searches for commands.
path=(
  $prepath
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)
