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
    # LocalSend uses port 53317 for file transfers and peer discovery.
    # The TCP listener must be reachable for other devices to send files to us.
    networking.firewall = {
      allowedTCPPorts = [53317];
      allowedUDPPorts = [53317];
    };

    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
