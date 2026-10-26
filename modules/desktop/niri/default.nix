{
  config,
  inputs,
  ...
}: let
  homeModule = config.flake.modules.homeManager.niri;
in {
  flake.modules.nixos.niri = {
    pkgs,
    lib,
    config,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    upstreamNiriPackage = inputs.niri-flake.packages.${system}.niri-unstable;
    # Keep upstream's login environment import, but pass variable names explicitly
    # for systemd 261+. Patch only the launcher to avoid rebuilding the compositor.
    niriPackage = pkgs.symlinkJoin {
      name = "${upstreamNiriPackage.name}-session-env";
      paths = [upstreamNiriPackage];
      inherit (upstreamNiriPackage) meta;
      passthru = upstreamNiriPackage.passthru;
      postBuild = ''
        rm "$out/bin/niri-session"
        cp ${upstreamNiriPackage}/bin/niri-session "$out/bin/niri-session"
        chmod u+w "$out/bin/niri-session"
        substituteInPlace "$out/bin/niri-session" \
          --replace-fail 'systemctl --user import-environment' \
          'systemctl --user import-environment $(${pkgs.bash}/bin/bash -c "compgen -e")'
      '';
    };
    xwaylandSatellitePackage = inputs.niri-flake.packages.${system}.xwayland-satellite-unstable;
  in {
    config = {
      home-manager.users.${config.local.user.name}.imports = [homeModule];

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
        xwaylandSatellitePackage
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
    };
  };

  flake.modules.homeManager.niri = {config, ...}: {
    xdg.configFile."niri/config.kdl".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Documents/nix-config/modules/desktop/niri/config.kdl";

    xdg.configFile."shikane/config.toml".source = ./shikane/config.toml;

    services.shikane.enable = true;
  };
}
