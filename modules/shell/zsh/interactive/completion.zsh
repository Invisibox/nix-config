reload_completions () {
  compinit -d $ZSH_CACHE_DIR/zcompdump
  zcompile -- $ZSH_CACHE_DIR/zcompdump
}

init_completions () {

  autoload -Uz compinit
  compinit -C -d $ZSH_CACHE_DIR/zcompdump
  if [[ -f $ZSH_CACHE_DIR/zcompdump && ! $ZSH_CACHE_DIR/zcompdump.zwc -nt $ZSH_CACHE_DIR/zcompdump ]]; then
    zcompile -U -- $ZSH_CACHE_DIR/zcompdump
  fi

  unfunction init_completions

  if [[ -v init_completions_hooks ]]; then
    for f in $init_completions_hooks; do
      $f
      unfunction -- $f 2>/dev/null || :
    done

    unset init_completions_hooks

  fi

}

zle -N init_completions

