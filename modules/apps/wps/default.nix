{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.wps;

  # chinese-fonts-overlay has a broken `packages` output in the pinned revision.
  # Use its overlay directly to obtain windows-fonts reliably.
  chineseFontsOverlay = inputs.chinese-fonts-overlay.overlays.default;
  windowsFontsFromOverlay = (chineseFontsOverlay pkgs pkgs).windows-fonts;

  wpsFontsConf = pkgs.writeText "wps-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <reset-dirs />
      <dir>${cfg.windowsFontsPackage}/share/fonts</dir>
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
  options.wps = {
    enable = lib.mkEnableOption "Enable WPS Office (wpsoffice-cn)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wpsoffice-cn;
      description = "WPS Office package installed for the user through Home Manager.";
    };

    windowsFontsPackage = lib.mkOption {
      type = lib.types.package;
      default = windowsFontsFromOverlay;
      defaultText = lib.literalExpression "(inputs.chinese-fonts-overlay.overlays.default pkgs pkgs).windows-fonts";
      description = ''
        Font package exposed only to WPS via dedicated FONTCONFIG_FILE.
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

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      wrappedWpsPackage
    ];
  };
}
