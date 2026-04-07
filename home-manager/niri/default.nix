{
  pkgs,
  config,
  lib,
  inputs,
  ...
} @ args: let
  cfg = config.modules.desktop.niri;
  confPath = "${config.home.homeDirectory}/Documents/nix-config/home-manager/niri";
in {
  imports = [
    # 保持这两个，DMS 需要它们
    inputs.dms.homeModules.niri
    inputs.dms.homeModules.dank-material-shell
  ];

  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.niri = {
          enable = true;
          package = inputs.niri-blurry.packages.${pkgs.stdenv.hostPlatform.system}.niri;
          
          # 🟢 修正：不要设置 config = {}，DMS 的模块可能改变了 config 的类型定义
          # 直接留空，让 DMS 模块去生成它所需的默认值，或者依靠下面的配置文件覆盖
        };

        # 这一段保持不变
        home.packages = with pkgs; [
          xwayland-satellite
          brightnessctl
          ddcutil
          libnotify
          mate.mate-polkit
          kdePackages.qtmultimedia
          accountsservice
          cliphist
          wl-clipboard
          matugen
          cava
          wlogout
          awww
        ];

        services.shikane.enable = true;

        # DMS 配置
        programs.dank-material-shell = {
          enable = true;
          systemd = {
            enable = true;
            restartIfChanged = true;
          };
          niri = {
            includes = {
              enable = true;
              override = true;
              originalFileName = "hm"; 
              filesToInclude = ["alttab" "binds" "colors" "layout" "outputs" "wpblur"];
            };
            enableSpawn = false;
          };
          enableSystemMonitoring = true;
          enableVPN = true;
          enableDynamicTheming = true;
          enableAudioWavelength = true;
          enableCalendarEvents = true;
        };

        # 配置文件链接
        xdg.configFile."niri/hm.kdl".source = config.lib.file.mkOutOfStoreSymlink "${confPath}/config.kdl";

        # Polkit 服务
        systemd.user.services.niri-flake-polkit = {
          Unit = {
            Description = "PolicyKit Authentication Agent provided by niri-flake";
            After = ["graphical-session.target"];
            Wants = ["graphical-session-pre.target"];
          };
          Install.WantedBy = ["niri.service"];
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      }
    ]
  );
}
