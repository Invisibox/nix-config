{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.local.apps.cc-switch;
  ccSwitchPackage = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.cc-switch = {
    enable = lib.mkEnableOption "Enable CC Switch";

    package = lib.mkOption {
      type = lib.types.package;
      default = ccSwitchPackage;
      description = "The CC Switch package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    home-manager.users.${username}.xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/ccswitch" = ["cc-switch.desktop"];
    };
  };
}
