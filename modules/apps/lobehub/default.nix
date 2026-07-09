{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.lobehub;
  localUserName = config.local.user.name;
  lobehubPackages = import ./package.nix {inherit lib pkgs;};
in {
  options.local.apps.lobehub = {
    enable = lib.mkEnableOption "Enable LobeHub Desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = lobehubPackages.package;
      description = "The LobeHub Desktop package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      lobehubPackages.cliPackage
    ];

    home-manager.users.${localUserName}.xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/lobehub" = ["lobehub-desktop.desktop"];
    };
  };
}
