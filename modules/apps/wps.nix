{inputs, ...}: {
  flake.modules.nixos.wps = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.apps.wps;
    packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    options.local.apps.wps.package = lib.mkOption {
      type = lib.types.package;
      default = packages.wps-office;
      description = "WPS Office with private Windows fonts, Fcitx support and launcher fixes.";
    };

    config.home-manager.users.${config.local.user.name}.home.packages = [cfg.package];
  };
}
