#!/bin/sh
# shellcheck disable=SC2086 # package lists and --user are split on purpose
#
# install.sh - Install this zdotdir on macOS or Linux.
#
# Installs zsh, git, eza and atuin, clones (or updates) the repo into
# ~/.config/zsh, hooks it into ~/.zshenv, imports zsh history into atuin and
# makes zsh the login shell.
#
# Usage:
#   ./install.sh                         # configure the current user
#   sudo ./install.sh --user=admin,deploy  # Linux: configure several users
#
# Options:
#   --user=u1,u2   Users to configure (root only; default: current user)
#   --branch=NAME  Branch to install (default: main)
#   --reset        Remove plugin caches (antidote, zsh cache) before installing
#   --no-packages  Skip installing zsh/git/eza/atuin
#   --no-chsh      Do not change the login shell
#
# Set ZDOTDIR_REPO to install from another URL or a local path/bundle.
#
# Safe to re-run: an existing install is updated with a fast-forward pull.
# Also works piped: curl -fsSL https://raw.githubusercontent.com/slazarov/zdotdir/main/install.sh | sh

set -eu

REPO_URL="${ZDOTDIR_REPO:-https://github.com/slazarov/zdotdir}"

# --- Output ---
if [ -t 1 ]; then
  GREEN='\033[0;32m' RED='\033[0;31m' YELLOW='\033[0;33m' NC='\033[0m'
else
  GREEN='' RED='' YELLOW='' NC=''
fi
info() { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}Warning:${NC} %s\n" "$*" >&2; }
die() { printf "${RED}Error:${NC} %s\n" "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

# --- Arguments ---
users="" branch="main" reset=0 packages=1 do_chsh=1
for arg in "$@"; do
  case "$arg" in
    --user=*) users="${arg#*=}" ;;
    --branch=*) branch="${arg#*=}" ;;
    --reset) reset=1 ;;
    --no-packages) packages=0 ;;
    --no-chsh) do_chsh=0 ;;
    -h|--help) sed -n '2,/^$/s/^# \{0,1\}//p' "$0" 2>/dev/null || true; exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done
case "$branch" in *[!A-Za-z0-9._/-]*|"") die "Invalid branch name: $branch" ;; esac

# --- Platform ---
OS=$(uname -s)
case "$OS" in
  Darwin|Linux) ;;
  *) die "Unsupported OS: $OS" ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64 ;;
  arm64|aarch64) ARCH=aarch64 ;;
  *) ARCH=$(uname -m) ;;
esac

LIBC=gnu
if [ "$OS" = Linux ] && { [ -f /etc/alpine-release ] || ldd --version 2>&1 | grep -qi musl; }; then
  LIBC=musl
fi

ME=$(id -un)
if [ "$(id -u)" -eq 0 ]; then
  IS_ROOT=1 SUDO=""
else
  IS_ROOT=0 SUDO=""
  has sudo && SUDO="sudo"
fi

[ "$OS" = Darwin ] && [ "$IS_ROOT" -eq 1 ] && die "On macOS, run this as your normal user (not with sudo)."

if [ -z "$users" ]; then
  users="$ME"
elif [ "$IS_ROOT" -eq 0 ] && [ "$users" != "$ME" ]; then
  die "Configuring other users (--user=$users) requires root."
fi

# Binaries we download go system-wide as root, otherwise into ~/.local/bin.
if [ "$IS_ROOT" -eq 1 ]; then
  BIN_DIR=/usr/local/bin
else
  BIN_DIR="$HOME/.local/bin"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
chmod 755 "$TMP"

# --- Packages ---
as_root() {
  if [ "$IS_ROOT" -eq 1 ]; then "$@"
  elif [ -n "$SUDO" ]; then $SUDO "$@"
  else die "Need root (or sudo) to run: $*"
  fi
}

