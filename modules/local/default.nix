{
  lib,
  config,
  ...
}: {
  options.local.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "zh";
      description = "Primary local user name used by local feature modules.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.local.user.name}";
      defaultText = lib.literalExpression ''"/home/''${config.local.user.name}"'';
      description = "Home directory for the primary local user.";
    };
  };
}
