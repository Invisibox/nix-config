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
    ./kitty.nix
    ./starship.nix
    ./zsh/zsh.nix
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
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
