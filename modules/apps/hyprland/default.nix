{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.hyprland;
in {
  options.hyprland = {
    enable = lib.mkEnableOption "Enable Hyprland window manager";
  };
  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    environment.systemPackages = with pkgs; [
      xdg-utils
    ];

    # home-manager.users.${username} = {
    #   pkgs,
    #   config,
    #   inputs,
    #   ...
    # }: {
    #   imports = [
    #     inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    #   ];

    #   programs.dankMaterialShell = {
    #     enable = true;
    #     enableSystemMonitoring = true; # System monitoring widgets (dgop)
    #     enableClipboard = true; # Clipboard history manager
    #     enableVPN = true; # VPN management widget
    #     enableBrightnessControl = true; # Backlight/brightness controls
    #     enableColorPicker = true; # Color picker tool
    #     enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    #     enableAudioWavelength = true; # Audio visualizer (cava)
    #     enableCalendarEvents = true; # Calendar integration (khal)
    #     enableSystemSound = true; # System sound effects
    #     plugins = {
    #       calculator.src = "${inputs.dankMaterialShell}/PLUGINS/calculator";
    #     };
    #   };

    #   home.packages = with pkgs; [
    #     brightnessctl
    #     ddcutil
    #     libnotify
    #     mate.mate-polkit
    #     kdePackages.qtmultimedia
    #     accountsservice
    #     cliphist
    #     matugen
    #     cava
    #     wlogout
    #     swww
    #   ];

    #   services.shikane.enable = true;
    # };
  };
}
