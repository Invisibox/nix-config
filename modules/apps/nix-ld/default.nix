{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.dev.nix-ld;
  localUserName = config.local.user.name;
in {
  options = {
    local.dev.nix-ld = {
      enable = lib.mkEnableOption "Enable nix-ld in NixOS";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs;
        (steam-run.args.multiPkgs pkgs)
        ++ (heroic.args.multiPkgs pkgs)
        ++ (lutris.args.multiPkgs pkgs)
        ++ [
          alsa-lib
          dbus
          glibc
          gst_all_1.gstreamer
          gst_all_1.gst-libav
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-ugly
          gtk3
          icu
          libcap
          libxcrypt
          libGL
          libdrm
          libudev0-shim
          libva
          mesa
          networkmanager
          pkg-config
          libX11
          libXext
          udev
          vulkan-loader
        ];
    };
    home-manager.users.${localUserName} = {};
  };
}
