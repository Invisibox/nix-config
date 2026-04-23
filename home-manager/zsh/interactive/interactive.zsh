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
source $ZSH_CONFIG_DIR/keybindings/keymap_foot.zsh

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
# delay completion system initialization until first hit on tab/s-tab.
# keep original tab widget so fzf-tab wraps a real completion widget
# (init_completions unfunctions itself after the first run).
typeset -g _completion_tab_key _completion_tab_orig_widget
if [[ -v keys[tab] ]]; then
  _completion_tab_key=$keys[tab]
else
  _completion_tab_key='^I'
fi
_completion_tab_orig_widget="$(bindkey -M main -- "$_completion_tab_key" 2>/dev/null || :)"
_completion_tab_orig_widget="${_completion_tab_orig_widget##* }"
case $_completion_tab_orig_widget in
  ""|undefined-key|init_completions)
    _completion_tab_orig_widget=expand-or-complete
    ;;
esac

bindkey -M emacs -- "$_completion_tab_key" init_completions
bindkey -M viins -- "$_completion_tab_key" init_completions
bindkey -M main -- "$_completion_tab_key" init_completions

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

  # replay the triggering tab key so the first tab press performs completion
  # after initialization/binding has finished.
  if [[ -n ${ZLE-} ]]; then
    zle -U "$_completion_tab_key"
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
