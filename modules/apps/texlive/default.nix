{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.apps.texlive;
  localUserName = config.local.user.name;
in {
  options.local.apps.texlive = {
    enable = lib.mkEnableOption "Enable TeX Live via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.texliveFull;
      description = "TeX Live package installed for the user through Home Manager.";
    };

    windowsFontsPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      default = null;
      defaultText = lib.literalExpression ''
        null
        # fallback when local.apps.texlive.enable = true:
        # inputs.chinese-fonts-overlay.packages.${pkgs.stdenv.hostPlatform.system}.windows-fonts
      '';
      description = ''
        Font package exposed to TeX Live via a merged FONTCONFIG_FILE.
        If null, fallback to windows-fonts from chinese-fonts-overlay when TeX Live is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    # Keep chinese-fonts-overlay lazy so it is not fetched/evaluated unless TeX Live is enabled.
    system = pkgs.stdenv.hostPlatform.system;
    defaultWindowsFontsPackage = inputs.chinese-fonts-overlay.packages.${system}.windows-fonts;
    windowsFontsPackage =
      if cfg.windowsFontsPackage == null
      then defaultWindowsFontsPackage
      else cfg.windowsFontsPackage;

    texliveFontsConf = pkgs.runCommand "texlive-fonts.conf" {} ''
      texlive_fonts_conf=""

      for bin in "${cfg.package}/bin"/*; do
        if [ -f "$bin" ]; then
          texlive_fonts_conf="$(
            sed -n "s|.*FONTCONFIG_FILE=.*'\([^']*fonts\.conf\)'.*|\1|p" "$bin" \
              | head -n 1
          )"

          if [ -n "$texlive_fonts_conf" ]; then
            break
          fi
        fi
      done

      if [ -z "$texlive_fonts_conf" ]; then
        echo "could not find TeX Live's generated FONTCONFIG_FILE in ${cfg.package}/bin" >&2
        exit 1
      fi

      cat > "$out" <<EOF
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <include>$texlive_fonts_conf</include>
        <dir>${windowsFontsPackage}/share/fonts</dir>
      </fontconfig>
      EOF
    '';

    wrappedTexlivePackage = pkgs.symlinkJoin {
      name = cfg.package.name or "texlive-full";
      paths = [cfg.package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        # TeX Live ships generated launchers with their own FONTCONFIG_FILE
        # defaults. Wrap them from the outside so this fontconfig file wins.
        rm -rf "$out/bin"
        mkdir -p "$out/bin"

        for bin in "${cfg.package}/bin"/*; do
          bin_name="$(basename "$bin")"

          if [ -x "$bin" ] && [ ! -d "$bin" ]; then
            makeWrapper "$bin" "$out/bin/$bin_name" \
              --set FONTCONFIG_FILE "${texliveFontsConf}"
          else
            ln -s "$bin" "$out/bin/$bin_name"
          fi
        done
      '';
    };
  in {
    home-manager.users.${localUserName}.home.packages = [
      wrappedTexlivePackage
    ];
  });
}
