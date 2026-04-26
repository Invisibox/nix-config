{
  lib,
  config,
  username,
  pkgs,
  ...
}:
let
  cfg = config.obs;
in
{
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
        packages =
          with pkgs;
          lib.mkIf cfg.enableNative [
            obs-cmd
          ];
        sessionVariables = {
          # https://github.com/nowrep/obs-vkcapture/issues/14#issuecomment-322237961
          VK_INSTANCE_LAYERS = "VK_LAYER_MANGOHUD_overlay_x86:VK_LAYER_MANGOHUD_overlay_x86_64:VK_LAYER_OBS_vkcapture_32:VK_LAYER_OBS_vkcapture_64";
        }
        // lib.optionalAttrs cfg.silenceOutput {
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
