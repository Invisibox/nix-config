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
      setopt extendedglob globstarshort dotglob
      for f in ${globs}; do
        zcompile -U -- $f 2>/dev/null
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

  zsh-syntax-highlighting = let
    name = "zsh-syntax-highlighting";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = name;
        rev = "5eb677bb0fa9a3e60f0eff031dc13926e093df92";
        hash = "sha256-KRsQEDRsJdF7LGOMTZuqfbW6xdV5S38wlgdcCM98Y/Q=";
      };
    };

  zsh-history-substring-search = let
    name = "zsh-history-substring-search";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = name;
        rev = "87ce96b1862928d84b1afe7c173316614b30e301";
        hash = "sha256-1+w0AeVJtu1EK5iNVwk3loenFuIyVlQmlw8TWliHZGI=";
      };
    };

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

  fzf-tab-completion = let
    name = "fzf-tab-completion";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "lincheney";
        repo = name;
        rev = "4850357beac6f8e37b66bd78ccf90008ea3de40b";
        hash = "sha256-pgcrRRbZaLoChVPeOvw4jjdDCokUK1ew0Wfy42bXfQo=";
      };
      unpackPhase = ''
        mkdir -p $out/
        cp $src/zsh/fzf-zsh-completion.sh $out/${name}.zsh
      '';
    };

  zsh-smartcache = let
    name = "zsh-smartcache";
  in
    mkZshPlugin name {
      src = pkgs.fetchFromGitHub {
        owner = "QuarticCat";
        repo = "zsh-smartcache";
        rev = "641dbfa196c9f69264ad7a49f9ef180af75831be";
        hash = "sha256-t6QbAMFJfCvEOtq1y/YXZz5eyyc5OHOM/xg3cgXNcjU=";
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

    XDG_CONFIG_HOME=/tmp/ XDG_DATA_HOME=/tmp/ \
      ${config.programs.atuin.package}/bin/atuin init zsh \
        | $sd '^bindkey.+?\n' "" \
        | $sd -f s '_zsh_autosuggest_strategy_atuin\(\) \{.+?\}' \
            '_zsh_autosuggest_strategy_atuin () {
              suggestion=$(atuin search --cmd-only --limit 1 --search-mode prefix --cwd $$PWD -- "$$1")
            }
            ' > $out
  '';
in {
  xdg.configFile = {
    # entrypoint
    # zdotdir is set by the nixos module and points to $XDG_CONFIG_HOME/zsh

    "zsh/.zshenv".source = ./zshenv;

    # plugins

    "zsh/plugins/zsh-syntax-highlighting".source = zsh-syntax-highlighting;
    "zsh/plugins/zsh-history-substring-search".source = zsh-history-substring-search;
    "zsh/plugins/zsh-autosuggestions".source = zsh-autosuggestions;
    "zsh/plugins/fzf-tab-completion".source = fzf-tab-completion;
    "zsh/plugins/atuin.zsh".source = atuin-integration;
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
        footKeysAttrSet = import ../foot/keys.nix {inherit lib;};
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
