{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.apps.im;
  localUserName = config.local.user.name;
  wechatSandboxed = import ./wechat-sandbox.nix {
    inherit pkgs;
    basePackage = cfg.wechatBasePackage;
  };
  qqSandboxed = import ./qq-sandbox.nix {
    inherit pkgs;
    basePackage = cfg.qqPackage;
  };
in {
  options.local.apps.im = {
    enable = lib.mkEnableOption "Enable sandboxed WeChat and QQ managed by Home Manager";

    wechatBasePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wechat;
      description = "Base WeChat package to sandbox (default: WeChat Universal).";
    };

    wechatPackage = lib.mkOption {
      type = lib.types.package;
      default = wechatSandboxed;
      description = "Final WeChat package installed for the user.";
    };

    qqPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qq;
      description = "Base QQ package wrapped in a strict bubblewrap sandbox.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${localUserName}.home.packages = [
      cfg.wechatPackage
      qqSandboxed
    ];
  };
}
