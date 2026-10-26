{inputs, ...}: {
  flake.modules.nixos.paseo = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.apps.paseo;
    localUserName = config.local.user.name;
    packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    options.local.apps.paseo = {
      package = lib.mkOption {
        type = lib.types.package;
        default = packages.paseo-desktop;
        description = "The Paseo Desktop package to use.";
      };
    };

    config = {
      environment.systemPackages = [cfg.package];

      home-manager.users.${localUserName}.xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/paseo" = ["paseo-desktop.desktop"];
      };
    };
  };
}
