{config, ...}: let
  nixosModules = config.flake.modules.nixos;
in {
  flake.modules.nixos.gaming = {
    imports = [
      nixosModules.steam
      nixosModules.gamescope
      nixosModules.heroic
    ];

    local.gaming.steam = {
      beta = true;
      fixDownloadSpeed = true;
    };

    hardware = {
      xone.enable = true;
      xpadneo.enable = true;
    };
  };
}
