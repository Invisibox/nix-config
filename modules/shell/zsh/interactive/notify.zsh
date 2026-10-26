autoload -Uz add-zsh-hook

# minimum command duration (seconds) before sending notifications.
# set to 0 to notify for every command.
typeset -gi ZSH_NOTIFY_MIN_SECONDS=${ZSH_NOTIFY_MIN_SECONDS:-5}

typeset -g _notify_last_command=""
typeset -gi _notify_command_running=0
typeset -gi _notify_command_started=0

_notify_command_preexec () {
  _notify_last_command=$1
  _notify_command_started=$SECONDS
  _notify_command_running=1
}

_notify_command_precmd () {
  local command_status=$?
  local elapsed

  (( _notify_command_running )) || return $command_status
  _notify_command_running=0

  (( ${+commands[notify-send]} )) || return $command_status

  elapsed=$(( SECONDS - _notify_command_started ))
  (( elapsed >= ZSH_NOTIFY_MIN_SECONDS )) || return $command_status

  local command_text=${_notify_last_command//$'\n'/ }
  command_text=${command_text//$'\t'/ }
  command_text=${command_text[1,180]}
  [[ -n $command_text ]] || command_text="(shell command)"

  local summary urgency
  if (( command_status == 0 )); then
    summary="Command finished"
    urgency="low"
  else
    summary="Command failed (exit ${command_status})"
    urgency="normal"
  fi

  notify-send \
    --app-name="zsh" \
    --icon="utilities-terminal" \
    --urgency="$urgency" \
    --expire-time=5000 \
    "$summary" \
    "${command_text} [${elapsed}s]" \
    >/dev/null 2>&1 || :

  _notify_last_command=""
  return $command_status
}

add-zsh-hook preexec _notify_command_preexec
add-zsh-hook precmd _notify_command_precmd
