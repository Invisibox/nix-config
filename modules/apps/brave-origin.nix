{inputs, ...}: {
  flake.modules.nixos.brave-origin = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.apps.brave-origin;
    localUserName = config.local.user.name;
    packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    options.local.apps.brave-origin = {
      package = lib.mkOption {
        type = lib.types.package;
        default = packages.brave-origin-beta;
        description = "The Brave Origin Beta package installed for the user.";
      };
    };

    config = {
      home-manager.users.${localUserName}.home.packages = [
        cfg.package
      ];
    };
  };
}
