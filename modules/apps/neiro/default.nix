{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.services.neiro;
  python = pkgs.python3.withPackages (ps: [ps.tomlkit]);
  settingsFile = pkgs.writeText "neiro-settings.json" (builtins.toJSON (cfg.settings
    // {
      # Offline CLI commands should use the same tuning as the daemon.
      tuning_path = toString cfg.tuningFile;
    }));
in {
  options.local.services.neiro = {
    enable = lib.mkEnableOption "Neiro speaker enhancement";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {};
      description = "Neiro package to use.";
    };

    tuningFile = lib.mkOption {
      type = lib.types.path;
      description = "Dolby DAX3 XML for this machine's built-in speakers.";
    };

    settings = lib.mkOption {
      type = (pkgs.formats.toml {}).type;
      default = {};
      description = ''
        Fields of state.toml enforced at each daemon start. Other fields,
        including the personal EQ and profile overrides, remain writable.
        Declaring a table replaces that entire table.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.pipewire.enable && config.services.pipewire.wireplumber.enable;
        message = "Neiro requires PipeWire and WirePlumber.";
      }
      {
        assertion =
          !(cfg.settings ? hw_volume)
          || (builtins.isFloat cfg.settings.hw_volume || builtins.isInt cfg.settings.hw_volume)
          && cfg.settings.hw_volume >= 0
          && cfg.settings.hw_volume <= 1;
        message = "Neiro hw_volume must be between 0 and 1.";
      }
    ];

    home-manager.users.${config.local.user.name} = {
      home.packages = [cfg.package];

      systemd.user.services.neiro = {
        Unit = {
          Description = "Neiro speaker enhancement (PipeWire DSP)";
          After = ["pipewire.service" "wireplumber.service"];
          Requires = ["pipewire.service"];
          Wants = ["wireplumber.service"];
          PartOf = ["pipewire.service"];
        };
        Service = {
          ExecStartPre = "${python}/bin/python ${./merge_state.py} ${settingsFile}";
          ExecStart = "${lib.getExe cfg.package} daemon --tuning ${lib.escapeShellArg (toString cfg.tuningFile)}";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["pipewire.service"];
      };
    };
  };
}