# Download a release tarball and install one binary from it into $BIN_DIR.
# $1 = URL, $2 = binary name, $3 = optional URL of a sha256 file
install_binary() {
  url=$1 name=$2 sum_url=${3:-}
  info "Downloading $name from $url"
  dl="$TMP/dl-$name"
  mkdir -p "$dl"
  curl -fsSL "$url" -o "$dl/archive.tar.gz" || { warn "Download of $name failed"; return 1; }
  if [ -n "$sum_url" ]; then
    expected=$(curl -fsSL "$sum_url" | awk '{print $1}')
    if has sha256sum; then actual=$(sha256sum "$dl/archive.tar.gz" | awk '{print $1}')
    else actual=$(shasum -a 256 "$dl/archive.tar.gz" | awk '{print $1}')
    fi
    [ -n "$expected" ] && [ "$expected" = "$actual" ] || { warn "Checksum mismatch for $name, not installing"; return 1; }
  fi
  tar -xzf "$dl/archive.tar.gz" -C "$dl"
  bin=$(find "$dl" -type f -name "$name" | head -n 1)
  [ -n "$bin" ] || { warn "$name not found in archive"; return 1; }
  "$bin" --version >/dev/null 2>&1 || { warn "Downloaded $name does not run on this system, not installing"; return 1; }
  mkdir -p "$BIN_DIR"
  if [ -w "$BIN_DIR" ]; then install -m 755 "$bin" "$BIN_DIR/$name"
  else as_root install -m 755 "$bin" "$BIN_DIR/$name"
  fi
}

install_atuin() {
  atuin --version >/dev/null 2>&1 || "$BIN_DIR/atuin" --version >/dev/null 2>&1 && return 0
  case "$OS" in
    Darwin) target="$ARCH-apple-darwin" ;;
    # The musl build is static, so it also runs on distros with an older glibc.
    Linux) target="$ARCH-unknown-linux-musl" ;;
  esac
  base="https://github.com/atuinsh/atuin/releases/latest/download/atuin-$target.tar.gz"
  install_binary "$base" atuin "$base.sha256" || warn "atuin not installed (no build for $target?)"
}

# eza has no macOS release binaries; Linux falls back to the GitHub release.
install_eza_binary() {
  if [ "$LIBC" = musl ] && [ "$ARCH" != x86_64 ]; then
    warn "eza publishes no $ARCH musl build; skipping eza"
    return 0
  fi
  url="https://github.com/eza-community/eza/releases/latest/download/eza_$ARCH-unknown-linux-$LIBC.tar.gz"
  install_binary "$url" eza || warn "eza not installed (no build for $ARCH/$LIBC?)"
}

# Add eza's apt repository. Writes nothing unless the key downloads and the
# repository works, so a failure can't leave apt broken.
add_eza_apt_repo() {
  info "Adding the eza apt repository"
  key="$TMP/gierens.asc"
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc -o "$key" || return 1
  grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$key" || return 1
  as_root mkdir -p /etc/apt/keyrings
  as_root install -m 644 "$key" /etc/apt/keyrings/gierens.asc
  echo "deb [signed-by=/etc/apt/keyrings/gierens.asc] https://deb.gierens.de stable main" |
    as_root tee /etc/apt/sources.list.d/gierens.list >/dev/null
  if ! as_root apt-get update -q; then
    as_root rm -f /etc/apt/sources.list.d/gierens.list /etc/apt/keyrings/gierens.asc
    as_root apt-get update -q || true
    return 1
  fi
}

