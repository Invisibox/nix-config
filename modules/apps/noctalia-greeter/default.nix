{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  cfg = config.local.desktop.noctalia-greeter;
in {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.local.desktop.noctalia-greeter = {
    enable = lib.mkEnableOption "Enable Noctalia Greeter";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = lib.mkForce false;

    programs.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 22;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
        keyboard.layout = "us";
      };
    };

    environment.systemPackages = [pkgs.bibata-cursors];
  };
}
