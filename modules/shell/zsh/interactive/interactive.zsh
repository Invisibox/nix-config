# prep: load smartcache plugin
source $ZSH_CONFIG_DIR/plugins/zsh-smartcache/zsh-smartcache.plugin.zsh

autoload -Uz add-zsh-hook

# ‣ [ prompt ]

source $ZSH_CONFIG_DIR/interactive/powerlevel10k.zsh

# ‣ [ hooks and shell integration ]

# direnv hooks
source $ZSH_CONFIG_DIR/interactive/direnv.zsh

# zoxide replaces cd and records directory changes
source $ZSH_CONFIG_DIR/plugins/zoxide.zsh

# OSC7: report PWD changes to the terminal emulator
source $ZSH_CONFIG_DIR/interactive/osc7.zsh

# OSC133: mark prompts
source $ZSH_CONFIG_DIR/interactive/osc133.zsh

# desktop notifications when commands finish
source $ZSH_CONFIG_DIR/interactive/notify.zsh

# ‣ [ completions, aliases and keybindings ]

# here we lazy-load completions by putting initialization into a function
# `init_completions` declared in `$ZSH_CONFIG_DIR/interactive/completion.zsh`.
# on the first execution it will run the initialization, run associated hooks,
# and then `unfunction` itself.

# set some options
fpath+=($XDG_DATA_HOME/zsh/completions)
_comp_options+=(globdots)

# the hooks to be executed when completion initialization is done
# this includes compdef calls, key rebinding, etc
typeset -ga init_completions_hooks=()

# first, make the keymap available to consumers
source $ZSH_CONFIG_DIR/keybindings/keymap_terminal.zsh

# lazily load atuin widgets on first key press
typeset -gi _atuin_lazy_loaded=0

