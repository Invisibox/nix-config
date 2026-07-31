{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.paseo;
  localUserName = config.local.user.name;
  paseo = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.paseo = {
    enable = lib.mkEnableOption "Enable Paseo via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = paseo;
      description = "The Paseo package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
