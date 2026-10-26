{
  flake.modules.nixos.obs = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.apps.obs;
    localUserName = config.local.user.name;
  in {
    options = {
      local.apps.obs = {
        silenceOutput = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
    config = {
      home-manager.users.${localUserName} = {
        home = {
          packages = [pkgs.obs-cmd];
          sessionVariables = lib.optionalAttrs cfg.silenceOutput {
            OBS_VKCAPTURE_QUIET = "1";
          };
        };
        programs.obs-studio = {
          enable = true;
          plugins = with pkgs.obs-studio-plugins; [
            input-overlay
            obs-gstreamer
            obs-pipewire-audio-capture
            obs-vaapi
            obs-vkcapture
          ];
        };
        xdg = {
          desktopEntries = {
            "obs" = {
              name = "OBS Studio";
              comment = "Free and Open Source Streaming/Recording Software";
              exec = "env GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb obs --disable-shutdown-check";
              terminal = false;
              icon = "com.obsproject.Studio";
              type = "Application";
              startupNotify = true;
              categories = [
                "AudioVideo"
                "Recorder"
              ];
            };
          };
        };
      };
    };
  };
}
