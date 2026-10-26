{config, ...}: let
  nixosModules = config.flake.modules.nixos;
  homeModule = config.flake.modules.homeManager.desktop;
in {
  flake.modules.nixos.desktop = {config, ...}: {
    imports = [
      nixosModules.niri
      nixosModules.noctalia-greeter
      nixosModules.fingerprint
      nixosModules.printing
    ];

    home-manager.users.${config.local.user.name}.imports = [homeModule];

    programs.dconf.enable = true;

    services.gvfs.enable = true;
  };
}
