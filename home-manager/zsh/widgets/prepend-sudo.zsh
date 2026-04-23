#! /usr/bin/env zsh

# fish-inspired widget for toggling sudo at command start

prepend-sudo () {
  emulate -L zsh

  local old_buffer="$BUFFER"
  local old_cursor=$CURSOR
  local leading rest
  local anchor remove_len
  local after_sudo spaces

  leading="${old_buffer%%[^[:space:]]*}"
  rest="${old_buffer#$leading}"
  anchor=${#leading}

  if [[ $rest == sudo || $rest == sudo[[:space:]]* ]]; then
    after_sudo="${rest#sudo}"
    spaces="${after_sudo%%[^[:space:]]*}"
    rest="${after_sudo#$spaces}"
    remove_len=$((4 + ${#spaces}))
    BUFFER="${leading}${rest}"

    if (( old_cursor > anchor )); then
      if (( old_cursor <= anchor + remove_len )); then
        CURSOR=$anchor
      else
        CURSOR=$((old_cursor - remove_len))
      fi
    fi
  else
    BUFFER="${leading}sudo ${rest}"
    if (( old_cursor >= anchor )); then
      CURSOR=$((old_cursor + 5))
    fi
  fi
}

zle -N prepend-sudo
