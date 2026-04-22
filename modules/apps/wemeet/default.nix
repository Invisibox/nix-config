{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.wemeet;
in {
  options.wemeet = {
    enable = lib.mkEnableOption "Enable native WeMeet with XWayland launcher";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wemeet;
      description = "The WeMeet package installed via Home Manager.";
    };
  };

  config = lib.mkIf cfg.enable (let
    pkgsStable = import inputs.nixpkgs-stable {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    wemeetX11 = pkgs.symlinkJoin {
      name = "wemeet-native-x11";
      paths = [pkgsStable.wemeet];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm -f "$out/bin/wemeet"
        makeWrapper "${pkgsStable.wemeet}/bin/wemeet-xwayland" "$out/bin/wemeet" \
          --set QT_QPA_PLATFORM "xcb" \
          --set SDL_VIDEODRIVER "x11" \
          --set GDK_BACKEND "x11" \
          --unset WAYLAND_DISPLAY \
          --set __EGL_VENDOR_LIBRARY_FILENAMES "${pkgsStable.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      '';
    };
  in {
    # Keep current behavior: default to stable wrapped XWayland WeMeet when enabled.
    wemeet.package = lib.mkDefault wemeetX11;

    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  });
}
