{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.daed;
in {
  imports = [inputs.daeuniverse.nixosModules.daed];
  options = {
    daed = {
      enable = lib.mkEnableOption "Enable Daed in NixOS";
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      # dae = {
      #   enable = true;
      #   openFirewall = {
      #     enable = true;
      #     port = 12345;
      #   };
      # };
      daed = {
        enable = true;
        openFirewall = {
          enable = true;
          port = 12345;
        };
      };
    };
  };
}