install_packages() {
  base_pkgs="zsh git curl tar gzip"
  if [ "$OS" = Darwin ]; then
    has git || die "git is missing; install the Xcode Command Line Tools: xcode-select --install"
    has zsh || die "zsh is missing (it ships with macOS)."
    if ! has eza; then
      if has brew; then
        info "Installing eza with Homebrew"
        brew install eza || warn "brew install eza failed"
      else
        warn "Homebrew not found, skipping eza"
      fi
    fi
    install_atuin
    return 0
  fi

  if has apt-get; then
    info "Installing packages with apt"
    as_root apt-get update -q
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -q $base_pkgs ca-certificates
    if ! has eza; then
      if ! apt-cache policy eza 2>/dev/null | grep -q 'Candidate: [0-9]'; then
        add_eza_apt_repo || warn "Could not add the eza apt repository"
      fi
      as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -q eza || install_eza_binary
    fi
  elif has dnf || has yum; then
    pm=dnf; has dnf || pm=yum
    info "Installing packages with $pm"
    as_root $pm install -y $base_pkgs
    has eza || as_root $pm install -y eza || install_eza_binary
  elif has pacman; then
    info "Installing packages with pacman"
    # Arch doesn't support partial upgrades, so sync and upgrade together.
    as_root pacman -Syu --needed --noconfirm $base_pkgs eza
  elif has zypper; then
    info "Installing packages with zypper"
    as_root zypper --non-interactive install $base_pkgs
    has eza || as_root zypper --non-interactive install eza || install_eza_binary
  elif has apk; then
    info "Installing packages with apk"
    # shadow provides chsh/usermod, which busybox lacks
    as_root apk add --no-cache $base_pkgs shadow
    has eza || as_root apk add --no-cache eza || install_eza_binary
  else
    warn "No supported package manager found; make sure zsh, git and curl are installed"
  fi
  install_atuin
}

# --- Per-user setup (runs as the target user) ---
cat >"$TMP/user-setup.sh" <<'USER_SETUP'
set -eu
branch=$1 reset=$2 repo=$3 bin_dir=$4
info() { printf "  -> %s\n" "$*"; }
warn() { printf "  Warning: %s\n" "$*" >&2; }

zd="$HOME/.config/zsh"

if [ "$reset" = 1 ]; then
  info "Removing plugin caches"
  rm -rf "$zd/.antidote" "$zd/.zsh_plugins.zsh" "$HOME/.cache/antidote" \
    "$HOME/Library/Caches/antidote" "$HOME/.cache/zsh"
  rm -rf "$zd"/.zcompdump* "$HOME"/.cache/p10k-*
fi

# Clone, or update an existing clone of this repo.
origin=$(git -C "$zd" remote get-url origin 2>/dev/null || true)
if [ -d "$zd/.git" ] && { [ "$origin" = "$repo" ] || case "$origin" in *slazarov/zdotdir*) true ;; *) false ;; esac; }; then
  info "Updating $zd"
  if git -C "$zd" fetch --quiet origin "$branch"; then
    git -C "$zd" checkout --quiet "$branch" 2>/dev/null || git -C "$zd" checkout --quiet -b "$branch" FETCH_HEAD
    git -C "$zd" merge --quiet --ff-only FETCH_HEAD ||
      warn "$zd has local changes or has diverged; left as is"
  else
    warn "Could not fetch $branch; left $zd as is"
  fi
else
  if [ -e "$zd" ]; then
    backup="$zd.bak.$(date +%Y%m%d%H%M%S)"
    warn "$zd exists and is not this repo; moving it to $backup"
    mv "$zd" "$backup"
  fi
  info "Cloning $repo into $zd"
  mkdir -p "$HOME/.config"
  git clone --quiet --branch "$branch" --depth 1 "$repo" "$zd"
fi

# Source the repo's .zshenv from ~/.zshenv, keeping anything else already there.
# The file is rewritten in place, so a symlink (e.g. from a dotfiles manager)
# and its permissions are kept.
line='. "$HOME/.config/zsh/.zshenv"'
if [ -f "$HOME/.zshenv" ] && grep -q '\.config/zsh/\.zshenv' "$HOME/.zshenv"; then
  info "~/.zshenv already sources the zdotdir"
else
  info "Adding the zdotdir to ~/.zshenv"
  new=$(mktemp)
  {
    printf '%s\n' "$line"
    if [ -f "$HOME/.zshenv" ]; then cat "$HOME/.zshenv"; fi
  } >"$new"
  cat "$new" >"$HOME/.zshenv"
  rm -f "$new"
fi

