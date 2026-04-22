{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.wps;

in {
  options.wps = {
    enable = lib.mkEnableOption "Enable WPS Office (wpsoffice-cn)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wpsoffice-cn;
      description = "WPS Office package installed for the user through Home Manager.";
    };

    windowsFontsPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      default = null;
      defaultText = lib.literalExpression ''
        null
        # fallback when wps.enable = true:
        # inputs.chinese-fonts-overlay.packages.${pkgs.stdenv.hostPlatform.system}.windows-fonts
      '';
      description = ''
        Font package exposed only to WPS via dedicated FONTCONFIG_FILE.
        If null, fallback to windows-fonts from chinese-fonts-overlay when WPS is enabled.
      '';
    };

    qtImModule = lib.mkOption {
      type = lib.types.str;
      default = "fcitx";
      description = ''
        QT input method module passed to WPS launchers.
        For fcitx5 compatibility, keep this as "fcitx".
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    # Keep chinese-fonts-overlay lazy so it is not fetched/evaluated unless WPS is enabled.
    system = pkgs.stdenv.hostPlatform.system;
    defaultWindowsFontsPackage = inputs.chinese-fonts-overlay.packages.${system}.windows-fonts;
    windowsFontsPackage =
      if cfg.windowsFontsPackage == null
      then defaultWindowsFontsPackage
      else cfg.windowsFontsPackage;

    wpsFontsConf = pkgs.writeText "wps-fonts.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <reset-dirs />
        <dir>${windowsFontsPackage}/share/fonts</dir>
      </fontconfig>
    '';

    # WPS bundles its own Qt stack and may fail to pick up input method settings
    # in some Wayland/XWayland setups. Wrap launchers explicitly for IME env.
    wrappedWpsPackage = cfg.package.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
      postFixup =
        (old.postFixup or "")
        + ''
          for bin in wps wpp et wpspdf; do
            if [ -x "$out/bin/$bin" ]; then
              wrapProgram "$out/bin/$bin" \
                --set QT_QPA_PLATFORM "xcb" \
                --set QT_IM_MODULE "${cfg.qtImModule}" \
                --set XMODIFIERS "@im=${cfg.qtImModule}" \
                --set FONTCONFIG_FILE "${wpsFontsConf}"
            fi
          done
        '';
    });
  in {
    home-manager.users.${username}.home.packages = [
      wrappedWpsPackage
    ];
  });
}
