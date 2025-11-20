{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.virtualization;
in {
  options = {
    virtualization = {
      enable = lib.mkEnableOption "Enable virtualization in NixOS & home-manager";
    };
  };
  config = lib.mkIf cfg.enable {
    boot = {
      extraModprobeConfig = ''
        options kvm_amd nested=1
        options kvm ignore_msrs=1 report_ignored_msrs=0
      '';
      kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        docker-compose
        podlet
        win-spice
      ];
    };

    virtualisation = {
      docker = {
        enable = true;
      };
      podman = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
        defaultNetwork.settings.dns_enabled = true;
        #dockerCompat = true;
        #dockerSocket.enable = true;
      };
      spiceUSBRedirection.enable = true;
      vmVariant = {
        virtualisation = {
          memorySize = 4096;
          cores = 3;
        };
      };
    };

    users = {
      users = {
        ${username} = {
          extraGroups = [
            "docker"
            "podman"
          ];
        };
      };
    };

    home-manager.users.${username} = {};
  };
}
