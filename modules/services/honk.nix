{inputs, ...}: {
  flake.modules.nixos.honk = {
    lib,
    pkgs,
    ...
  }: let
    inherit (inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}) doona-web honk-core;

    # Honk reads this seed only when the persistent configuration DB is empty.
    initialConfig = pkgs.writeText "honk-config.dae" ''
      global {
        wan_interface: auto
        data_dir: '/var/lib/honk'
      }

      experimental {
        native_api {
          enabled: true
          listen: '127.0.0.1:9527'
          password_auth: true
          config_write: true
          ui: '/etc/honk/doona'
        }
      }
    '';
  in {
    systemd.packages = [honk-core];
    environment.systemPackages = [honk-core];
    environment.etc."honk/doona".source = doona-web;

    systemd.services.honk-core = {
      wantedBy = ["multi-user.target"];
      overrideStrategy = "asDropin";
      unitConfig.RequiresMountsFor = "/sys/fs/bpf";
      restartTriggers = [doona-web];

      # Leave the import source untouched once initialized.
      preStart = ''
        if [ ! -e /var/lib/honk/config.dae ]; then
          install -m 0600 ${initialConfig} /var/lib/honk/config.dae
        fi

        # Seed writable assets once so Doona can replace them in place.
        if [ ! -e "$STATE_DIRECTORY/geoip.dat" ]; then
          install -m 0600 ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat "$STATE_DIRECTORY/geoip.dat"
        fi
        if [ ! -e "$STATE_DIRECTORY/geosite.dat" ]; then
          install -m 0600 ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat "$STATE_DIRECTORY/geosite.dat"
        fi
      '';
      serviceConfig = {
        ExecStart = ["" "${lib.getExe honk-core} --disable-timestamp --store db -c /var/lib/honk/config.dae"];
        StateDirectory = "honk";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/honk";
        UMask = "0077";
      };
    };

    fileSystems."/sys/fs/bpf" = {
      device = "bpf";
      fsType = "bpf";
      options = ["nosuid" "nodev" "noexec" "mode=0700"];
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkOptionDefault 1;
      "net.ipv6.conf.all.forwarding" = lib.mkOptionDefault 1;
      "net.ipv4.conf.all.rp_filter" = lib.mkDefault 2;
    };

    networking.firewall = {
      trustedInterfaces = ["dae0"];
      checkReversePath = lib.mkDefault "loose";
    };
  };
}
