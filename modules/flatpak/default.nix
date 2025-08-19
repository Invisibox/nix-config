{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.flatpak;
in
{

  options = {
    flatpak = {
      enable = lib.mkEnableOption "Enable flatpak in NixOS & home-manager";
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      flatpak = {
        enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      flatpak-builder
      xdg-dbus-proxy
    ];

    systemd.services = {
      "home-manager-zh" = {
        serviceConfig.TimeoutStartSec = pkgs.lib.mkForce 1200;
      };
    };

    users.users.zh.extraGroups = [ "flatpak" ];

    xdg.portal.enable = true;

    home-manager.users.zh =
      { config, ... }:
      {
        home = {
          sessionPath = [
            "/var/lib/flatpak/exports/bin"
            "${config.xdg.dataHome}/flatpak/exports/bin"
          ];
        };
        services.flatpak = {
          packages = [
            "io.github.DenysMb.Kontainer"
            "com.tencent.WeChat"
            "com.baidu.NetDisk"
            "com.qq.QQ"
            "com.tencent.wemeet"
            "org.telegram.desktop"
            "com.cherry_ai.CherryStudio"
          ];
          remotes = [
            {
              name = "flathub";
              location = "https://flathub.org/repo/flathub.flatpakrepo";
            }
            {
              name = "flathub-beta";
              location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
            }
          ];
          overrides = {
            global = {
              Context = {
                filesystems = [
                  "/nix/store:ro"
                  "/run/current-system/sw/bin:ro"
                  "/run/media/zh:ro"
                  # Theming
                  "${config.home.homeDirectory}/.icons:ro"
                  "${config.home.homeDirectory}/.themes:ro"
                  "xdg-config/fontconfig:ro"
                  "xdg-config/gtkrc:ro"
                  "xdg-config/gtkrc-2.0:ro"
                  "xdg-config/gtk-2.0:ro"
                  "xdg-config/gtk-3.0:ro"
                  "xdg-config/gtk-4.0:ro"
                  "xdg-data/themes:ro"
                  "xdg-data/icons:ro"
                ];
              };
              Environment = {
                # Wrong cursor in flatpaks fix
                XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
              };
            };
          };
          uninstallUnmanaged = false;
        };
      };
  };
}