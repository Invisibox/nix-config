{
  lib,
  pkgs,
  config,
  steamGameWrapper ? pkgs.callPackage ./game-wrapper.nix {},
  steamRuntimeEnv ? {},
}: let
  steamConfigEnv =
    steamRuntimeEnv
    // {
      STEAM_GAMESCOPE = "1";
      WINEDLLOVERRIDES = "dinput8,dxgi,dsound,ddraw=n,b";
    };
  defaultOptions = {
    env = lib.mapAttrs (_: value: lib.mkDefault value) steamConfigEnv;
    wrappers = [
      (lib.getExe steamGameWrapper)
    ];
  };
in {
  enable = true;
  onSteamRunning = "close";
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
      "130" = {
        env = {
          MESA_LOADER_DRIVER_OVERRIDE = "zink";
        };
      };
    };
}
