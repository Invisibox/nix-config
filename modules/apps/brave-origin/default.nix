{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.brave-origin;
  localUserName = config.local.user.name;
  braveOriginBeta = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.brave-origin = {
    enable = lib.mkEnableOption "Enable Brave Origin Beta via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = braveOriginBeta;
      description = "The Brave Origin Beta package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