_atuin_defer_failed_history_init () {
  # Keep failed commands searchable in this shell, then let store_failed=false
  # remove them when the shell exits.
  typeset -ga __atuin_deferred_failed_history_ids
  typeset -ga __atuin_deferred_failed_history_exits
  typeset -ga __atuin_deferred_failed_history_durations

  __atuin_defer_failed_history_end () {
    local exit_status=$1
    local duration=$2
    local history_id=$3
    local -a args

    args=(history end --exit "$exit_status")
    [[ -n $duration ]] && args+=(--duration="$duration")
    args+=(-- "$history_id")

    ATUIN_LOG=error atuin "${args[@]}"
  }

  _atuin_precmd () {
    local EXIT="$?" __atuin_precmd_time=${EPOCHREALTIME-}

    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return

    local history_id="$ATUIN_HISTORY_ID"
    export ATUIN_HISTORY_ID=""

    local duration=""
    if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
      printf -v duration %.0f $(((__atuin_precmd_time - __atuin_preexec_time) * 1000000000))
    fi

    if (( EXIT != 0 )); then
      __atuin_deferred_failed_history_ids+=("$history_id")
      __atuin_deferred_failed_history_exits+=("$EXIT")
      __atuin_deferred_failed_history_durations+=("$duration")
      return
    fi

    (__atuin_defer_failed_history_end "$EXIT" "$duration" "$history_id" &) >/dev/null 2>&1
  }

  __atuin_end_deferred_failed_history () {
    local i history_id exit_status duration

    for (( i = 1; i <= ${#__atuin_deferred_failed_history_ids[@]}; ++i )); do
      history_id=${__atuin_deferred_failed_history_ids[$i]}
      exit_status=${__atuin_deferred_failed_history_exits[$i]}
      duration=${__atuin_deferred_failed_history_durations[$i]}

      [[ -n $history_id ]] || continue
      __atuin_defer_failed_history_end "$exit_status" "$duration" "$history_id" >/dev/null 2>&1
    done

    __atuin_deferred_failed_history_ids=()
    __atuin_deferred_failed_history_exits=()
    __atuin_deferred_failed_history_durations=()
  }

  add-zsh-hook -d zshexit __atuin_end_deferred_failed_history 2>/dev/null || :
  add-zsh-hook zshexit __atuin_end_deferred_failed_history
}

_init_atuin_widgets () {
  (( _atuin_lazy_loaded )) && return 0

  local plugin_file=$ZSH_CONFIG_DIR/plugins/atuin.zsh
  [[ -r $plugin_file ]] || return 1

  # Keep the background index warm-up from taking the foreground terminal.
  setopt localoptions nomonitor
  source $plugin_file
  _atuin_defer_failed_history_init
  if (( ${+widgets[atuin-search]} && ${+widgets[atuin-up-search]} )); then
    _atuin_lazy_loaded=1
    return 0
  fi

  return 1
}

lazy-atuin-search () {
  if _init_atuin_widgets; then
    zle atuin-search
  else
    zle history-incremental-search-backward
  fi
}
zle -N lazy-atuin-search

lazy-atuin-up-search () {
  if _init_atuin_widgets; then
    zle atuin-up-search
  else
    zle up-line-or-history
  fi
}
zle -N lazy-atuin-up-search

lazy-atuin-self-insert () {
  (( _atuin_lazy_loaded )) || _init_atuin_widgets || :
  zle .self-insert
  if (( ! ${+functions[_deja_fetch]} )); then
    _init_deja && zle deja-fetch
  fi
}
zle -N lazy-atuin-self-insert

_init_deja () {
  (( ${+functions[_deja_fetch]} )) && return 0

  typeset -g DEJA_HIGHLIGHT_STYLE=fg=8
  # Keep Tab for fzf-tab and Shift+arrows for the existing word movements.
  typeset -g DEJA_CYCLE_KEY= DEJA_CYCLE_FUZZY_KEY= DEJA_CYCLE_FUZZY_BACK_KEY=
  if [[ -r $HOME/.local/share/deja/init.zsh ]]; then
    source "$HOME/.local/share/deja/init.zsh"
  else
    eval "$(deja init zsh)"
  fi
  DEJA_PARTIAL_ACCEPT_WIDGETS+=(qc-sub-r qc-shell-r)
  _deja_bind_widgets
  _DEJA_BOUND_WIDGET_COUNT=${#widgets}
}

lazy-deja-execute () {
  _init_deja && zle deja-execute
}
zle -N lazy-deja-execute

# define initial bindings and export `bind` function
# we rely on zsh-edit for sane zle widgets so there's a plugin involved too
source $ZSH_CONFIG_DIR/keybindings/keybindings.zsh

# source completions helpers
source $ZSH_CONFIG_DIR/interactive/completion.zsh
# delay completion initialization until first tab. use a dispatcher widget
# so the same keypress both initializes completion and runs completion.
typeset -g _completion_tab_key _completion_tab_orig_widget
if [[ -v terminal_key_sequences[tab] ]]; then
  _completion_tab_key=${terminal_key_sequences[tab]}
else
  _completion_tab_key='^I'
fi
_completion_tab_orig_widget="$(bindkey -M main -- "$_completion_tab_key" 2>/dev/null || :)"
_completion_tab_orig_widget="${_completion_tab_orig_widget##* }"
case $_completion_tab_orig_widget in
  ""|undefined-key|init_completions|lazy-tab-complete)
    _completion_tab_orig_widget=expand-or-complete
    ;;
esac

lazy-tab-complete () {
  # run one-time completion initialization on first invocation.
  if (( ${+functions[init_completions]} )); then
    zle init_completions
  fi

  # dispatch this same keypress to the real completion widget.
  if (( ${+widgets[fzf-tab-complete]} )); then
    zle fzf-tab-complete
  else
    zle "$_completion_tab_orig_widget"
  fi
}
zle -N lazy-tab-complete

bindkey -M emacs -- "$_completion_tab_key" lazy-tab-complete
bindkey -M viins -- "$_completion_tab_key" lazy-tab-complete
bindkey -M main -- "$_completion_tab_key" lazy-tab-complete

# the hook to run upon completion initialization
_completion_init_hook1 () {
  # restore original tab widget before loading fzf-tab; otherwise fzf-tab
  # would capture init_completions as its fallback widget.
  bindkey -M emacs -- "$_completion_tab_key" "$_completion_tab_orig_widget"
  bindkey -M viins -- "$_completion_tab_key" "$_completion_tab_orig_widget"
  bindkey -M main -- "$_completion_tab_key" "$_completion_tab_orig_widget"

  source $ZSH_CONFIG_DIR/plugins/fzf-tab/fzf-tab.plugin.zsh
  zstyle ':completion:*' menu no
  compdef _files rm
  compdef _directories mcd
  compdef __zoxide_z_complete cd

  if (( ${+widgets[fzf-tab-complete]} )); then
    bindkey -M emacs -- "$_completion_tab_key" fzf-tab-complete
    bindkey -M viins -- "$_completion_tab_key" fzf-tab-complete
    bindkey -M main -- "$_completion_tab_key" fzf-tab-complete
  fi

  # Include the new completion widgets without waiting for another prompt.
  if (( ${+functions[_deja_bind_widgets]} )); then
    _deja_clear
    _deja_bind_widgets
    _DEJA_BOUND_WIDGET_COUNT=${#widgets}
  fi

}
init_completions_hooks+=(_completion_init_hook1)

# load aliases, those which need to use `compdef` will be manually added in a hook
. $ZSH_CONFIG_DIR/interactive/aliases.zsh

# plugins and their keybindings
() {

  local plugin_dir=$ZSH_CONFIG_DIR/plugins

  # disabled: overlaps with atuin search/history widgets.
  # source $plugin_dir/zsh-history-substring-search/zsh-history-substring-search.zsh

  # no-ps2
  source $plugin_dir/zsh-no-ps2/zsh-no-ps2.plugin.zsh

  _patina_activate () {
    # ZLE hook setup expects ERR_RETURN to be off; smartcache enables it.
    print -r -- 'unsetopt errreturn'
    XDG_RUNTIME_DIR="$2" TMPDIR="$3" "$1" activate
  }
  # Key the compiled cache by executable version and daemon runtime directory.
  smartcache eval _patina_activate \
    "${commands[zsh-patina]:A}" "${XDG_RUNTIME_DIR-}" "${TMPDIR:-/tmp}"
  unfunction _patina_activate

}
