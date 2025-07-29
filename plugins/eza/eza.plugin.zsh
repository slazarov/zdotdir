# Standardized $0 handling
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `docker`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_eza" ]]; then
  typeset -g -A _comps
  autoload -Uz _docker
  _comps[eza]=_eza
fi


command cp "${0:h}/completions/_eza" "$ZSH_CACHE_DIR/completions/_eza"