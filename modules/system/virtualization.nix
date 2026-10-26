{
  flake.modules.nixos.virtualization = {
    config,
    pkgs,
    ...
  }: let
    localUserName = config.local.user.name;
  in {
    config = {
      boot = {
        extraModprobeConfig = ''
          options kvm_intel nested=1
          options kvm ignore_msrs=1 report_ignored_msrs=0
        '';
        kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
        };
      };

      environment = {
        systemPackages = with pkgs; [
          #docker-compose
          podlet
          quickemu
          spice
          spice-protocol
          virtiofsd
          virtio-win
          win-spice
        ];
      };

      networking.firewall.trustedInterfaces = ["virbr0"];

      programs.virt-manager.enable = true;

      services = {
        spice-vdagentd.enable = true;
        qemuGuest.enable = true;
      };

      virtualisation = {
        containers = {
          enable = true;
        };
        podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
          dockerCompat = false;
          dockerSocket.enable = false;
        };
        docker.enable = true;
        libvirtd = {
          # Make sure you run this once: "sudo virsh net-autostart default"
          enable = true;
          qemu = {
            swtpm.enable = true;
            vhostUserPackages = with pkgs; [virtiofsd];
          };
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
          ${localUserName} = {
            extraGroups = [
              "kvm"
              "libvirtd"
              "podman"
              "docker"
            ];
          };

          nixosvmtest = {
            isSystemUser = true;
            initialHashedPassword = "$y$j9T$B1obD.4xOr/6gJ6FCsu1v/$7axAjbaqRpFR3zGZVbOuCRGUNGJXyRxdavAHIyOdyK.";
            group = "nixosvmtest";
          };
        };
        groups = {
          nixosvmtest = {};
        };
      };
    };
  };
}
