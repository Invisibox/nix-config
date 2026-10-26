{
  config,
  inputs,
  ...
}: let
  homeModule = config.flake.modules.homeManager.desktop;
in {
  flake.modules.nixos.base = {config, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-back";

      users.${config.local.user.name} = {
        imports = [homeModule];
        home = {
          username = config.local.user.name;
          homeDirectory = config.local.user.home;
        };
      };

      sharedModules = [
        inputs.spicetify-nix.homeManagerModules.default
        inputs.steam-config-nix.homeModules.default
      ];
    };
  };
}
