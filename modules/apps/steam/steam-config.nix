{
  lib,
  pkgs,
  config,
  steamGameWrapper ? pkgs.callPackage ./game-wrapper.nix {},
}: let
  steamRuntimeEnv = {
    PIPEWIRE_NODE = "Game";
    PULSE_SINK = "Game";
    PROTON_ENABLE_HDR = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_FSR4_RDNA3_UPGRADE = "1";
    PROTON_USE_NTSYNC = "1";
    PROTON_USE_WOW64 = "1";
    STEAM_GAMESCOPE = "1";
    WINEDLLOVERRIDES = "dinput8,dxgi,dsound,ddraw=n,b";
  };
  defaultOptions = {
    launchOptions = {
      env = lib.mapAttrs (_: value: lib.mkDefault value) steamRuntimeEnv;
      wrappers = [
        (lib.getExe steamGameWrapper)
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
