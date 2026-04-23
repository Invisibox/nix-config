{
  pkgs,
  lib,
  inputs,
  ...
}: let
  niriPackage = inputs.niri-unstable.packages.${pkgs.stdenv.hostPlatform.system}.niri;
in {
  # Enable Niri
  programs.niri = {
    enable = true;
    package = niriPackage;
  };

  # 图形界面权限管理
  security.polkit.enable = true;

  # XDG Portals (屏幕共享、文件选择)
  xdg.portal = {
    enable = true;
    # 切回 gnome portal 后端，避免 wlr backend 的兼容性问题
    wlr.enable = lib.mkForce false;
    config = {
      common = {
        default = ["gnome" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
      niri = {
        default = ["gnome" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  # Ensure xdg-desktop-portal sees Niri session env on D-Bus activation.
  systemd.user.services.niri-portal-env = {
    description = "Import Niri env for XDG portal activation";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session-pre.target"];
    after = ["graphical-session-pre.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri";
    };
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    slurp
    grim
    satty
  ];

  # 认证代理自动启动
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # 设置默认会话
  # 确保你在其他地方配置了 services.xserver.displayManager.gdm.enable = true;
  # 或者 services.greetd...
  services.displayManager.defaultSession = lib.mkForce "niri";
}
