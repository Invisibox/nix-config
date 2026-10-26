{config, ...}: let
  nixosModules = config.flake.modules.nixos;
  homeModule = config.flake.modules.homeManager.dev;
in {
  flake.modules.nixos.dev = {config, ...}: {
    imports = [
      nixosModules.nix-ld
      nixosModules.virtualization
    ];

    home-manager.users.${config.local.user.name}.imports = [homeModule];
  };
}
