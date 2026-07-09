{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.local.apps.brave-origin;
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
    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  };
}
