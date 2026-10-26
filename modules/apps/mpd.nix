{
  flake.modules.homeManager.apps = {
    services.mpd = {
      enable = true;
      extraConfig = ''
        auto_update "yes"
        audio_output {
          type "pipewire"
          name "PipeWire"
        }
      '';
    };

    dconf.settings = {
      "io/github/htkhiem/Euphonica/client".mpd-host = "127.0.0.1";
      # Home Manager provides MPD, so skip Euphonica's server setup.
      "io/github/htkhiem/Euphonica/state".onboarded = true;
    };
  };
}
