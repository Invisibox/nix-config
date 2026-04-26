{
  lib,
  writeShellApplication,
  gamemode,
  gamescope,
  mangohud,
  obs-studio-plugins,
}: let
  gamescopeArgs = [
    "--backend"
    "sdl"
    "--fullscreen"
    "--force-grab-cursor"
    "--expose-wayland"
    "--mangoapp"
  ];
in
  writeShellApplication {
    name = "steam-game-wrapper";
    runtimeEnv = {
      OBS_VKCAPTURE = "1";
      PIPEWIRE_NODE = "Game";
      PULSE_SINK = "Game";
    };
    runtimeInputs = [
      gamemode
      gamescope
      mangohud
      obs-studio-plugins.obs-vkcapture
    ];
    text = ''
      if [[ -n "''${MESA_LOADER_DRIVER_OVERRIDE+x}" && -z "$MESA_LOADER_DRIVER_OVERRIDE" ]]; then
        unset MESA_LOADER_DRIVER_OVERRIDE
      fi

      declare -a gamescope_args=(${lib.escapeShellArgs gamescopeArgs})

      if [[ "''${STEAM_GAMESCOPE_HDR:-0}" == "1" ]]; then
        gamescope_args+=(--hdr-enabled)
      fi

      if [[ "''${STEAM_GAMESCOPE_VRR:-0}" == "1" ]]; then
        gamescope_args+=(--adaptive-sync)
      fi

      if [[ "''${STEAM_GAMESCOPE:-1}" == "0" ]]; then
        exec env gamemoderun obs-gamecapture mangohud "$@"
      fi

      if [[ "''${STEAM_GAMESCOPE_OBS:-1}" == "0" ]]; then
        exec env gamemoderun gamescope "''${gamescope_args[@]}" -- "$@"
      fi

      exec env gamemoderun gamescope "''${gamescope_args[@]}" -- obs-gamecapture "$@"
    '';
  }
