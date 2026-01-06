{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.dms.homeModules.dankMaterialShell.default
    inputs.dms.homeModules.dankMaterialShell.niri
  ];

  programs.dankMaterialShell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
    };

    niri = {
      # enableKeybinds = true; # Automatic keybinding configuration
      # enableSpawn = true; # Auto-start DMS with niri
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableClipboard = true; # Clipboard history manager
    enableVPN = true; # VPN management widget
    enableBrightnessControl = true; # Backlight/brightness controls
    enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects
  };

  # systemd.user.services.niri-flake-polkit.enable = false;

  home.packages = with pkgs; [
    brightnessctl
    ddcutil
    libnotify
    mate.mate-polkit
    kdePackages.qtmultimedia
    accountsservice
    cliphist
    matugen
    cava
    wlogout
    swww
  ];

  services.shikane.enable = true;
}
