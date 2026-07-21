{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.baidunetdisk;
  baidunetdiskPackage = import ./package.nix {inherit lib pkgs;};
  baidunetdiskSandboxed = import ./sandbox.nix {
    inherit pkgs;
    basePackage = cfg.basePackage;
  };
in {
  options.local.apps.baidunetdisk = {
    enable = lib.mkEnableOption "Enable Baidu Netdisk";

    basePackage = lib.mkOption {
      type = lib.types.package;
      default = baidunetdiskPackage;
      description = "Base Baidu Netdisk package used to build the sandboxed launcher.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = baidunetdiskSandboxed;
      description = "Final Baidu Netdisk package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
