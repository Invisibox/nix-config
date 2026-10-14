#! /usr/bin/env zsh

# complete a filename with fzf — an alternative to ZSH native
# file completion which always shows depth of 1

# expand a path starting with either `./`, `../` or `~/` into an
# absolute path. if it's a relative path, expansion happens relative
# to the value of `$PWD`.
expand-path () {
  p=$1
  p=${p/#\.\.\//${PWD:h}/} # expand leading ../
  p=${p/#\.\//$PWD/}       # expand leading ./
  p=${p/#\~\//$HOME/}      # expand leading ~/
  print -- $p
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
    --read0 --print0 --scheme=path --tiebreak=length --height=50%
    )
  local -ar fdArgs=(
    -c always -HL0
    )
  # split left part of the buffer on whitespace
  local -a LBuffWords=(${(s/ /)LBUFFER})
  # get the last word and last char
  local lastLBuffWord=${LBuffWords[-1]:-}
  local cursorChar=${LBUFFER[-1]}

  # if there is a last word and the cursor is on the last word (not separated with spaces)
  if [[ -n "${lastLBuffWord:-}" && ${lastLBuffWord[-1]} = $cursorChar ]]; then
    # expand leading tilde and dots
    lastLBuffWord=$(expand-path $lastLBuffWord)
    local -r dir=${lastLBuffWord:h}
    local -r pat=${lastLBuffWord:t}

    read-fzf-selections < <(
      # could be replaced with `print -N -- $dir/$pat* $dir/$pat*/**`
      # for much better performance, but no colors
      { fd $fdArgs -gp "$dir/$pat*"    $dir &
        fd $fdArgs -gp "$dir/$pat*/**" $dir
      } | { fzf $fzfArgs --query="$pat "; exit }
    )
    local -a fs=("${(@)reply}")

    # if none were picked we'll get 0-length array and abort
    (( ${#fs} )) || { zle reset-prompt; return }
    # replace the last word with picked words
    LBuffWords[-1]=( "${(@q)fs}" )
    # reassemble (join on whitespace) the words and update LBUFFER
    LBUFFER=${(j/ /)LBuffWords}

  # no word under cursor, just print out CWD contents
  else
    read-fzf-selections < <(fd . $fdArgs -- $cdpath | fzf $fzfArgs)
    local -a fs=("${(@)reply}")
    LBUFFER+=${(j/ /)${(@q)fs}}
  fi

  zle reset-prompt
}

zle -N fzf-complete-file

