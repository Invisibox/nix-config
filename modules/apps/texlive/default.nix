{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.texlive;
in {
  options.texlive = {
    enable = lib.mkEnableOption "Enable TeX Live via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.texlive.combined.scheme-full;
      description = "TeX Live package installed for the user through Home Manager.";
    };

    windowsFontsPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      default = null;
      defaultText = lib.literalExpression ''
        null
        # fallback when texlive.enable = true:
        # inputs.chinese-fonts-overlay.packages.${pkgs.stdenv.hostPlatform.system}.windows-fonts
      '';
      description = ''
        Font package exposed only to TeX Live via dedicated FONTCONFIG_FILE and OSFONTDIR.
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

    texliveFontsConf = pkgs.writeText "texlive-fonts.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <reset-dirs />
        <dir>${windowsFontsPackage}/share/fonts</dir>
      </fontconfig>
    '';

    wrappedTexlivePackage = pkgs.symlinkJoin {
      name = cfg.package.name or "texlive-combined-full";
      paths = [ cfg.package ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # TeX engine aliases such as xelatex -> xetex derive formats from the
        # program name. Build wrappers that call the original package directly
        # instead of wrapping the symlink-joined aliases in place.
        rm -rf "$out/bin"
        mkdir -p "$out/bin"

        for bin in "${cfg.package}/bin"/*; do
          bin_name="$(basename "$bin")"

          if [ -x "$bin" ] && [ ! -d "$bin" ]; then
            makeWrapper "$bin" "$out/bin/$bin_name" \
              --set FONTCONFIG_FILE "${texliveFontsConf}" \
              --set OSFONTDIR "${windowsFontsPackage}/share/fonts//"
          else
            ln -s "$bin" "$out/bin/$bin_name"
          fi
        done
      '';
    };
  in {
    home-manager.users.${username}.home.packages = [
      wrappedTexlivePackage
    ];
  });
}
