#!/usr/bin/env zsh
set -eu

repo_root=${0:A:h:h}
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

# Exercise the formatter without loading the interactive theme or starting its worker.
ZSH_CONFIG_DIR=$test_root
mkdir -p "$ZSH_CONFIG_DIR/plugins/powerlevel10k"
: > "$ZSH_CONFIG_DIR/plugins/powerlevel10k/powerlevel10k.zsh-theme"
source "$repo_root/modules/shell/zsh/interactive/powerlevel10k.zsh"

reset-git-status () {
  unset -m 'VCS_STATUS_*' || :
  P9K_CONTENT=
  VCS_STATUS_LOCAL_BRANCH=main
  VCS_STATUS_COMMIT=123456789abcdef
  VCS_STATUS_ACTION=
}

assert-git-prompt () {
  _p10k_git_formatter
  local actual=$(print -Pr -- "$_p10k_git_format" | sed $'s/\e\\[[0-9;]*m//g')
  [[ $actual == "$1" ]] || {
    print -ru2 -- "expected ${(qqq)1}, got ${(qqq)actual}"
    exit 1
  }
}

reset-git-status
assert-git-prompt 'on  main'
VCS_STATUS_NUM_UNSTAGED=3
VCS_STATUS_COMMITS_AHEAD=2
assert-git-prompt 'on  main [!⇡]'
VCS_STATUS_NUM_STAGED=2
VCS_STATUS_NUM_UNTRACKED=4
VCS_STATUS_STASHES=1
VCS_STATUS_COMMITS_BEHIND=1
assert-git-prompt 'on  main [$!+?⇕]'

reset-git-status
VCS_STATUS_NUM_STAGED=1
VCS_STATUS_NUM_STAGED_DELETED=1
assert-git-prompt 'on  main [✘]'
reset-git-status
VCS_STATUS_NUM_CONFLICTED=1
VCS_STATUS_ACTION=merge
assert-git-prompt 'on  main (MERGE) [=]'
reset-git-status
VCS_STATUS_LOCAL_BRANCH=
assert-git-prompt '(1234567)'
VCS_STATUS_COMMIT=
assert-git-prompt ''
reset-git-status
VCS_STATUS_LOCAL_BRANCH='feature/50%done'
assert-git-prompt 'on  feature/50%done'
P9K_CONTENT=loading
assert-git-prompt loading

print -- 'Zsh prompt regression checks passed.'
