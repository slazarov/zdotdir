# zdotdir
Based on https://github.com/getantidote/zdotdir

# Installation
Clone this project to $ZDOTDIR, and then make ~/.zshenv source $ZDOTDIR/.zshenv.
```
# clone this project
ZDOTDIR=~/.config/zsh
git clone --branch main https://github.com/slazarov/zdotdir $ZDOTDIR

# source the .zshenv from ZDOTDIR
[[ -f ~/.zshenv ]] && mv -f ~/.zshenv ~/.zshenv.bak
echo ". $ZDOTDIR/.zshenv" > ~/.zshenv

# start a new zsh session
zsh
```
# Plugins folder sources
Git: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git (auto-updates)

Podman: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/podman

Docker: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker

Docker compose:https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose

Eza: https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza (auto-updates)
