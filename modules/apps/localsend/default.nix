{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.localsend;
  localUserName = config.local.user.name;
in {
  options.local.apps.localsend = {
    enable = lib.mkEnableOption "Enable LocalSend via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.localsend;
      description = "The LocalSend package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
