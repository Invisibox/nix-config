{
  imports = [
    ./features/packages.nix
    ./features/mime.nix
    ./features/git.nix
    ./features/theme.nix
    ./features/cli.nix

    ./niri
    ./noctalia
    ./nautilus
    # ./spotify
    ./zed
    ./zen-browser.nix
    ./mpv.nix
    ./rime.nix
    ./fcitx5
    ./kitty.nix
    ./starship.nix
    ./zsh/zsh.nix
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };

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

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
