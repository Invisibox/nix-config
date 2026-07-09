{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.cc-switch;
  localUserName = config.local.user.name;
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

    home-manager.users.${localUserName}.xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/ccswitch" = ["cc-switch.desktop"];
    };
  };
}
