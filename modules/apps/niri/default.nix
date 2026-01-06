{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Enable Niri
  programs.niri = {
    enable = true;
    package = inputs.niri-blurry.packages.${pkgs.stdenv.hostPlatform.system}.niri;
  };

  # 图形界面权限管理
  security.polkit.enable = true;

  # XDG Portals (屏幕共享、文件选择)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gnome
    ];
    config.niri.default = ["gnome" "gtk"]; # 强制 Niri 使用 gnome/gtk portal
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    # material-symbols
    # inter
    # fira-code
  ];

  # 禁用 Niri Flake 可能自带的 Polkit 服务，以使用下方自定义的
  systemd.user.services.niri-flake-polkit.enable = false;

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
