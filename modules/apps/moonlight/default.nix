{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.moonlight;
in {
  options.moonlight = {
    enable = lib.mkEnableOption "Enable Moonlight via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.moonlight-qt;
      description = "Moonlight package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  };
}
