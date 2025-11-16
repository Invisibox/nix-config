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

    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs.xfce; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
      # enable preference changes saving for xfce/thunar
      xfconf.enable = true;
      # test for archive plugin and neovim wrapper
      file-roller.enable = true;
      # add this after environment.systemPackages, otherwise it won't be found
      dconf.enable = true;
    };
    services = {
      gvfs.enable = true;
      tumbler.enable = true;
    };

    environment.systemPackages = with pkgs; [
      xdg-utils
    ];

    # stylix = {
    #   base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    #   enable = true;
    #   targets.gtk.enable = true;
    #   # targets.gtk.flatpakSupport.enable = true;
    #   cursor = {
    #     package = pkgs.bibata-cursors;
    #     name = "Bibata-Modern-Ice";
    #     size = 20;
    #   };
    #   # fonts = {
    #   #   monospace.name = "Maple Mono";
    #   #   monospace.package = pkgs.maple-mono-variable;
    #   #   sansSerif.name = "LXGW WenKai";
    #   #   sansSerif.package = pkgs.lxgw-wenkai;
    #   #   serif.name = "LXGW WenKai";
    #   #   serif.package = pkgs.lxgw-wenkai;
    #   #   emoji.name = "Noto Color Emoji";
    #   #   emoji.package = pkgs.noto-fonts-color-emoji;
    #   # };
    #   iconTheme = {
    #     enable = true;
    #     package = pkgs.papirus-icon-theme;
    #     dark = "Papirus-Dark";
    #     light = "Papirus-Light";
    #   };
    # };

    home-manager.users.${username} = {
      pkgs,
      config,
      inputs,
      ...
    }: {
      imports = [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
      ];

      programs.dankMaterialShell = {
        enable = true;
        enableSystemMonitoring = true; # System monitoring widgets (dgop)
        enableClipboard = true; # Clipboard history manager
        enableVPN = true; # VPN management widget
        enableBrightnessControl = true; # Backlight/brightness controls
        enableColorPicker = true; # Color picker tool
        enableDynamicTheming = true; # Wallpaper-based theming (matugen)
        enableAudioWavelength = true; # Audio visualizer (cava)
        enableCalendarEvents = true; # Calendar integration (khal)
        enableSystemSound = true; # System sound effects
        plugins = {
          calculator.src = "${inputs.dankMaterialShell}/PLUGINS/calculator";
        };
      };

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

      # services.kanshi = {
      #   enable = true;
      #   systemdTarget = "";
      # };
      # services.swaync.enable = true;
    };
  };
}
