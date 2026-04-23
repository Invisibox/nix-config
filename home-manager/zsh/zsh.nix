{
  lib,
  pkgs,
  config,
  ...
}: let
  # zcompile files based on a glob expression
  zcompileGlob = globs:
  # sh
  ''
    ${config.programs.zsh.package}/bin/zsh -dfc '
      setopt extendedglob globstarshort dotglob nullglob
      for f in ~/.config/zsh/${globs}; do
        [[ -f $f ]] || continue
        zcompile -U -- "$f" 2>/dev/null
      done
    ' || :
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
                  cp -r $src/.* $src/* $out/
                ''
              )
              + ''
                ${zcompileGlob "$out/**"}
              '';
          }
        )
    ) {};

  fast-syntax-highlighting = let
    name = "fast-syntax-highlighting";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = name;
        rev = "3d574ccf48804b10dca52625df13da5edae7f553";
        hash = "sha256-ZihUL4JAVk9V+IELSakytlb24BvEEJ161CQEHZYYoSA=";
      };
    };

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

  zsh-autosuggestions = let
    name = "zsh-autosuggestions";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = name;
        rev = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5";
        hash = "sha256-KmkXgK1J6iAyb1FtF/gOa0adUnh1pgFsgQOUnNngBaE=";
      };
      unpackPhase = ''
        mkdir -p $out/
        sed 's/(( $#POSTDISPLAY ))/(( ''${#''${POSTDISPLAY-}} ))/' \
          < $src/${name}.zsh > $out/${name}.zsh
      '';
    };

  fzf-tab = let
    name = "fzf-tab";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = name;
        rev = "0983009f8666f11e91a2ee1f88cfdb748d14f656";
        hash = "sha256-yvPQyuK4Dw+LkwxrkWTRcw4PIf/79fW61jWbEg8Pe9Y=";
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
    XDG_CONFIG_HOME=/tmp/ XDG_DATA_HOME=/tmp/ \
      ${config.programs.atuin.package}/bin/atuin init zsh \
        | $sd '^bindkey.+?\n' "" \
        | $sd -f s '_zsh_autosuggest_strategy_atuin\(\) \{.+?\}' \
            '_zsh_autosuggest_strategy_atuin () {
              suggestion=$(atuin search --cmd-only --limit 1 --search-mode prefix --cwd $$PWD -- "$$1")
            }
            ' > "$out/atuin.zsh"

    ${config.programs.zsh.package}/bin/zsh -dfc 'zcompile -U -- "$1"' _ "$out/atuin.zsh"
  '';
in {
  xdg.configFile = {
    # entrypoint
    # zdotdir is set by the nixos module and points to $XDG_CONFIG_HOME/zsh

    "zsh/.zshenv".source = ./zshenv;

    # plugins

    "zsh/plugins/fast-syntax-highlighting".source = fast-syntax-highlighting;
    # disabled: overlaps with atuin search/history widgets.
    # "zsh/plugins/zsh-history-substring-search".source = zsh-history-substring-search;
    "zsh/plugins/zsh-autosuggestions".source = zsh-autosuggestions;
    "zsh/plugins/fzf-tab".source = fzf-tab;
    "zsh/plugins/atuin.zsh".source = "${atuin-integration}/atuin.zsh";
    "zsh/plugins/atuin.zsh.zwc".source = "${atuin-integration}/atuin.zsh.zwc";
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

    "zsh/keybindings/keymap_foot.zsh" = {
      text = import ./keybindings/keymap_foot.nix {
        footKeysAttrSet = import ./keybindings/keys.nix {inherit lib;};
        inherit lib;
      };
      onChange = zcompileGlob "keybindings/keymap_foot.zsh";
    };

    "zsh/widgets" = {
      source = ./widgets;
      recursive = true;
      onChange = zcompileGlob "widgets/**.zsh";
    };
  };
}
