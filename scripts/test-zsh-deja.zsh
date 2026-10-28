#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
deja_bin=${1:-deja}

cat > "$test_root/atuin" <<'ZSH'
#!/usr/bin/env zsh
if [[ $1 == uuid ]]; then
  print -r -- 00000000000040008000000000000001
  exit
fi
[[ -n ${ATUIN_SESSION:-} && ${DEJA_TEST_EXPORT_FAILURE:-0} == 0 ]] || exit 1
printf '%s\0' 'echo import-check' 'echo import-check' $'printf "line one\nline two"' '  ignored'
ZSH
chmod +x "$test_root/atuin"

result=$(env -u ATUIN_SESSION HOME="$test_root/home" ZDOTDIR="$test_root" zsh -df "$repo_root/modules/shell/zsh/import-atuin-history.zsh" \
  "$test_root/atuin" "$deja_bin")
[[ $result == 'imported 3 commands into '* ]]
[[ -f $test_root/home/.local/share/deja/.atuin-imported ]]

result=$(env HOME="$test_root/home" "$deja_bin" query --buffer 'echo import')
[[ $result == 'echo import-check' ]]
result=$(env HOME="$test_root/home" "$deja_bin" query --buffer 'printf')
[[ $result == $'printf "line one\nline two"' ]]

if env -u ATUIN_SESSION HOME="$test_root/failed-home" ZDOTDIR="$test_root" DEJA_TEST_EXPORT_FAILURE=1 \
  zsh -df "$repo_root/modules/shell/zsh/import-atuin-history.zsh" "$test_root/atuin" "$deja_bin"; then
  print -ru2 -- 'A failed Atuin export must fail the import.'
  exit 1
fi
[[ ! -e $test_root/failed-home/.local/share/deja/.atuin-imported ]]

print -- 'Deja import checks passed (missing session, multiline, duplicates, failed export).'
