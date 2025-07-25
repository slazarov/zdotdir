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