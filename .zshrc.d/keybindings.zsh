# zsh-history-substring-search: up/down search history for the typed substring.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
[[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" history-substring-search-up
[[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" history-substring-search-down
