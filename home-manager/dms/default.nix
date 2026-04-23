{
  pkgs,
  inputs,
  config,
  ...
}: let
  avatarPath = "${config.home.homeDirectory}/.config/DankMaterialShell/avatar.avif";
  dmsCli = "${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell}/bin/dms";
  setAvatarScript = pkgs.writeShellScript "dms-set-avatar" ''
    set -euo pipefail

    for _ in $(seq 1 30); do
      if ${dmsCli} ipc call profile setImage "${avatarPath}" >/dev/null 2>&1; then
        exit 0
      fi
      sleep 1
    done

    exit 1
  '';
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
    };

    # niri = {
    # enableKeybinds = true; # Automatic keybinding configuration
    # enableSpawn = true; # Auto-start DMS with niri
    # };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    # enableClipboard = true; # Clipboard history manager
    enableVPN = true; # VPN management widget
    # enableBrightnessControl = true; # Backlight/brightness controls
    # enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    # enableSystemSound = true; # System sound effects
  };

  # systemd.user.services.niri-flake-polkit.enable = false;

  home.file.".config/DankMaterialShell/avatar.avif".source = ./avatar.avif;

  home.packages = with pkgs; [
    brightnessctl
    ddcutil
    libnotify
    mate-polkit
    kdePackages.qtmultimedia
    accountsservice
    cliphist
    matugen
    cava
    wlogout
    awww
    dsearch
  ];

  systemd.user.services.dsearch = {
    Unit = {
      Description = "dsearch - fast filesystem search service";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.dsearch}/bin/dsearch serve";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.dms-set-avatar = {
    Unit = {
      Description = "Set DMS profile avatar";
      After = ["dms.service"];
      Wants = ["dms.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${setAvatarScript}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  services.shikane.enable = true;
}
