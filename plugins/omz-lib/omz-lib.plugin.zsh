# Oh My Zsh library functions that the vendored OMZ plugins rely on
# (git_current_branch, clipcopy, ...), since OMZ itself isn't loaded here.
# git.zsh and clipboard.zsh are auto-updated from ohmyzsh/lib by the weekly workflow.
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

source "${0:h}/git.zsh"
source "${0:h}/clipboard.zsh"
