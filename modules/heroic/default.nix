{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.heroic;
in
{
  options = {
    heroic = {
      enable = lib.mkEnableOption "Enable heroic in home-manager";
      enableNative = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.zh =
      { config, pkgs, ... }:
      {
        home.file = {
          wine-links-proton-cachyos-heroic = {
            enable = cfg.enableNative;
            source = config.lib.file.mkOutOfStoreSymlink "${
              inputs.chaotic.packages.${pkgs.system}.proton-cachyos
            }/bin";
            target = "${config.xdg.configHome}/heroic/tools/proton/proton-cachyos";
          };
          wine-links-proton-ge-heroic = {
            enable = cfg.enableNative;
            source = config.lib.file.mkOutOfStoreSymlink "${pkgs.proton-ge-bin.steamcompattool}";
            target = "${config.xdg.configHome}/heroic/tools/proton/proton-ge-bin";
          };
        };
        home.packages = with pkgs; lib.mkIf cfg.enableNative [ heroic ];
      };
  };
}