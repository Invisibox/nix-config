{
  writeShellApplication,
  gamemode,
  mangohud,
  obs-studio-plugins,
}:
writeShellApplication {
  name = "steam-game-wrapper";
  runtimeEnv = {
    OBS_VKCAPTURE = "1";
    PIPEWIRE_NODE = "Game";
    PULSE_SINK = "Game";
  };
  runtimeInputs = [
    gamemode
    mangohud
    obs-studio-plugins.obs-vkcapture
  ];
  text = ''
    if [[ -n "''${MESA_LOADER_DRIVER_OVERRIDE+x}" && -z "$MESA_LOADER_DRIVER_OVERRIDE" ]]; then
      unset MESA_LOADER_DRIVER_OVERRIDE
    fi

    if [[ "''${STEAM_OBS_CAPTURE:-1}" == "0" ]]; then
      exec env gamemoderun mangohud "$@"
    fi

    exec env gamemoderun obs-gamecapture mangohud "$@"
  '';
}
