{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.omp;
  localUserName = config.local.user.name;
  omp = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.omp = {
    enable = lib.mkEnableOption "Enable Oh My Pi via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = omp;
      description = "The Oh My Pi package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  };
}
