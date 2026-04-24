# prep: load smartcache plugin
source $ZSH_CONFIG_DIR/plugins/zsh-smartcache/zsh-smartcache.plugin.zsh

autoload -Uz add-zsh-hook

# ‣ [ prompt ]

source $ZSH_CONFIG_DIR/interactive/starship.zsh

# ‣ [ hooks and shell integration ]

# direnv hooks
source $ZSH_CONFIG_DIR/interactive/direnv.zsh

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

_init_atuin_widgets () {
  (( _atuin_lazy_loaded )) && return 0

  local plugin_file=$ZSH_CONFIG_DIR/plugins/atuin.zsh
  [[ -r $plugin_file ]] || return 1

  source $plugin_file
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
}
zle -N lazy-atuin-self-insert

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
  compdef _lf _lfcd
  compdef _directories mcd

  if (( ${+widgets[fzf-tab-complete]} )); then
    bindkey -M emacs -- "$_completion_tab_key" fzf-tab-complete
    bindkey -M viins -- "$_completion_tab_key" fzf-tab-complete
    bindkey -M main -- "$_completion_tab_key" fzf-tab-complete
  fi

  # fzf-tab widgets are created lazily; rebind fast-syntax-highlighting so
  # its wrapper also covers `fzf-tab-complete` and refreshes colors after tab.
  if (( ${+functions[_zsh_highlight_bind_widgets]} )); then
    _zsh_highlight_bind_widgets
  fi

  # fzf-tab is loaded lazily during the first tab press, after autosuggestions
  # has already wrapped widgets. Rebind autosuggestions wrappers now so the
  # newly registered fzf-tab widget joins the same wrapper chain.
  if (( ${+functions[_zsh_autosuggest_bind_widgets]} )); then
    _zsh_autosuggest_bind_widgets
  fi

  # Clear stale autosuggestion display from the pre-fzf-tab widget state.
  if (( ${+functions[_zsh_autosuggest_highlight_reset]} )); then
    _zsh_autosuggest_highlight_reset
    POSTDISPLAY=
  fi

}
init_completions_hooks+=(_completion_init_hook1)

# load aliases, those which need to use `compdef` will be manually added in a hook
. $ZSH_CONFIG_DIR/interactive/aliases.zsh

# plugins and their keybindings
() {

  local plugin_dir=$ZSH_CONFIG_DIR/plugins

  # autosuggestions
  source $plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(qc-sub-r qc-shell-r)
  ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)

  # disabled: overlaps with atuin search/history widgets.
  # source $plugin_dir/zsh-history-substring-search/zsh-history-substring-search.zsh

  # syntax highlighting (fast-syntax-highlighting)
  source $plugin_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

  # keep behavior closer to zsh-syntax-highlighting defaults:
  # - keep bracket highlighting
  # - disable command-specific chroma rules
  FAST_HIGHLIGHT[use_brackets]=1
  for _fsh_key in ${(k)FAST_HIGHLIGHT}; do
    [[ $_fsh_key == chroma-* ]] && unset "FAST_HIGHLIGHT[$_fsh_key]"
  done
  unset _fsh_key

  # no-ps2
  source $plugin_dir/zsh-no-ps2/zsh-no-ps2.plugin.zsh

}
