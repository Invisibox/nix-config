{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  configDir = "${config.local.user.home}/Documents/nix-config/modules/apps/dae";
  privateDir = "${config.local.user.home}/.config/dae";
in {
  imports = [inputs.daeuniverse.nixosModules.dae];

  options.local.services.dae.enable = lib.mkEnableOption "Enable dae transparent proxy";

  config = lib.mkIf config.local.services.dae.enable {
    services.dae = {
      enable = true;
      package = inputs.daeuniverse.packages.${pkgs.stdenv.hostPlatform.system}."dae-unstable";
      configFile = "${configDir}/config.dae";
    };

    # dae rejects configuration files that are accessible by other users.
    systemd.tmpfiles.rules = [
      "z ${configDir}/config.dae 0600 - - - -"
      "d ${privateDir} 0700 ${config.local.user.name} - - -"
      "d ${privateDir}/persist.d 0700 ${config.local.user.name} - - -"
      "L ${configDir}/subscriptions.dae - - - - ${privateDir}/subscriptions.dae"
      "L ${configDir}/persist.d - - - - ${privateDir}/persist.d"
    ];

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
}