# Import existing zsh history into atuin once.
atuin=$(command -v atuin 2>/dev/null || true)
[ -z "$atuin" ] && [ -x "$bin_dir/atuin" ] && atuin="$bin_dir/atuin"
[ -z "$atuin" ] && [ -x "$HOME/.local/bin/atuin" ] && atuin="$HOME/.local/bin/atuin"
if [ -n "$atuin" ] && [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/atuin/history.db" ]; then
  for hist in "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh_history" "$HOME/.zsh_history"; do
    if [ -s "$hist" ]; then
      info "Importing $hist into atuin"
      HISTFILE="$hist" "$atuin" import zsh >/dev/null 2>&1 || warn "atuin import failed"
      break
    fi
  done
fi

# Start zsh once so antidote and the plugins are downloaded now, not at first login.
if command -v zsh >/dev/null 2>&1; then
  info "Downloading zsh plugins"
  TERM=${TERM:-xterm-256color} zsh -i -c exit </dev/null >/dev/null 2>&1 ||
    warn "First zsh start reported errors; run 'zsh' to see them"
fi
USER_SETUP
chmod 644 "$TMP/user-setup.sh"

run_as() {
  user=$1; shift
  if [ "$user" = "$ME" ]; then
    sh "$@"
  elif has runuser; then
    runuser -u "$user" -- env -i HOME="$home" USER="$user" LOGNAME="$user" \
      PATH="$PATH" TERM="${TERM:-xterm-256color}" LANG="${LANG:-C.UTF-8}" sh "$@"
  elif has sudo; then
    sudo -u "$user" -H sh "$@"
  else
    # Every argument is checked for single quotes up front (see "Main"), so this quoting is safe.
    su -l -s /bin/sh "$user" -c "sh $(printf "'%s' " "$@")"
  fi
}

user_home() {
  if [ "$1" = "$ME" ]; then echo "$HOME"
  elif has getent; then getent passwd "$1" | cut -d: -f6
  else awk -F: -v u="$1" '$1 == u { print $6 }' /etc/passwd
  fi
}

user_shell() {
  if [ "$OS" = Darwin ]; then dscl . -read "/Users/$1" UserShell 2>/dev/null | awk '{print $2}'
  elif has getent; then getent passwd "$1" | cut -d: -f7
  else awk -F: -v u="$1" '$1 == u { print $7 }' /etc/passwd
  fi
}

set_login_shell() {
  user=$1
  # Prefer the conventional path over e.g. /usr/sbin/zsh on merged-/usr distros.
  zsh_path=$(command -v zsh)
  for p in /usr/bin/zsh /bin/zsh; do
    if [ -x "$p" ]; then zsh_path=$p; break; fi
  done
  case "$(user_shell "$user")" in */zsh) info "Login shell for $user is already zsh"; return 0 ;; esac
  grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null
  info "Setting login shell for $user to $zsh_path"
  if [ "$IS_ROOT" -eq 1 ] || { [ "$OS" = Linux ] && [ -n "$SUDO" ]; }; then
    if has usermod; then as_root usermod -s "$zsh_path" "$user"; else as_root chsh -s "$zsh_path" "$user"; fi
  else
    chsh -s "$zsh_path" || warn "chsh failed; run: chsh -s $zsh_path"
  fi
}

# --- Main ---
case "$REPO_URL$TMP$BIN_DIR" in *"'"*) die "Repository URL and paths must not contain single quotes." ;; esac
[ "$packages" -eq 1 ] && install_packages
has zsh || die "zsh is not installed"
has git || die "git is not installed"

old_ifs=$IFS
IFS=,
set -f
set -- $users
set +f
IFS=$old_ifs
for user in "$@"; do
  case "$user" in *[!A-Za-z0-9._-]*|"") warn "Invalid user name '$user', skipping"; continue ;; esac
  if ! id "$user" >/dev/null 2>&1; then
    warn "User '$user' does not exist, skipping"
    continue
  fi
  home=$(user_home "$user")
  [ -n "$home" ] && [ -d "$home" ] || { warn "No home directory for '$user', skipping"; continue; }

  info "Configuring zsh for $user"
  run_as "$user" "$TMP/user-setup.sh" "$branch" "$reset" "$REPO_URL" "$BIN_DIR"
  [ "$do_chsh" -eq 1 ] && set_login_shell "$user"
done

info "Done. Open a new terminal (or run 'exec zsh') to start using it."
