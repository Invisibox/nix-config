#! /usr/bin/env zsh

# complete a filename with fzf — an alternative to ZSH native
# file completion which always shows depth of 1

# expand leading `~/`; the search directory is made absolute below
expand-path () {
  local p=$1
  p=${p/#\~\//$HOME/}      # expand leading ~/
  print -r -- $p
}

# read NUL-separated fzf output into $reply (command substitution drops NULs)
read-fzf-selections () {
  reply=()
  local item
  while IFS= read -r -d '' item; do
    reply+=("$item")
  done
}

# insert files picked in FZF into command line
fzf-complete-file () {
  local -ar fzfArgs=(
    --ansi --read0 --print0 --scheme=path --tiebreak=length --height=50%
    )
  local -ar fdArgs=(
    -c always -HL0
    )
  local -a words=( ${(z)LBUFFER} )
  local token=${words[-1]:-}

  # Only replace the final token; earlier spacing and quotes belong to the user.
  if [[ -n $token && $LBUFFER == *"$token" ]]; then
    local prefix=${LBUFFER%"$token"}
    local lastLBuffWord=$(expand-path "${(Q)token}")
    local -r dir=${lastLBuffWord:h:a}
    local -r pat=${lastLBuffWord:t}

    read-fzf-selections < <(
      # could be replaced with `print -N -- $dir/$pat* $dir/$pat*/**`
      # for much better performance, but no colors
      { fd $fdArgs -gp "$dir/$pat*"    $dir &
        fd $fdArgs -gp "$dir/$pat*/**" $dir
      } | fzf $fzfArgs
    )
    local -a fs=("${(@)reply}")

    # if none were picked we'll get 0-length array and abort
    (( ${#fs} )) || { zle reset-prompt; return }
    LBUFFER=$prefix${(j/ /)${(@q)fs}}

  # no word under cursor, just print out CWD contents
  else
    read-fzf-selections < <(fd . $fdArgs -- $cdpath | fzf $fzfArgs)
    local -a fs=("${(@)reply}")
    LBUFFER+=${(j/ /)${(@q)fs}}
  fi

  zle reset-prompt
}

zle -N fzf-complete-file

