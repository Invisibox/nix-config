#!/usr/bin/env zsh
set -eu

repo_root=${0:A:h:h}
test_root=$(mktemp -d)
trap 'cd /; rm -rf -- "$test_root"' EXIT
ZSH_CONFIG_DIR=$repo_root/modules/shell/zsh

assert-equal () {
  [[ $1 == "$2" ]] || {
    print -ru2 -- "$3: expected ${(qqq)2}, got ${(qqq)1}"
    exit 1
  }
}

# Run the actual widgets without an interactive terminal, using fzf's filter mode.
zle () { :; }
fzf () { command fzf "$@" --filter="${fzf_filter:-}"; }
source "$ZSH_CONFIG_DIR/widgets/list-token.zsh"
source "$ZSH_CONFIG_DIR/widgets/fzf-complete-file.zsh"
source "$ZSH_CONFIG_DIR/widgets/ascend-descend.zsh"
source "$ZSH_CONFIG_DIR/widgets/fzf-shell-history.zsh"

cd "$test_root"
mkdir -p 'modules/apps' 'dir name' 'child directory'
touch flake.nix modules/apps/kitty.nix 'dir name/file name' 'child directory/child'
touch 'line\name'

record-token () { received=("$@"); }
listTokenCommand='record-token "fixed argument"'
PROMPT=''
BUFFER='ls $(touch injected)'
LBUFFER=$BUFFER
list-token >/dev/null
[[ ! -e injected ]]
assert-equal "$received[1]" 'fixed argument' 'configured command arguments'
assert-equal "$received[2]" '$(touch injected)' 'token stays literal'
BUFFER='ls "dir name"'
LBUFFER=$BUFFER
list-token >/dev/null
assert-equal "$received[2]" 'dir name' 'quoted listing token'

complete-case () {
  LBUFFER=$1
  RBUFFER=' untouched'
  fzf_filter=$2
  fzf-complete-file
  assert-equal "$LBUFFER" "$3" "completion of $1"
  assert-equal "$RBUFFER" ' untouched' 'text after cursor'
  [[ $LBUFFER != *$'\e'* ]] || exit 1
}

selected=$test_root/flake.nix
complete-case 'cat flak*' flake.nix "cat ${(q)selected}"
complete-case 'printf "a  b" flak' flake.nix "printf \"a  b\" ${(q)selected}"
selected=$test_root/modules/apps/kitty.nix
complete-case 'cat modules/apps/ki*' kitty.nix "cat ${(q)selected}"
selected="$test_root/dir name/file name"
complete-case 'cat "dir name/fi"' 'file name' "cat ${(q)selected}"
complete-case 'cat dir\ name/fi' 'file name' "cat ${(q)selected}"
selected="$test_root/line\name"
complete-case 'cat line*' 'name' "cat ${(q)selected}"
complete-case 'cat flak' no-such-result 'cat flak'
complete-case 'printf "a  b"  ' flake.nix 'printf "a  b"  ./flake.nix'

fzf_filter='child directory'
descend
assert-equal "$PWD" "$test_root/child directory" 'directory widget'
cd "$test_root"
fc () { print -r -- 'echo history works'; }
fzf_filter='history works'
fzf-shell-history
assert-equal "$LBUFFER" 'echo history works' 'history widget'

commands[direnv]=$test_root/direnv
direnv () { print -r -- 'export WIDGET_TEST_DIRENV="loaded value"'; }
source "$ZSH_CONFIG_DIR/interactive/direnv.zsh"
_direnv_hook
assert-equal "$WIDGET_TEST_DIRENV" 'loaded value' 'direnv hook'

print -- 'Zsh widget regression checks passed.'
