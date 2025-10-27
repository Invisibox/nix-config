# Shell integration for notifications on command completion

# Only source this inside Hyprland
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE-} && -v commands[hyprctl] ]] || return

autoload -Uz add-zsh-hook

: ${NOTIFY_THRESHOLD=5000} # 默认阈值改为5秒，只为耗时较长的命令通知

# Get active hyprland window address
__hyprland_active_window () {
  command hyprctl activewindow -j | jq -r .address
}

# Save current hyprland window address
HYPRLAND_WINDOW_ADDRESS=$(__hyprland_active_window)

# Return current time in milliseconds
unix_ms () {
  print -P '%D{%s%3.}'
}

# Save time at the moment before execution
__save_time_preexec () {
  typeset -gi __cmd_start_time=$(unix_ms)
}

# Calculate command duration
__save_time_precmd () {
  # If __cmd_start_time is not set, do nothing.
  [[ -v __cmd_start_time ]] || return
  local now=$(unix_ms)
  typeset -gi CMD_DURATION=$(( now - __cmd_start_time ))
  # Unset the start time to prepare for the next command
  unset __cmd_start_time
}

add-zsh-hook preexec __save_time_preexec

# Return human-readable (albeit minimal) duration calculated from milliseconds
duration_from_ms () {
  local h m s ms=$1
  h=$((  ms / 3600000 ))
  ms=$(( ms % 3600000 ))
  m=$((  ms / 60000 ))
  ms=$(( ms % 60000 ))
  s=$((  ms / 1000 ))
  ms=$(( ms % 1000 ))
  # Create an array of duration parts
  local -a durs
  ((h > 0)) && durs+=("${h}h")
  ((m > 0)) && durs+=("${m}m")
  ((s > 0)) && durs+=("${s}s")
  # Only show ms if total duration is less than a second
  ((s == 0 && m == 0 && h == 0)) && durs+=("${ms}ms")
  
  # Join the parts with a space, or print 0s if it's super fast
  print ${durs:-0s}
}

# Check if sending notification would be valid at this point
__should_notify () {
  # Get current active window. If hyprctl fails, assume we shouldn't notify.
  local activeHlWin
  activeHlWin=$(__hyprland_active_window) || return 1
  
  # Notify if:
  # 1. The active window is NOT the original terminal window.
  # 2. The command duration is equal to or greater than the threshold.
  [[ $activeHlWin != $HYPRLAND_WINDOW_ADDRESS ]] && (( CMD_DURATION >= NOTIFY_THRESHOLD ))
}

# Send the notification
__notify_on_command_completion () {
  local -i lastStatus=$?
  # First, calculate the duration of the command that just finished
  __save_time_precmd
  
  # If duration wasn't calculated (e.g., first prompt), stop.
  [[ -z $CMD_DURATION ]] && return

  # Get the last command from history
  local cmd
  cmd=$(fc -Lnl -1 -1) || return
  # Trim leading/trailing whitespace
  cmd=${${cmd#\s*}/%\s*/}
  
  if __should_notify; then
    local duration
    duration=$(duration_from_ms $CMD_DURATION)
    case $lastStatus in
      0) notify-send -- "✔ Finished in $duration"  "$cmd" ;;
      *) notify-send -- "✘ Failed after $duration" "$cmd" ;;
    esac
  fi
}

add-zsh-hook precmd __notify_on_command_completion
