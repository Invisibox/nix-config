{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.wps;

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
              --set XMODIFIERS "@im=${cfg.qtImModule}"
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
