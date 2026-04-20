{
  lib,
  pkgs,
  config,
}: let
  defaultOptions = {
    launchOptions = {
      env = {
        PIPEWIRE_NODE = "Game";
        PULSE_SINK = "Game";
        PROTON_ENABLE_HDR = true;
        PROTON_ENABLE_WAYLAND = true;
        PROTON_FSR4_RDNA3_UPGRADE = true;
        PROTON_USE_NTSYNC = true;
        PROTON_USE_WOW64 = true;
        WINEDLLOVERRIDES = "dinput8,dxgi,dsound,ddraw=n,b";
      };
      wrappers = [
        (lib.getExe pkgs.gamemode)
        (lib.getExe' pkgs.obs-studio-plugins.obs-vkcapture "obs-gamecapture")
        (lib.getExe pkgs.mangohud)
      ];
    };
  };
in {
  enable = true;
  closeSteam = true;
  defaultCompatTool = "Proton GE";
  apps =
    lib.mapAttrs
    (
      _: options:
        lib.mkMerge [
          options
          defaultOptions
        ]
    )
    {
      hlbs = {
        id = 130;
        launchOptions = {
          env = {
            MESA_LOADER_DRIVER_OVERRIDE = "zink";
          };
        };
      };
    };
}
