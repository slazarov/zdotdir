# Support Compose v2 as docker CLI plugin
#
# This tests that the (old) docker-compose command is in $PATH and that
# it resolves to an existing executable file if it's a symlink.


alias dco="$dccmd"
alias dcb="$dccmd build"
alias dce="$dccmd exec"
alias dcps="$dccmd ps"
alias dcrestart="$dccmd restart"
alias dcrm="$dccmd rm"
alias dcr="$dccmd run"
alias dcstop="$dccmd stop"
alias dcup="$dccmd up"
alias dcupb="$dccmd up --build"
alias dcupd="$dccmd up -d"
alias dcupdb="$dccmd up -d --build"
alias dcdn="$dccmd down"
alias dcl="$dccmd logs"
alias dclf="$dccmd logs -f"
alias dclF="$dccmd logs -f --tail 0"
alias dcpull="$dccmd pull"
alias dcstart="$dccmd start"
alias dck="$dccmd kill"

# Check if docker-compose or docker compose command is available
if (( ! $+commands[docker-compose] && ! $+commands[docker] )); then
  return
fi

# Standardized $0 handling
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `docker-compose`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_docker-compose" ]]; then
  typeset -g -A _comps
  autoload -Uz _docker-compose
  _comps[docker-compose]=_docker-compose
fi

{
  # Check if we're using docker-compose (v1) or docker compose (v2)
  if [[ -n $commands[docker-compose] ]]; then
    # For docker-compose v1, use the bundled completion file
    command cp "${0:h}/completions/_docker-compose" "$ZSH_CACHE_DIR/completions/_docker-compose"
  elif [[ -n $commands[docker] ]]; then
    # For docker compose (v2), check Docker version and use completion if supported
    if zstyle -t ':omz:plugins:docker-compose' legacy-completion || \
       ! is-at-least 23.0.0 ${${(s:,:z)"$(command docker --version)"}[3]}; then
         command cp "${0:h}/completions/_docker-compose" "$ZSH_CACHE_DIR/completions/_docker-compose"
       else
         # Generate completion for `docker compose` if supported
         command docker completion zsh | tee "$ZSH_CACHE_DIR/completions/_docker-compose" > /dev/null
    fi
  fi
} &|