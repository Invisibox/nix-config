#! /usr/bin/env zsh

# list the token under cursor
#
# if current token isn't available or isn't a directory, list $PWD
#
# the command used for listing is $listTokenCommand if set and
# non-empty, otherwise `fd . -HLl -d 1 -c always --`

. $ZSH_CONFIG_DIR/widgets/_word-under-cursor.zsh

list-token () {
  local tok=$(word-under-cursor)
  local -a cmd=( "${(@Q)${(z)${listTokenCommand:-fd . -HLl -d 1 -c always --}}}" )
  print
  [[ -n $tok ]] && cmd+=( "${(Q)tok}" )
  "${cmd[@]}"

  local promptHeight=${#${(f)PROMPT}}
  for _ in {1..$promptHeight}; do print; done
  zle reset-prompt
}

zle -N list-token

