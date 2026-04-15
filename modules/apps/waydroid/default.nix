{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.waydroid;
  kernelVersion = lib.getVersion config.boot.kernelPackages.kernel;
  preferNftables = config.networking.nftables.enable || lib.versionAtLeast kernelVersion "6.17";
  waydroidInitDefault = pkgs.writeShellApplication {
    name = "waydroid-init-default";
    runtimeInputs = [
      cfg.package
      pkgs.sudo
    ];
    text = ''
      set -euo pipefail

      system_type="${cfg.initSystemType}"

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo waydroid init -s "$system_type" "$@"
      fi

      exec waydroid init -s "$system_type" "$@"
    '';
  };
in {
  options.waydroid = {
    enable = lib.mkEnableOption "Enable Waydroid on NixOS";

    package = lib.mkOption {
      type = lib.types.package;
      default = if preferNftables then pkgs.waydroid-nftables else pkgs.waydroid;
      defaultText = lib.literalExpression ''
        if config.networking.nftables.enable
        || lib.versionAtLeast (lib.getVersion config.boot.kernelPackages.kernel) "6.17"
        then pkgs.waydroid-nftables
        else pkgs.waydroid
      '';
      description = "The Waydroid package to use.";
    };

    initSystemType = lib.mkOption {
      type = lib.types.enum [
        "VANILLA"
        "FOSS"
        "GAPPS"
      ];
      default = "GAPPS";
      description = ''
        Default system type used by the helper command `waydroid-init-default`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (preferNftables && cfg.package == pkgs.waydroid) ''
      waydroid.package is set to pkgs.waydroid, but kernel ${kernelVersion} is more reliable
      with pkgs.waydroid-nftables because Waydroid legacy iptables mode may fail with
      "Module ip_tables not found".
    '';

    virtualisation.waydroid = {
      enable = true;
      package = cfg.package;
    };

    environment.systemPackages = [
      waydroidInitDefault
    ];
  };
}
