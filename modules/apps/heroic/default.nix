{
  lib,
  config,
  username,
  pkgs,
  ...
}:
let
  cfg = config.heroic;
  protonCachyos = pkgs.runCommand "proton-cachyos-10.0-20260410-slr" {
    src = pkgs.fetchzip {
      url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20260410-slr/proton-cachyos-10.0-20260410-slr-x86_64_v3.tar.xz";
      hash = "sha256-t38hmJPUuifBCFbi6F5ACiqVS/HygQQOQpn0fvQMd8g=";
    };
  } ''
    mkdir -p "$out/share/steam/compatibilitytools.d/proton-cachyos"
    cp -r "$src"/* "$out/share/steam/compatibilitytools.d/proton-cachyos"
  '';
in
{
  options = {
    heroic = {
      enable = lib.mkEnableOption "Enable heroic in home-manager";
      enableFlatpak = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableNative = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} =
      { config, ... }:
      {
        home.file = {
          wine-links-proton-cachyos-heroic = {
            enable = cfg.enableNative;
            source = "${protonCachyos}/share/steam/compatibilitytools.d/proton-cachyos";
            target = "${config.xdg.configHome}/heroic/tools/proton/proton-cachyos";
          };
          wine-links-proton-cachyos-flatpak-heroic = {
            enable = cfg.enableFlatpak;
            source = "${protonCachyos}/share/steam/compatibilitytools.d/proton-cachyos";
            target = ".var/app/com.heroicgameslauncher.hgl/config/heroic/tools/proton/proton-cachyos";
          };
          wine-links-proton-ge-heroic = {
            enable = cfg.enableNative;
            source = "${pkgs.proton-ge-bin.steamcompattool}";
            target = "${config.xdg.configHome}/heroic/tools/proton/proton-ge-bin";
          };
          wine-links-proton-ge-flatpak-heroic = {
            enable = cfg.enableFlatpak;
            source = "${pkgs.proton-ge-bin.steamcompattool}";
            target = ".var/app/com.heroicgameslauncher.hgl/config/heroic/tools/proton/proton-ge-bin";
          };
        };
        home.packages = with pkgs; lib.mkIf cfg.enableNative [ heroic ];
        services.flatpak = lib.mkIf cfg.enableFlatpak {
          overrides = {
            "com.heroicgameslauncher.hgl" = {
              Context = {
                filesystems = [
                  "/mnt/crusader/Games"
                  "${config.home.homeDirectory}/Games"
                  "${config.xdg.dataHome}/applications"
                  "${config.xdg.dataHome}/Steam"
                ];
              };
              "Session Bus Policy" = {
                "org.freedesktop.Flatpak" = "talk";
              };
            };
          };
          packages = [
            "com.heroicgameslauncher.hgl"
          ];
        };
      };
  };
}
