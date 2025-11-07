alias reload="exec zsh"
alias c='clear' # clear terminal

# nix aliases

alias nix-gc="command sudo nix-collect-garbage -d"
alias nix-delete="command sudo nix store delete"
ns () nix shell 'nixpkgs#'${^@} --impure

# files
alias ls='eza --icons --color=auto --group-directories-first' # list files with icons, color, and directories first
alias l='ls -lhg --sort=type' # list files with human-readable sizes, sorted by type
alias la='l -a' # list all files
alias lsd='ls -ld *(-/DN)' # list directories only
alias lsa='ls -aF' # list all files with indicators
alias lt='eza --icons=auto --tree' # list folder as tree

alias tree='ls --tree'
alias tre='tree -L 2'
alias treea='tree -a' # list all files in tree format
alias treed='tree -d' # list directories only in tree format
# alias treel='tree -a --git-ignore --ignore-glob=".git|.DS_Store|.cache|node_modules|target"' # list all files in tree format, ignoring certain directories
alias treel='tree -a --git-ignore --ignore-glob=".git|.DS_Store|.cache|node_modules|target"'

alias md="mkdir -p"
mcd () { mkdir -p -- $1 && cd $1 }

# rm () {
#   # 依然保留对 rm -rf 的危险操作警告
#   if [[ "$1" = "-rf" || "$1" = "-r" || "$1" = "-f" ]]; then
#     print -u2 -- "错误: 此命令不支持 -r 或 -f 参数。请改用 'purge' 进行永久删除。"
#     return 1
#   fi
#   # 如果没有提供任何文件，则显示 rm 的帮助信息
#   if [[ $# -eq 0 ]]; then
#       command rm --help
#       return
#   fi
#   # 使用 kioclient 将所有参数指定的文件移动到回收站
#   # "$@" 可以正确处理带空格的文件名
#   kioclient move -- "$@" trash:/
# }
# # 用于永久删除的命令
# alias purge="command rm -rf"

alias mx="chmod +x"

# downloads
alias curl="curl -L"
alias dl="curl -LO"

# misc
alias ka="killall"

alias ff="fastfetch"