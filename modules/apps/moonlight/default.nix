{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.moonlight;
  localUserName = config.local.user.name;
in {
  options.local.apps.moonlight = {
    enable = lib.mkEnableOption "Enable Moonlight via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.moonlight-qt;
      description = "Moonlight package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
