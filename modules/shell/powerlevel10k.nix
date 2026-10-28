{
  flake.modules.homeManager.shell = {
    config,
    pkgs,
    ...
  }: let
    powerlevel10k = pkgs.zsh-powerlevel10k.overrideAttrs (old: {
      # The read-only Nix store prevents the theme from compiling itself at startup.
      postInstall =
        (old.postInstall or "")
        + ''
          ${config.programs.zsh.package}/bin/zsh -dfec '
            for f in "$out"/share/zsh-powerlevel10k/{*.zsh-theme,internal/*.zsh,gitstatus/gitstatus.plugin.zsh,gitstatus/install}; do
              zcompile -R -- "$f"
            done
          '
        '';
    });
  in {
    xdg.configFile."zsh/plugins/powerlevel10k".source = "${powerlevel10k}/share/zsh-powerlevel10k";
  };
}
