{
  config,
  inputs,
  ...
}: let
  homeModules = config.flake.modules.homeManager;
in {
  flake.modules.nixos.base = {config, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-back";

      users.${config.local.user.name} = {
        imports = [homeModules.base homeModules.shell];
        home = {
          username = config.local.user.name;
          homeDirectory = config.local.user.home;
        };
      };

      sharedModules = [
        inputs.steam-config-nix.homeModules.default
      ];
    };
  };
}
