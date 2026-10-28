#!/usr/bin/env zsh
set -euo pipefail
umask 077

history_file=$(mktemp)
trap 'rm -f -- "$history_file"' EXIT
zmodload zsh/datetime
history_continuation=$'\\\n'

# Home Manager activation runs before Atuin's interactive session setup.
export ATUIN_SESSION=${ATUIN_SESSION:-$("$1" uuid)}

# Extended history escaping keeps multiline commands in a single entry.
"$1" history list --cmd-only --print0 | while IFS= read -r -d $'\0' entry; do
  print -r -- ": $EPOCHSECONDS:0;${entry//$'\n'/$history_continuation}"
done > "$history_file" || exit $?
"$2" import --file "$history_file"
touch "$HOME/.local/share/deja/.atuin-imported"
