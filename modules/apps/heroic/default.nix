{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.gaming.heroic;
  localUserName = config.local.user.name;
  protonCachyos =
    pkgs.runCommand "proton-cachyos-10.0-20260410-slr" {
      src = pkgs.fetchzip {
        url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20260410-slr/proton-cachyos-10.0-20260410-slr-x86_64_v3.tar.xz";
        hash = "sha256-t38hmJPUuifBCFbi6F5ACiqVS/HygQQOQpn0fvQMd8g=";
      };
    } ''
      mkdir -p "$out/share/steam/compatibilitytools.d/proton-cachyos"
      cp -r "$src"/* "$out/share/steam/compatibilitytools.d/proton-cachyos"
    '';
in {
  options = {
    local.gaming.heroic = {
      enable = lib.mkEnableOption "Enable heroic in home-manager";
      enableNative = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName} = {config, ...}: {
      home.file = {
        wine-links-proton-cachyos-heroic = {
          enable = cfg.enableNative;
          source = "${protonCachyos}/share/steam/compatibilitytools.d/proton-cachyos";
          target = "${config.xdg.configHome}/heroic/tools/proton/proton-cachyos";
        };
        wine-links-proton-ge-heroic = {
          enable = cfg.enableNative;
          source = "${pkgs.proton-ge.steamcompattool}";
          target = "${config.xdg.configHome}/heroic/tools/proton/proton-ge-nix";
        };
      };
      home.packages = with pkgs; lib.mkIf cfg.enableNative [heroic];
    };
  };
}
