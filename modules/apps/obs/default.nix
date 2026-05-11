{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.obs;
in {
  options = {
    obs = {
      enable = lib.mkEnableOption "Enable obs in home-manager";
      enableNative = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      silenceOutput = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home = {
        packages = with pkgs;
          lib.mkIf cfg.enableNative [
            obs-cmd
          ];
        sessionVariables = lib.optionalAttrs cfg.silenceOutput {
          OBS_VKCAPTURE_QUIET = "1";
        };
      };
      programs.obs-studio = {
        enable = cfg.enableNative;
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
          "obs" = lib.mkIf cfg.enableNative {
            name = "OBS Studio";
            comment = "Free and Open Source Streaming/Recording Software";
            exec = "GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb obs --disable-shutdown-check";
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
}
