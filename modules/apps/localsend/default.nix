{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.localsend;
in {
  options.localsend = {
    enable = lib.mkEnableOption "Enable LocalSend via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.localsend;
      description = "The LocalSend package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  };
}
