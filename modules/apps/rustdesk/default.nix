{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.rustdesk;
in {
  options.rustdesk = {
    enable = lib.mkEnableOption "Enable RustDesk desktop client";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rustdesk;
      description = "RustDesk package installed for the user.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open RustDesk peer ports for controlled-endpoint use.
        This does not enable RustDesk relay/signal server services.
      '';
    };

    tcpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        21115
        21116
        21118
        21119
      ];
      description = "TCP ports opened when rustdesk.openFirewall = true.";
    };

    udpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [21116];
      description = "UDP ports opened when rustdesk.openFirewall = true.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [cfg.package];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = cfg.tcpPorts;
      allowedUDPPorts = cfg.udpPorts;
    };
  };
}
