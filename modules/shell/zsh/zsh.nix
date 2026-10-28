{
  flake.modules.homeManager.shell = {
    lib,
    pkgs,
    config,
    ...
  }: let
    # zcompile files based on a glob expression.
    # relative globs are resolved under ~/.config/zsh, while absolute
    # or shell-variable-prefixed globs (e.g. $out/**) are used as-is.
    zcompileGlob = glob: let
      globExpr =
        if lib.hasPrefix "/" glob || lib.hasPrefix "~/" glob || lib.hasPrefix "$" glob
        then glob
        else "~/.config/zsh/${glob}";
    in
      # sh
      ''
        ${config.programs.zsh.package}/bin/zsh -dfec '
          setopt extendedglob globstarshort dotglob nullglob
          for f in ${globExpr}; do
            [[ -f $f ]] || continue
            zcompile -U -- "$f"
          done
        '
      '';

    # make a derivation out of a plugin's name and source.
    # will zcompile it automatically. optionally, the unpack
    # phase can be overwritten.
    mkZshPlugin = name: attrs:
      pkgs.callPackage (
        {stdenvNoCC}:
          stdenvNoCC.mkDerivation (
            attrs
            // {
              inherit name;
              phases = ["unpackPhase"];
              unpackPhase =
                (
                  attrs.unpackPhase or # sh
              ''
                    mkdir -p -- $out/
                    cp -r "$src"/. "$out"/
                  ''
                )
                + ''
                  chmod -R u+w "$out"
                  ${zcompileGlob "$out/**/*.zsh"}
                '';
            }
          )
      ) {};

    # disabled: overlaps with atuin search/history widgets.
    # zsh-history-substring-search = let
    #   name = "zsh-history-substring-search";
    # in
    #   mkZshPlugin name {
    #     src = pkgs.fetchFromGitHub {
    #       owner = "zsh-users";
    #       repo = name;
    #       rev = "14c8d2e0ffaee98f2df9850b19944f32546fdea5";
    #       hash = "sha256-KHujL1/TM5R3m4uQh2nGVC98D6MOyCgQpyFf+8gjKR0=";
    #     };
    #   };

    fzf-tab = let
      name = "fzf-tab";
    in
      mkZshPlugin name {
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = name;
          rev = "24105b15714bfec37989ed5c5b6e60f572253019";
          hash = "sha256-YhTSu0P7mFlVx1zBvbT0jNstkamcZHhPYJHKMAHgyuM=";
        };
      };

    zsh-smartcache = let
      name = "zsh-smartcache";
    in
      mkZshPlugin name {
        src = pkgs.fetchFromGitHub {
          owner = "QuarticCat";
          repo = "zsh-smartcache";
          rev = "54aba13a6824e212992fd754c598c9e9acd259a3";
          hash = "sha256-VFrMpSm66b8Uyyr2QDN6gvFVB9caN9TC1rNC8dMoWCo=";
        };
      };

    zsh-no-ps2 = let
      name = "zsh-no-ps2";
    in
      mkZshPlugin name {
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "zsh-no-ps2";
          rev = "4b23567dc503170672386660706e55ce0201770c";
          hash = "sha256-blu8KEdF4IYEI3VgIkSYsd0RZsAHErj9KnC67MN5Jsw=";
        };
      };

    atuin-integration = pkgs.runCommandLocal "zsh atuin init" {} ''
      sd=${pkgs.sd}/bin/sd

      mkdir -p "$out"
      HOME="$TMPDIR" XDG_CONFIG_HOME="$TMPDIR/config" XDG_DATA_HOME="$TMPDIR/data" \
        ${config.programs.atuin.package}/bin/atuin init zsh \
          | $sd '^bindkey.+?\n' "" > "$out/atuin.zsh"

      ${config.programs.zsh.package}/bin/zsh -dfc 'zcompile -U -- "$1"' _ "$out/atuin.zsh"
    '';

    # Cache initialization in the store so shell startup only loads bytecode.
    zoxide-integration = pkgs.runCommandLocal "zsh zoxide init" {} ''
      mkdir -p "$out"
      ${lib.getExe pkgs.zoxide} init zsh --cmd cd > "$out/zoxide.zsh"
      ${config.programs.zsh.package}/bin/zsh -dfec 'zcompile -U -- "$1"' _ "$out/zoxide.zsh"
    '';
  in {
    home.packages = [pkgs.deja pkgs.zoxide pkgs.zsh-patina];

    home.activation.prepareDeja = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${lib.getExe pkgs.deja} init zsh > /dev/null
      run ${config.programs.zsh.package}/bin/zsh -dfc \
        'zcompile -U -- "$HOME/.local/share/deja/init.zsh"'
      if [[ ! -e "$HOME/.local/share/deja/.atuin-imported" ]]; then
        run ${config.programs.zsh.package}/bin/zsh -df \
          ${./import-atuin-history.zsh} \
          ${lib.getExe config.programs.atuin.package} ${lib.getExe pkgs.deja}
      fi
    '';

    xdg.configFile = {
      # entrypoint
      # zdotdir is set by the nixos module and points to $XDG_CONFIG_HOME/zsh

      "zsh/.zshenv".source = ./zshenv;

      # Bound highlighting work for large pasted commands.
      "zsh-patina/config.toml".text = ''
        [highlighting]
        max_line_length = 10000
        timeout_ms = 20
      '';

      # plugins

      # disabled: overlaps with atuin search/history widgets.
      # "zsh/plugins/zsh-history-substring-search".source = zsh-history-substring-search;
      "zsh/plugins/fzf-tab".source = fzf-tab;
      "zsh/plugins/atuin.zsh".source = "${atuin-integration}/atuin.zsh";
      "zsh/plugins/atuin.zsh.zwc".source = "${atuin-integration}/atuin.zsh.zwc";
      "zsh/plugins/zoxide.zsh".source = "${zoxide-integration}/zoxide.zsh";
      "zsh/plugins/zoxide.zsh.zwc".source = "${zoxide-integration}/zoxide.zsh.zwc";
      "zsh/plugins/zsh-smartcache".source = zsh-smartcache;
      "zsh/plugins/zsh-no-ps2".source = zsh-no-ps2;

      # run control

      "zsh/environment" = {
        source = ./environment;
        recursive = true;
        onChange = zcompileGlob "environment/**.zsh";
      };

      "zsh/interactive" = {
        source = ./interactive;
        recursive = true;
        onChange = zcompileGlob "interactive/**.zsh";
      };

      "zsh/keybindings/keybindings.zsh" = {
        source = ./keybindings/keybindings.zsh;
        onChange = zcompileGlob "keybindings/keybindings.zsh";
      };

      "zsh/keybindings/keymap_terminal.zsh" = {
        text = import ./keybindings/_keymap_terminal.nix {
          terminalKeySequencesAttrSet = import ./keybindings/_keys.nix {inherit lib;};
          inherit lib;
        };
        onChange = zcompileGlob "keybindings/keymap_terminal.zsh";
      };

      "zsh/widgets" = {
        source = ./widgets;
        recursive = true;
        onChange = zcompileGlob "widgets/**.zsh";
      };
    };
  };
}
