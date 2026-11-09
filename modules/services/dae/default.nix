{inputs, ...}: {
  flake.modules.nixos.dae = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      inputs.daeuniverse.nixosModules.dae
      inputs.sops-nix.nixosModules.sops
    ];

    config = {
      services.dae = {
        enable = true;
        package = inputs.daeuniverse.packages.${pkgs.stdenv.hostPlatform.system}."dae-unstable";
        config = builtins.readFile ./config.dae;
      };

      sops.secrets.dae-subscriptions = {
        sopsFile = ./subscriptions.dae.enc;
        format = "binary";
        path = "/etc/dae/subscriptions.dae";
        mode = "0400";
        reloadUnits = ["dae.service"];
      };

      environment.etc."dae/persist.d".source = "/var/lib/dae";
      systemd.services.dae.serviceConfig = {
        StateDirectory = "dae";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };

      systemd.services.dae-subscription-update = {
        description = "Refresh dae subscriptions";
        after = ["dae.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecCondition = "${pkgs.systemd}/bin/systemctl --quiet is-active dae.service";
          ExecStart = "${pkgs.systemd}/bin/systemctl reload dae.service";
        };
      };

      systemd.timers.dae-subscription-update = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 00,06,12,18:10:00";
          Persistent = true;
        };
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
  };
}
