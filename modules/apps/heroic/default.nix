{
  flake.modules.nixos.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.gaming.heroic;
    localUserName = config.local.user.name;
    protonPackages = import ../_proton.nix {inherit pkgs;};
    inherit (protonPackages) protonGePackage protonCachyos;
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
            source = "${protonGePackage.steamcompattool}";
            target = "${config.xdg.configHome}/heroic/tools/proton/proton-ge-nix";
          };
        };
        home.packages = with pkgs; lib.mkIf cfg.enableNative [heroic];
      };
    };
  };
}
