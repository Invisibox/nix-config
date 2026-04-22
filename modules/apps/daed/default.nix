{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.daed;
  system = pkgs.stdenv.hostPlatform.system;
  daePackages = inputs.daeuniverse.packages.${system};
  daePackageFromFlake = daePackages.dae;
  daedPackageFromFlake = daePackages.daed;
  genAssetsDrv = paths:
    pkgs.symlinkJoin {
      name = "daed-assets";
      inherit paths;
    };
  listen = "${cfg.dashboardAddress}:${toString cfg.dashboardPort}";
  runArgs =
    [
      "run"
      "-c"
      cfg.configDir
      "--listen"
      listen
    ]
    ++ lib.optionals cfg.apiOnly [ "--api-only" ]
    ++ lib.optionals cfg.disableTimestamp [ "--disable-timestamp" ]
    ++ cfg.extraArgs;
in
{
  options = {
    daed = {
      enable = lib.mkEnableOption "Enable daed network proxy dashboard";

      package = lib.mkOption {
        type = lib.types.package;
        default = daedPackageFromFlake;
        defaultText = lib.literalExpression "inputs.daeuniverse.packages.${system}.daed";
        description = "The daed package to use.";
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/daed";
        description = "Writable config/state directory used by daed.";
      };

      dashboardAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Dashboard listen address for daed.";
      };

      dashboardPort = lib.mkOption {
        type = lib.types.port;
        default = 2023;
        description = "Dashboard listen port for daed.";
      };

      openDashboardFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open dashboard port in firewall.";
      };

      tproxyPort = lib.mkOption {
        type = lib.types.port;
        default = 12345;
        description = "TPROXY port used by dae core.";
      };

      openProxyFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open TPROXY port in firewall.";
      };

      autoKernelForward = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable kernel forwarding for transparent proxy.";
      };

      autoLooseRpFilter = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use loose reverse-path filtering for transparent proxy.";
      };

      trustDaeInterface = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Trust dae TUN interface in firewall.";
      };

      apiOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run daed in API-only mode (without proxy engine).";
      };

      disableTimestamp = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable timestamp prefix in daed logs.";
      };

      extraArgs = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Extra command line arguments appended to `daed run`.";
      };

      assets = lib.mkOption {
        type = with lib.types; listOf path;
        default = with pkgs; [
          v2ray-geoip
          v2ray-domain-list-community
        ];
        defaultText = lib.literalExpression "with pkgs; [ v2ray-geoip v2ray-domain-list-community ]";
        description = "Geo assets required by dae core (geoip/geosite).";
      };

      assetsPath = lib.mkOption {
        type = lib.types.str;
        default = "${genAssetsDrv cfg.assets}/share/v2ray";
        defaultText = lib.literalExpression ''
          (symlinkJoin {
            name = "daed-assets";
            paths = assets;
          })/share/v2ray
        '';
        description = "Path that contains geoip.dat and geosite.dat.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      daePackageFromFlake
      cfg.package
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0750 root root - -"
    ];

    boot.kernel.sysctl = lib.mkMerge [
      (lib.mkIf cfg.autoKernelForward {
        "net.ipv4.ip_forward" = lib.mkOptionDefault 1;
        "net.ipv6.conf.all.forwarding" = lib.mkOptionDefault 1;
      })
      (lib.mkIf cfg.autoLooseRpFilter {
        "net.ipv4.conf.all.rp_filter" = lib.mkDefault 2;
      })
    ];

    networking.firewall = lib.mkMerge [
      {
        allowedTCPPorts =
          lib.optionals cfg.openProxyFirewall [ cfg.tproxyPort ]
          ++ lib.optionals cfg.openDashboardFirewall [ cfg.dashboardPort ];
        allowedUDPPorts = lib.optionals cfg.openProxyFirewall [ cfg.tproxyPort ];
      }
      (lib.mkIf cfg.trustDaeInterface {
        trustedInterfaces = [ "dae0" ];
      })
      (lib.mkIf cfg.autoLooseRpFilter {
        checkReversePath = lib.mkDefault "loose";
      })
    ];

    systemd.services.daed = {
      description = "daed network proxy dashboard";
      after = [
        "network-online.target"
        "systemd-sysctl.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Environment = "DAE_LOCATION_ASSET=${cfg.assetsPath}";
        ExecStart = "${lib.getExe' cfg.package "daed"} ${lib.escapeShellArgs runArgs}";
        Restart = "on-failure";
        RestartSec = "2s";
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
      };
    };

    assertions = [
      {
        assertion = lib.pathExists (toString (genAssetsDrv cfg.assets) + "/share/v2ray");
        message = ''
          Packages in `daed.assets` do not provide `share/v2ray`.
          Please set `daed.assetsPath` manually.
        '';
      }
    ];
  };
}
