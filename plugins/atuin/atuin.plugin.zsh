# Atuin: SQLite-backed shell history with a full-screen Ctrl+R search.
# https://github.com/atuinsh/atuin
#
# Up arrow is left to zsh-history-substring-search and `?` (Atuin AI) is disabled.
# The init script is cached and regenerated whenever the atuin binary changes.

if (( ! $+commands[atuin] )); then
  return
fi

() {
  local cache="$ZSH_CACHE_DIR/atuin-init.zsh"
  if [[ ! -s "$cache" || "${commands[atuin]:A}" -nt "$cache" ]]; then
    local -a flags=(--disable-up-arrow)
    # --disable-ai only exists in atuin 18.13+; distro packages are often older.
    [[ "$(command atuin init --help 2>/dev/null)" == *--disable-ai* ]] && flags+=(--disable-ai)
    # Write to a temp file so a failed init never leaves an empty or broken cache.
    if command atuin init zsh $flags >| "$cache.tmp" 2>/dev/null && [[ -s "$cache.tmp" ]]; then
      command mv -f "$cache.tmp" "$cache"
    else
      command rm -f "$cache.tmp"
      return
    fi
  fi
  source "$cache"
}
