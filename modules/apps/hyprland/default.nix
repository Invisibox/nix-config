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
    # programs.thunar = {
    #   enable = true;
    #   plugins = with pkgs.xfce; [
    #     thunar-volman
    #     thunar-archive-plugin
    #   ];
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

      programs.dankMaterialShell.enable = true;

      home.packages = with pkgs; [
        brightnessctl
        # qtmultimedia
        accountsservice
        cliphist
        matugen
        waybar
        rofi
        swaynotificationcenter
        wlogout
        swww
      ];

      # services.kanshi.enable = true;

      services.swaync.enable = true;
    };
  };
}
