# zdotdir

Based on https://github.com/getantidote/zdotdir

# Installation

Works on macOS and Linux (apt, dnf/yum, pacman, zypper, apk). Installs zsh, git, eza and atuin,
clones this repo into `~/.config/zsh`, hooks it into `~/.zshenv` and sets zsh as the login shell.

```
# current user
curl -fsSL https://raw.githubusercontent.com/slazarov/zdotdir/main/install.sh | sh

# Linux: several users at once
curl -fsSL https://raw.githubusercontent.com/slazarov/zdotdir/main/install.sh | sudo sh -s -- --user=admin,deploy
```

Options: `--branch=NAME`, `--reset` (clear plugin caches), `--no-packages`, `--no-chsh`. Re-running updates an existing install.

# Plugins folder sources

Git: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git (auto-updates)

OMZ lib (git.zsh, clipboard.zsh, needed by the git plugin): https://github.com/ohmyzsh/ohmyzsh/tree/master/lib (auto-updates)

Podman: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/podman

Docker: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker

Docker compose:https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose

Eza: https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza (auto-updates)

Systemd: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/systemd/systemd.plugin.zsh

Atuin: https://github.com/atuinsh/atuin (Ctrl+R history search, loaded only when `atuin` is installed)

Only the git plugin, the OMZ lib files and the `_eza` completion are auto-updated by the weekly workflow. The docker, docker-compose, podman and systemd plugins (including their bundled completions) are local copies with custom changes and must be updated by hand.
