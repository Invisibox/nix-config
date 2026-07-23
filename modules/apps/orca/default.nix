{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.orca;
  localUserName = config.local.user.name;
  orca = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.orca = {
    enable = lib.mkEnableOption "Enable Orca via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = orca;
      description = "The Orca package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
